package com.aeropush.networkmanager

import com.aeropush.events.AeropushEventManager
import com.aeropush.events.NativeStageEventType
import com.aeropush.utils.AeropushSlotManager

/**
 * Manages stage bundle downloads from the dev/testing UI.
 */
object AeropushStageManager {

    /**
     * Downloads a staging bundle and installs it.
     *
     * @param url The download URL
     * @param hash The bundle hash
     * @param onSuccess Called with the hash on success
     * @param onError Called with error message on failure
     */
    fun downloadStageBundle(
        url: String,
        hash: String,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        AeropushFileDownloader.downloadBundle(
            downloadUrl = url,
            hash = hash,
            isProduction = false,
            callback = object : AeropushDownloadCallback {
                override fun onSuccess(hash: String) {
                    val installed = AeropushSlotManager.installStageBundle(hash)
                    if (installed) {
                        AeropushEventManager.emitStageEvent(
                            NativeStageEventType.DOWNLOAD_COMPLETE_STAGE,
                            releaseHash = hash
                        )
                        AeropushEventManager.emitStageEvent(
                            NativeStageEventType.INSTALLED_STAGE,
                            releaseHash = hash
                        )
                        onSuccess(hash)
                    } else {
                        AeropushEventManager.emitStageEvent(
                            NativeStageEventType.DOWNLOAD_ERROR_STAGE,
                            error = "Failed to install stage bundle"
                        )
                        onError("Failed to install stage bundle")
                    }
                }

                override fun onReject(error: String) {
                    AeropushEventManager.emitStageEvent(
                        NativeStageEventType.DOWNLOAD_ERROR_STAGE,
                        error = error
                    )
                    onError(error)
                }

                override fun onProgress(progress: Int) {
                    AeropushEventManager.emitStageEvent(
                        NativeStageEventType.DOWNLOAD_PROGRESS_STAGE,
                        progress = progress.toString()
                    )
                }
            }
        )
    }
}
