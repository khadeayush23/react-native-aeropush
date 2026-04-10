package com.aeropush

import com.aeropush.events.AeropushEventManager
import com.aeropush.networkmanager.AeropushStageManager
import com.aeropush.networkmanager.AeropushSyncHandler
import com.aeropush.storage.AeropushStateManager
import com.aeropush.storage.SwitchState
import com.aeropush.utils.AeropushExceptionHandler
import com.aeropush.utils.ProcessPhoenix
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod

class AeropushModule(reactContext: ReactApplicationContext) :
    NativeAeropushSpec(reactContext) {

    companion object {
        const val NAME = NativeAeropushSpec.NAME
    }

    init {
        // Initialize state manager with application context
        if (!AeropushStateManager.isInitialized()) {
            AeropushStateManager.initialize(reactContext.applicationContext)
        }
        // Initialize event manager with react context
        AeropushEventManager.initialize(reactContext)
    }

    override fun getName(): String = NAME

    /**
     * Called from JS when the Aeropush provider mounts.
     * Initializes the module, sets up event emission, checks for pending downloads,
     * and marks the launch for stabilization tracking.
     */
    @ReactMethod
    override fun onLaunch(initParamsString: String) {
        try {
            AeropushStateManager.setMounted(true)

            // Ensure directories exist
            Aeropush.ensureDirectories()

            // Install exception handler
            AeropushExceptionHandler.install(reactApplicationContext.applicationContext)

            // Check for crash markers from previous session
            AeropushExceptionHandler.checkAndHandleCrashMarker(reactApplicationContext.applicationContext)

            // Clean up any interrupted downloads
            AeropushSyncHandler.checkPendingDownloads()

            // Mark this launch for stabilization tracking
            AeropushSyncHandler.markLaunch()
        } catch (e: Exception) {
            // Best effort initialization - don't crash the app
        }
    }

    /**
     * Returns the current Aeropush config as a JSON string via Promise.
     */
    @ReactMethod
    override fun getAeropushConfig(promise: Promise) {
        try {
            val config = AeropushStateManager.getConfig()
            promise.resolve(config.toJson().toString())
        } catch (e: Exception) {
            promise.reject("AEROPUSH_CONFIG_ERROR", "Failed to get config: ${e.message}", e)
        }
    }

    /**
     * Returns the current Aeropush meta state as a JSON string via Promise.
     */
    @ReactMethod
    override fun getAeropushMeta(promise: Promise) {
        try {
            val meta = AeropushStateManager.getMeta()
            promise.resolve(meta.toJson().toString())
        } catch (e: Exception) {
            promise.reject("AEROPUSH_META_ERROR", "Failed to get meta: ${e.message}", e)
        }
    }

    /**
     * Triggers a background sync with the Aeropush API.
     */
    @ReactMethod
    override fun sync() {
        AeropushSyncHandler.sync()
    }

    /**
     * Downloads a staging bundle from the given URL.
     */
    @ReactMethod
    override fun downloadStageBundle(url: String, hash: String, promise: Promise) {
        AeropushStageManager.downloadStageBundle(
            url = url,
            hash = hash,
            onSuccess = { resultHash ->
                promise.resolve(resultHash)
            },
            onError = { error ->
                promise.reject("AEROPUSH_DOWNLOAD_ERROR", error)
            }
        )
    }

    /**
     * Returns a batch of queued native events as a JSON array string.
     */
    @ReactMethod
    override fun popEvents(promise: Promise) {
        try {
            val events = AeropushEventManager.popEvents()
            promise.resolve(events)
        } catch (e: Exception) {
            promise.reject("AEROPUSH_EVENTS_ERROR", "Failed to pop events: ${e.message}", e)
        }
    }

    /**
     * Acknowledges that the given event IDs have been processed.
     * Removes them from the event cache.
     */
    @ReactMethod
    override fun acknowledgeEvents(eventIds: String) {
        AeropushEventManager.acknowledgeEvents(eventIds)
    }

    /**
     * Toggles between PROD and STAGE switch states.
     */
    @ReactMethod
    override fun toggleAeropushSwitch(switchState: String, promise: Promise) {
        try {
            val newState = SwitchState.fromValue(switchState)
            val meta = AeropushStateManager.getMeta()
            meta.setSwitchState(newState)
            promise.resolve(meta.toJson().toString())
        } catch (e: Exception) {
            promise.reject("AEROPUSH_SWITCH_ERROR", "Failed to toggle switch: ${e.message}", e)
        }
    }

    /**
     * Updates the SDK token used for API authentication.
     */
    @ReactMethod
    override fun updateSdkToken(sdkToken: String, promise: Promise) {
        try {
            val config = AeropushStateManager.getConfig()
            config.updateSdkToken(sdkToken)
            promise.resolve(config.toJson().toString())
        } catch (e: Exception) {
            promise.reject("AEROPUSH_TOKEN_ERROR", "Failed to update SDK token: ${e.message}", e)
        }
    }

    /**
     * Restarts the application using ProcessPhoenix.
     */
    @ReactMethod
    override fun restart() {
        val activity = currentActivity
        if (activity != null) {
            ProcessPhoenix.triggerRebirth(activity)
        } else {
            ProcessPhoenix.triggerRebirth(reactApplicationContext)
        }
    }

}
