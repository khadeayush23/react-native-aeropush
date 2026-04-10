package com.aeropush.utils

import com.aeropush.events.AeropushEventManager
import com.aeropush.events.NativeProdEventType
import com.aeropush.storage.AeropushMeta
import com.aeropush.storage.AeropushStateManager
import com.aeropush.storage.SlotState
import java.io.File

object AeropushSlotManager {

    /**
     * Installs a downloaded bundle into the NEW slot for production.
     * Moves the bundle from the temp directory to the NEW slot directory.
     * Updates the meta to point to the NEW slot.
     */
    fun installProdBundle(hash: String): Boolean {
        val meta = AeropushStateManager.getMeta()
        val tempDir = AeropushStateManager.getTempDir(true)
        val newSlotDir = AeropushStateManager.getSlotDir(true, SlotState.NEW)

        val tempBundleDir = File(tempDir)
        val newSlotFile = File(newSlotDir)

        if (!tempBundleDir.exists()) {
            return false
        }

        // Clear existing NEW slot
        if (newSlotFile.exists()) {
            AeropushFileManager.deleteDirectory(newSlotFile)
        }
        newSlotFile.mkdirs()

        // Move temp to NEW slot
        val success = AeropushFileManager.moveFile(tempBundleDir, newSlotFile)
        if (!success) {
            // Fallback: copy then delete
            tempBundleDir.listFiles()?.forEach { file ->
                AeropushFileManager.copyFile(file, File(newSlotFile, file.name))
            }
            AeropushFileManager.deleteDirectory(tempBundleDir)
        }

        // Update meta
        meta.setProdNewHash(hash)
        meta.setProdCurrentSlot(SlotState.NEW)
        meta.resetLaunchCount()
        meta.setProdTempHash("")

        AeropushEventManager.emitProdEvent(NativeProdEventType.INSTALLED_PROD, releaseHash = hash)

        return true
    }

    /**
     * Installs a downloaded bundle into the stage slot.
     */
    fun installStageBundle(hash: String): Boolean {
        val meta = AeropushStateManager.getMeta()
        val tempDir = AeropushStateManager.getTempDir(false)
        val stableSlotDir = AeropushStateManager.getSlotDir(false, SlotState.STABLE)

        val tempBundleDir = File(tempDir)
        val stableSlotFile = File(stableSlotDir)

        if (!tempBundleDir.exists()) {
            return false
        }

        // Clear existing slot
        if (stableSlotFile.exists()) {
            AeropushFileManager.deleteDirectory(stableSlotFile)
        }
        stableSlotFile.mkdirs()

        // Move temp to stable slot
        tempBundleDir.listFiles()?.forEach { file ->
            AeropushFileManager.copyFile(file, File(stableSlotFile, file.name))
        }
        AeropushFileManager.deleteDirectory(tempBundleDir)

        meta.setStageStableHash(hash)
        meta.setStageCurrentSlot(SlotState.STABLE)
        meta.setStageTempHash("")

        return true
    }

    /**
     * Promotes the NEW slot to STABLE for production after stabilization threshold is met.
     */
    fun stabilize(): Boolean {
        val meta = AeropushStateManager.getMeta()
        if (meta.prodCurrentSlot != SlotState.NEW) return false

        val newSlotDir = AeropushStateManager.getSlotDir(true, SlotState.NEW)
        val stableSlotDir = AeropushStateManager.getSlotDir(true, SlotState.STABLE)

        val newSlotFile = File(newSlotDir)
        val stableSlotFile = File(stableSlotDir)

        if (!newSlotFile.exists()) return false

        // Clear old stable
        if (stableSlotFile.exists()) {
            AeropushFileManager.deleteDirectory(stableSlotFile)
        }
        stableSlotFile.mkdirs()

        // Copy NEW to STABLE
        newSlotFile.listFiles()?.forEach { file ->
            AeropushFileManager.copyFile(file, File(stableSlotFile, file.name))
        }

        // Update meta
        meta.setProdStableHash(meta.prodNewHash)
        meta.setProdCurrentSlot(SlotState.STABLE)
        meta.resetLaunchCount()

        AeropushEventManager.emitProdEvent(NativeProdEventType.STABILIZED_PROD, releaseHash = meta.prodStableHash)

        return true
    }

