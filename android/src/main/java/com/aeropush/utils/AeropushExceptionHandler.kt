package com.aeropush.utils

import android.content.Context
import android.content.SharedPreferences
import com.aeropush.events.AeropushEventManager
import com.aeropush.events.NativeProdEventType
import com.aeropush.storage.AeropushConfigConstants
import com.aeropush.storage.AeropushStateManager
import com.aeropush.storage.SlotState
import org.json.JSONObject
import java.io.File

class AeropushExceptionHandler(private val context: Context) : Thread.UncaughtExceptionHandler {

    private val defaultHandler: Thread.UncaughtExceptionHandler? =
        Thread.getDefaultUncaughtExceptionHandler()

    companion object {
        private const val CRASH_MARKER_FILE = "aeropush_crash_marker.json"
        private var isInstalled = false

        /**
         * Installs the global exception handler.
         */
        @Synchronized
        fun install(context: Context) {
            if (isInstalled) return
            val handler = AeropushExceptionHandler(context.applicationContext)
            Thread.setDefaultUncaughtExceptionHandler(handler)
            isInstalled = true

            // Initialize native signal handler
            try {
                System.loadLibrary("aeropush-crash")
                val markerPath = File(context.filesDir, CRASH_MARKER_FILE).absolutePath
                initNativeSignalHandler(markerPath)
            } catch (e: UnsatisfiedLinkError) {
                // Native library not available, Java-only crash handling
            }
        }

        /**
         * Checks if a crash marker exists from a previous session.
         * If so, performs auto-rollback.
         */
        fun checkAndHandleCrashMarker(context: Context) {
            val markerFile = File(context.filesDir, CRASH_MARKER_FILE)

            // Check native crash marker
            if (markerFile.exists()) {
                try {
                    val markerContent = markerFile.readText()
                    val markerJson = JSONObject(markerContent)
                    val crashType = markerJson.optString("type", "unknown")

                    performAutoRollback(context, "native_crash:$crashType")
                    markerFile.delete()
                } catch (e: Exception) {
                    markerFile.delete()
                }
            }

            // Check Java crash marker from SharedPreferences
            val prefs = context.getSharedPreferences(
                AeropushConfigConstants.SHARED_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            if (prefs.getBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, false)) {
                performAutoRollback(context, "java_crash")
                prefs.edit().putBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, false).apply()
            }
        }

        private fun performAutoRollback(context: Context, crashType: String) {
            if (!AeropushStateManager.isInitialized()) {
                AeropushStateManager.initialize(context)
            }

            val meta = AeropushStateManager.getMeta()
            if (meta.prodCurrentSlot != SlotState.DEFAULT) {
                AeropushSlotManager.autoRollback()
                try {
                    AeropushEventManager.emitProdEvent(
                        NativeProdEventType.EXCEPTION_PROD,
                        error = crashType
                    )
                } catch (e: Exception) {
                    // Event emission may fail if React context is not available
                }
            }
        }

        @JvmStatic
        private external fun initNativeSignalHandler(crashMarkerPath: String)
    }

    override fun uncaughtException(thread: Thread, throwable: Throwable) {
        try {
            // Set crash marker
            val prefs: SharedPreferences = context.getSharedPreferences(
                AeropushConfigConstants.SHARED_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            prefs.edit().putBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, true).apply()

            // Write crash marker file
            val markerFile = File(context.filesDir, CRASH_MARKER_FILE)
            val crashInfo = JSONObject().apply {
                put("type", "java_exception")
                put("thread", thread.name)
                put("exception", throwable.javaClass.name)
                put("message", throwable.message ?: "")
                put("timestamp", System.currentTimeMillis())
            }
            markerFile.writeText(crashInfo.toString())
        } catch (e: Exception) {
            // Best effort crash marker write
        }

        // Chain to the default handler
        defaultHandler?.uncaughtException(thread, throwable)
    }
}
