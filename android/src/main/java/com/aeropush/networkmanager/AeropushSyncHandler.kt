package com.aeropush.networkmanager

import com.aeropush.events.AeropushEventManager
import com.aeropush.events.NativeProdEventType
import com.aeropush.storage.AeropushStateManager
import com.aeropush.storage.SlotState
import com.aeropush.storage.SwitchState
import com.aeropush.utils.AeropushDeviceInfo
import com.aeropush.utils.AeropushSlotManager
import org.json.JSONObject

/**
 * Handles background sync with the Aeropush API.
 * Checks for new production bundles, manages download, rollback, and stabilization.
 */
object AeropushSyncHandler {

    @Volatile
    private var isSyncing = false

    /**
     * Triggers a background sync. Safe to call multiple times; concurrent calls are ignored.
     */
    fun sync() {
        if (isSyncing) return
        isSyncing = true

        Thread {
            try {
                performSync()
            } catch (e: Exception) {
                AeropushEventManager.emitProdEvent(
                    NativeProdEventType.SYNC_ERROR_PROD,
                    error = e.message ?: "Sync failed"
                )
            } finally {
                isSyncing = false
            }
        }.start()
    }

    private fun performSync() {
        val config = AeropushStateManager.getConfig()
        val meta = AeropushStateManager.getMeta()

        if (config.appToken.isEmpty() || config.projectId.isEmpty()) {
            return
        }

        // Only sync for production
        if (meta.switchState != SwitchState.PROD) {
            return
        }

        val context = AeropushStateManager.getApplicationContext()
        val deviceInfo = AeropushDeviceInfo.collect(context)

        val body = JSONObject().apply {
            put("projectId", config.projectId)
            put("platform", "android")
            put("appVersion", config.appVersion)
            put("currentHash", meta.getActiveHash(true))
            put("currentSlot", meta.prodCurrentSlot.value)
            put("stableHash", meta.prodStableHash)
            put("newHash", meta.prodNewHash)
            put("launchCount", meta.launchCount)
            put("deviceInfo", deviceInfo)
            if (config.uid.isNotEmpty()) {
                put("uid", config.uid)
            }
        }

        val response = AeropushApiManager.post(AeropushApiConstants.PATH_SYNC, body) ?: return

        val success = response.optBoolean("success", false)
        if (!success) {
            val errorMessage = response.optString("message", "Sync response unsuccessful")
            AeropushEventManager.emitProdEvent(
                NativeProdEventType.SYNC_ERROR_PROD,
                error = errorMessage
            )
            return
        }

        val data = response.optJSONObject("data") ?: return

        // Handle commands from server
        val action = data.optString("action", "")
        when (action) {
            "download" -> handleDownloadAction(data)
            "rollback" -> handleRollbackAction()
            "stabilize" -> handleStabilizeAction()
            "noop" -> { /* Nothing to do */ }
        }
    }

    private fun handleDownloadAction(data: JSONObject) {
        val downloadUrl = data.optString("downloadUrl", "")
        val hash = data.optString("hash", "")

        if (downloadUrl.isEmpty() || hash.isEmpty()) {
            AeropushEventManager.emitProdEvent(
                NativeProdEventType.SYNC_ERROR_PROD,
                error = "Invalid download data in sync response"
            )
            return
        }

        val meta = AeropushStateManager.getMeta()

        // Don't download if we already have this hash
        if (hash == meta.prodStableHash || hash == meta.prodNewHash) {
            return
        }

        // Don't download during rollback cooldown
        if (meta.isRollbackCooldownActive()) {
            return
        }

        AeropushEventManager.emitProdEvent(
            NativeProdEventType.DOWNLOAD_STARTED_PROD,
            releaseHash = hash
        )

        AeropushFileDownloader.downloadBundle(
            downloadUrl = downloadUrl,
            hash = hash,
            isProduction = true,
            callback = object : AeropushDownloadCallback {
                override fun onSuccess(hash: String) {
                    val installed = AeropushSlotManager.installProdBundle(hash)
                    if (installed) {
                        AeropushEventManager.emitProdEvent(
                            NativeProdEventType.DOWNLOAD_COMPLETE_PROD,
                            releaseHash = hash
                        )
                    } else {
                        AeropushEventManager.emitProdEvent(
                            NativeProdEventType.DOWNLOAD_ERROR_PROD,
                            releaseHash = hash,
                            error = "Failed to install bundle"
                        )
                    }
                }

                override fun onReject(error: String) {
                    AeropushEventManager.emitProdEvent(
                        NativeProdEventType.DOWNLOAD_ERROR_PROD,
                        error = error
                    )
                }

                override fun onProgress(progress: Int) {
                    AeropushEventManager.emitProdEvent(
                        NativeProdEventType.DOWNLOAD_PROGRESS_PROD,
                        progress = progress.toString()
                    )
                }
            }
        )
    }

    private fun handleRollbackAction() {
        AeropushSlotManager.rollback()
    }

    private fun handleStabilizeAction() {
        AeropushSlotManager.stabilize()
    }

    /**
     * Checks if there is a pending download in temp that was interrupted.
     * If so, cleans up the temp directory.
     */
    fun checkPendingDownloads() {
        val meta = AeropushStateManager.getMeta()

        // If there's a temp hash set but the current slot isn't pointing to it,
        // the download was interrupted - clean up
        if (meta.prodTempHash.isNotEmpty()) {
            val tempDir = AeropushStateManager.getTempDir(true)
            val tempFile = java.io.File(tempDir)
            if (tempFile.exists()) {
                com.aeropush.utils.AeropushFileManager.deleteDirectory(tempFile)
            }
            meta.setProdTempHash("")
        }

        if (meta.stageTempHash.isNotEmpty()) {
            val tempDir = AeropushStateManager.getTempDir(false)
            val tempFile = java.io.File(tempDir)
            if (tempFile.exists()) {
                com.aeropush.utils.AeropushFileManager.deleteDirectory(tempFile)
            }
            meta.setStageTempHash("")
        }
    }

    /**
     * Marks the current launch in meta.
     * Handles stabilization check for NEW slot.
     */
    fun markLaunch() {
        val meta = AeropushStateManager.getMeta()

        if (meta.prodCurrentSlot == SlotState.NEW) {
            meta.incrementLaunchCount()

            if (meta.hasReachedStabilizationThreshold()) {
                AeropushSlotManager.stabilize()
            }
        }
    }
}