    /**
     * Rolls back from NEW slot to STABLE slot for production.
     */
    fun rollback(): Boolean {
        val meta = AeropushStateManager.getMeta()

        if (meta.prodStableHash.isEmpty()) {
            // No stable version to roll back to, go to DEFAULT
            meta.setProdCurrentSlot(SlotState.DEFAULT)
            meta.setProdNewHash("")
            meta.resetLaunchCount()

            AeropushEventManager.emitProdEvent(NativeProdEventType.ROLLED_BACK_PROD)
            return true
        }

        // Verify stable bundle still exists
        val stableBundlePath = AeropushStateManager.getBundlePath(true, SlotState.STABLE)
        if (!AeropushFileManager.bundleExists(stableBundlePath)) {
            // Stable bundle is missing, fall back to DEFAULT
            meta.setProdCurrentSlot(SlotState.DEFAULT)
            meta.setProdStableHash("")
            meta.setProdNewHash("")
            meta.resetLaunchCount()

            AeropushEventManager.emitProdEvent(NativeProdEventType.ROLLED_BACK_PROD)
            return true
        }

        // Roll back to STABLE
        meta.setProdCurrentSlot(SlotState.STABLE)
        meta.setProdNewHash("")
        meta.resetLaunchCount()
        meta.setLastRollbackTime(System.currentTimeMillis())

        AeropushEventManager.emitProdEvent(NativeProdEventType.ROLLED_BACK_PROD, releaseHash = meta.prodStableHash)

        return true
    }

    /**
     * Auto-rollback triggered by crash or exception handler.
     */
    fun autoRollback(): Boolean {
        val meta = AeropushStateManager.getMeta()
        val currentSlot = meta.prodCurrentSlot

        if (currentSlot == SlotState.DEFAULT) return false

        if (meta.prodStableHash.isNotEmpty() && currentSlot == SlotState.NEW) {
            // Roll back to STABLE
            val stableBundlePath = AeropushStateManager.getBundlePath(true, SlotState.STABLE)
            if (AeropushFileManager.bundleExists(stableBundlePath)) {
                meta.setProdCurrentSlot(SlotState.STABLE)
                meta.setProdNewHash("")
                meta.resetLaunchCount()
                meta.setLastRollbackTime(System.currentTimeMillis())

                AeropushEventManager.emitProdEvent(NativeProdEventType.AUTO_ROLLED_BACK_PROD, releaseHash = meta.prodStableHash)
                return true
            }
        }

        // Fall back to DEFAULT
        meta.setProdCurrentSlot(SlotState.DEFAULT)
        meta.setProdStableHash("")
        meta.setProdNewHash("")
        meta.resetLaunchCount()
        meta.setLastRollbackTime(System.currentTimeMillis())

        AeropushEventManager.emitProdEvent(NativeProdEventType.AUTO_ROLLED_BACK_PROD)
        return true
    }

    /**
     * Resolves the bundle path for the current production slot.
     * Includes auto-fallback if the current slot's bundle is missing.
     */
    fun resolveProdBundlePath(): String? {
        val meta = AeropushStateManager.getMeta()
        val currentSlot = meta.prodCurrentSlot

        if (currentSlot == SlotState.DEFAULT) return null

        val bundlePath = AeropushStateManager.getBundlePath(true, currentSlot)
        if (AeropushFileManager.bundleExists(bundlePath)) {
            return bundlePath
        }

        // Auto-fallback: current slot is missing, try the other
        if (currentSlot == SlotState.NEW && meta.prodStableHash.isNotEmpty()) {
            val stablePath = AeropushStateManager.getBundlePath(true, SlotState.STABLE)
            if (AeropushFileManager.bundleExists(stablePath)) {
                meta.setProdCurrentSlot(SlotState.STABLE)
                meta.setProdNewHash("")
                return stablePath
            }
        }

        // Nothing available, fall back to DEFAULT
        meta.setProdCurrentSlot(SlotState.DEFAULT)
        return null
    }

    /**
     * Resolves the bundle path for the current stage slot.
     */
    fun resolveStageBundlePath(): String? {
        val meta = AeropushStateManager.getMeta()
        val currentSlot = meta.stageCurrentSlot

        if (currentSlot == SlotState.DEFAULT) return null

        val bundlePath = AeropushStateManager.getBundlePath(false, currentSlot)
        if (AeropushFileManager.bundleExists(bundlePath)) {
            return bundlePath
        }

        // Fall back to DEFAULT
        meta.setStageCurrentSlot(SlotState.DEFAULT)
        return null
    }
}
