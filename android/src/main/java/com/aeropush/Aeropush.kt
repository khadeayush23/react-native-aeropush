package com.aeropush

import android.content.Context
import com.aeropush.storage.AeropushConfigConstants
import com.aeropush.storage.AeropushStateManager
import com.aeropush.storage.SlotState
import com.aeropush.storage.SwitchState
import com.aeropush.utils.AeropushExceptionHandler
import com.aeropush.utils.AeropushFileManager
import java.io.File

/**
 * Core entry point for Aeropush. Used by the host application to resolve
 * which JS bundle file to load at startup.
 *
 * Usage in MainApplication:
 * ```
 * override fun getJSBundleFile(): String {
 *     return Aeropush.getJSBundleFile(applicationContext)
 * }
 * ```
 */
object Aeropush {

    private const val DEFAULT_BUNDLE_ASSET = "assets://index.android.bundle"

    /**
     * Determines the JS bundle file to load.
     * Returns the path to a hot-updated bundle if available and valid,
     * otherwise returns the default asset bundle path.
     *
     * @param applicationContext The application context
     * @return The path to the JS bundle file
     */
    @JvmStatic
    fun getJSBundleFile(applicationContext: Context): String {
        return getJSBundleFile(applicationContext, null)
    }

    /**
     * Determines the JS bundle file to load with an optional default path override.
     *
     * @param applicationContext The application context
     * @param defaultBundlePath Optional custom default bundle path. If null, uses the asset bundle.
     * @return The path to the JS bundle file
     */
    @JvmStatic
    fun getJSBundleFile(applicationContext: Context, defaultBundlePath: String?): String {
        val fallbackPath = defaultBundlePath ?: DEFAULT_BUNDLE_ASSET

        try {
            // Initialize state manager if not already done
            if (!AeropushStateManager.isInitialized()) {
                AeropushStateManager.initialize(applicationContext)
            }

            // Install exception handler
            AeropushExceptionHandler.install(applicationContext)

            // Check for crash markers from previous session
            AeropushExceptionHandler.checkAndHandleCrashMarker(applicationContext)

            val meta = AeropushStateManager.getMeta()

            // Determine which bundle to use based on switch state
            val bundlePath = when (meta.switchState) {
                SwitchState.PROD -> resolveProdBundle(fallbackPath)
                SwitchState.STAGE -> resolveStageBundle(fallbackPath)
            }

            return bundlePath
        } catch (e: Exception) {
            return fallbackPath
        }
    }

    private fun resolveProdBundle(fallbackPath: String): String {
        val meta = AeropushStateManager.getMeta()
        val currentSlot = meta.prodCurrentSlot

        if (currentSlot == SlotState.DEFAULT) {
            return fallbackPath
        }

        val bundlePath = AeropushStateManager.getBundlePath(true, currentSlot)

        // Validate the bundle file exists
        if (AeropushFileManager.bundleExists(bundlePath)) {
            return bundlePath
        }

        // Auto-fallback: try the other slot
        if (currentSlot == SlotState.NEW && meta.prodStableHash.isNotEmpty()) {
            val stableBundlePath = AeropushStateManager.getBundlePath(true, SlotState.STABLE)
            if (AeropushFileManager.bundleExists(stableBundlePath)) {
                meta.setProdCurrentSlot(SlotState.STABLE)
                meta.setProdNewHash("")
                return stableBundlePath
            }
        }

        if (currentSlot == SlotState.STABLE && meta.prodNewHash.isNotEmpty()) {
            val newBundlePath = AeropushStateManager.getBundlePath(true, SlotState.NEW)
            if (AeropushFileManager.bundleExists(newBundlePath)) {
                meta.setProdCurrentSlot(SlotState.NEW)
                meta.setProdStableHash("")
                return newBundlePath
            }
        }

        // Both slots are empty/invalid, fall back to default
        meta.setProdCurrentSlot(SlotState.DEFAULT)
        meta.setProdStableHash("")
        meta.setProdNewHash("")

        return fallbackPath
    }

    private fun resolveStageBundle(fallbackPath: String): String {
        val meta = AeropushStateManager.getMeta()
        val currentSlot = meta.stageCurrentSlot

        if (currentSlot == SlotState.DEFAULT) {
            return fallbackPath
        }

        val bundlePath = AeropushStateManager.getBundlePath(false, currentSlot)

        if (AeropushFileManager.bundleExists(bundlePath)) {
            return bundlePath
        }

        // Stage bundle is missing, fall back to default
        meta.setStageCurrentSlot(SlotState.DEFAULT)
        meta.setStageStableHash("")
        meta.setStageNewHash("")

        return fallbackPath
    }

    /**
     * Ensures required directories exist on disk.
     */
    @JvmStatic
    fun ensureDirectories() {
        try {
            AeropushFileManager.ensureDirectory(AeropushStateManager.getProdDir())
            AeropushFileManager.ensureDirectory(AeropushStateManager.getStageDir())
            AeropushFileManager.ensureDirectory(AeropushStateManager.getSlotDir(true, SlotState.STABLE))
            AeropushFileManager.ensureDirectory(AeropushStateManager.getSlotDir(true, SlotState.NEW))
            AeropushFileManager.ensureDirectory(AeropushStateManager.getSlotDir(false, SlotState.STABLE))
        } catch (e: Exception) {
            // Best effort directory creation
        }
    }
}
