package com.aeropush.events

import android.content.Context
import android.content.SharedPreferences
import com.aeropush.storage.AeropushConfigConstants
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.core.DeviceEventManagerModule
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

object AeropushEventManager {
    private const val KEY_EVENT_CACHE = "aeropush_event_cache"
    private const val MAX_CACHED_EVENTS = 60
    private const val BATCH_SIZE = 9

    @Volatile
    private var reactContext: ReactApplicationContext? = null

    private val lock = Any()

    fun initialize(context: ReactApplicationContext) {
        reactContext = context
    }

    fun emitEvent(eventType: String, data: JSONObject? = null) {
        val eventPayload = JSONObject().apply {
            put("type", eventType)
            put("eventId", UUID.randomUUID().toString())
            put("eventTimestamp", System.currentTimeMillis())
            data?.keys()?.forEach { key ->
                put(key, data.get(key))
            }
        }

        cacheEvent(eventPayload)
        emitToJs(eventPayload.toString())
    }

    fun emitProdEvent(eventType: NativeProdEventType, releaseHash: String? = null, error: String? = null, progress: String? = null) {
        val data = JSONObject().apply {
            releaseHash?.let { put("releaseHash", it) }
            error?.let { put("error", it) }
            progress?.let { put("progress", it) }
        }
        emitEvent(eventType.value, data)
    }

    fun emitStageEvent(eventType: NativeStageEventType, releaseHash: String? = null, error: String? = null, progress: String? = null) {
        val data = JSONObject().apply {
            releaseHash?.let { put("releaseHash", it) }
            error?.let { put("error", it) }
            progress?.let { put("progress", it) }
        }
        emitEvent(eventType.value, data)
    }

    private fun emitToJs(eventString: String) {
        try {
            reactContext?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                ?.emit(AeropushEventName.AEROPUSH_NATIVE_EVENT, eventString)
        } catch (e: Exception) {
            // JS runtime may not be ready yet; event is still cached
        }
    }

    private fun cacheEvent(event: JSONObject) {
        synchronized(lock) {
            val prefs = getPrefs() ?: return
            val cachedJson = prefs.getString(KEY_EVENT_CACHE, "[]") ?: "[]"
            val events = try {
                JSONArray(cachedJson)
            } catch (e: Exception) {
                JSONArray()
            }

            events.put(event)

            // Trim to max size, removing oldest events
            while (events.length() > MAX_CACHED_EVENTS) {
                events.remove(0)
            }

            prefs.edit().putString(KEY_EVENT_CACHE, events.toString()).apply()
        }
    }

    fun popEvents(): String {
        synchronized(lock) {
            val prefs = getPrefs() ?: return "[]"
            val cachedJson = prefs.getString(KEY_EVENT_CACHE, "[]") ?: "[]"
            val allEvents = try {
                JSONArray(cachedJson)
            } catch (e: Exception) {
                return "[]"
            }

            if (allEvents.length() == 0) return "[]"

            val batch = JSONArray()
            val remaining = JSONArray()
            for (i in 0 until allEvents.length()) {
                if (i < BATCH_SIZE) {
                    batch.put(allEvents.getJSONObject(i))
                } else {
                    remaining.put(allEvents.getJSONObject(i))
                }
            }

            prefs.edit().putString(KEY_EVENT_CACHE, remaining.toString()).apply()
            return batch.toString()
        }
    }

    fun acknowledgeEvents(eventIds: String) {
        synchronized(lock) {
            try {
                val idsArray = JSONArray(eventIds)
                val idsSet = mutableSetOf<String>()
                for (i in 0 until idsArray.length()) {
                    idsSet.add(idsArray.getString(i))
                }

                val prefs = getPrefs() ?: return
                val cachedJson = prefs.getString(KEY_EVENT_CACHE, "[]") ?: "[]"
                val allEvents = JSONArray(cachedJson)
                val filtered = JSONArray()

                for (i in 0 until allEvents.length()) {
                    val event = allEvents.getJSONObject(i)
                    val eventId = event.optString("eventId", "")
                    if (eventId !in idsSet) {
                        filtered.put(event)
                    }
                }

                prefs.edit().putString(KEY_EVENT_CACHE, filtered.toString()).apply()
            } catch (e: Exception) {
                // Ignore malformed eventIds
            }
        }
    }

    private fun getPrefs(): SharedPreferences? {
        return reactContext?.getSharedPreferences(
            AeropushConfigConstants.SHARED_PREFS_NAME,
            Context.MODE_PRIVATE
        )
    }
}
