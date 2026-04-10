package com.aeropush.storage

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

class AeropushMeta(context: Context) {
    var switchState: SwitchState = SwitchState.PROD
        private set
    var prodCurrentSlot: SlotState = SlotState.DEFAULT
        private set
    var stageCurrentSlot: SlotState = SlotState.DEFAULT
        private set
    var prodStableHash: String = ""
        private set
    var prodNewHash: String = ""
        private set
    var prodTempHash: String = ""
        private set
    var stageStableHash: String = ""
        private set
    var stageNewHash: String = ""
        private set
    var stageTempHash: String = ""
        private set
    var launchCount: Int = 0
        private set
    var lastRollbackTime: Long = 0L
        private set
    var crashMarker: Boolean = false
        private set

    private val prefs: SharedPreferences = context.getSharedPreferences(
        AeropushConfigConstants.SHARED_PREFS_NAME,
        Context.MODE_PRIVATE
    )

    companion object {
        const val ROLLBACK_TTL_MS = 6L * 60 * 60 * 1000 // 6 hours
        const val STABILIZATION_THRESHOLD = 3
    }

    init {
        loadFromPrefs()
    }

    private fun loadFromPrefs() {
        switchState = SwitchState.fromValue(
            prefs.getString(AeropushConfigConstants.KEY_SWITCH_STATE, SwitchState.PROD.value) ?: SwitchState.PROD.value
        )
        prodCurrentSlot = SlotState.fromValue(
            prefs.getString(AeropushConfigConstants.KEY_PROD_CURRENT_SLOT, SlotState.DEFAULT.value) ?: SlotState.DEFAULT.value
        )
        stageCurrentSlot = SlotState.fromValue(
            prefs.getString(AeropushConfigConstants.KEY_STAGE_CURRENT_SLOT, SlotState.DEFAULT.value) ?: SlotState.DEFAULT.value
        )
        prodStableHash = prefs.getString(AeropushConfigConstants.KEY_PROD_STABLE_HASH, "") ?: ""
        prodNewHash = prefs.getString(AeropushConfigConstants.KEY_PROD_NEW_HASH, "") ?: ""
        prodTempHash = prefs.getString(AeropushConfigConstants.KEY_PROD_TEMP_HASH, "") ?: ""
        stageStableHash = prefs.getString(AeropushConfigConstants.KEY_STAGE_STABLE_HASH, "") ?: ""
        stageNewHash = prefs.getString(AeropushConfigConstants.KEY_STAGE_NEW_HASH, "") ?: ""
        stageTempHash = prefs.getString(AeropushConfigConstants.KEY_STAGE_TEMP_HASH, "") ?: ""
        launchCount = prefs.getInt(AeropushConfigConstants.KEY_LAUNCH_COUNT, 0)
        lastRollbackTime = prefs.getLong(AeropushConfigConstants.KEY_LAST_ROLLBACK_TIME, 0L)
        crashMarker = prefs.getBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, false)
    }

    fun setSwitchState(state: SwitchState) {
        switchState = state
        prefs.edit().putString(AeropushConfigConstants.KEY_SWITCH_STATE, state.value).apply()
    }

    fun setProdCurrentSlot(slot: SlotState) {
        prodCurrentSlot = slot
        prefs.edit().putString(AeropushConfigConstants.KEY_PROD_CURRENT_SLOT, slot.value).apply()
    }

    fun setStageCurrentSlot(slot: SlotState) {
        stageCurrentSlot = slot
        prefs.edit().putString(AeropushConfigConstants.KEY_STAGE_CURRENT_SLOT, slot.value).apply()
    }

    fun setProdStableHash(hash: String) {
        prodStableHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_PROD_STABLE_HASH, hash).apply()
    }

    fun setProdNewHash(hash: String) {
        prodNewHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_PROD_NEW_HASH, hash).apply()
    }

    fun setProdTempHash(hash: String) {
        prodTempHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_PROD_TEMP_HASH, hash).apply()
    }

    fun setStageStableHash(hash: String) {
        stageStableHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_STAGE_STABLE_HASH, hash).apply()
    }

    fun setStageNewHash(hash: String) {
        stageNewHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_STAGE_NEW_HASH, hash).apply()
    }

    fun setStageTempHash(hash: String) {
        stageTempHash = hash
        prefs.edit().putString(AeropushConfigConstants.KEY_STAGE_TEMP_HASH, hash).apply()
    }

    fun incrementLaunchCount() {
        launchCount++
        prefs.edit().putInt(AeropushConfigConstants.KEY_LAUNCH_COUNT, launchCount).apply()
    }

    fun resetLaunchCount() {
        launchCount = 0
        prefs.edit().putInt(AeropushConfigConstants.KEY_LAUNCH_COUNT, 0).apply()
    }

    fun setLastRollbackTime(time: Long) {
        lastRollbackTime = time
        prefs.edit().putLong(AeropushConfigConstants.KEY_LAST_ROLLBACK_TIME, time).apply()
    }

    fun setCrashMarker(marker: Boolean) {
        crashMarker = marker
        prefs.edit().putBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, marker).apply()
    }

    fun isRollbackCooldownActive(): Boolean {
        if (lastRollbackTime == 0L) return false
        return (System.currentTimeMillis() - lastRollbackTime) < ROLLBACK_TTL_MS
    }

    fun hasReachedStabilizationThreshold(): Boolean {
        return launchCount >= STABILIZATION_THRESHOLD
    }

    fun getActiveHash(isProduction: Boolean): String {
        val currentSlot = if (isProduction) prodCurrentSlot else stageCurrentSlot
        return when (currentSlot) {
            SlotState.STABLE -> if (isProduction) prodStableHash else stageStableHash
            SlotState.NEW -> if (isProduction) prodNewHash else stageNewHash
            SlotState.DEFAULT -> ""
        }
    }

    fun toJson(): JSONObject {
        val prodSlot = JSONObject().apply {
            put("currentSlot", prodCurrentSlot.value)
            put("stableHash", prodStableHash)
            put("newHash", prodNewHash)
            put("tempHash", prodTempHash)
        }
        val stageSlot = JSONObject().apply {
            put("currentSlot", stageCurrentSlot.value)
            put("stableHash", stageStableHash)
            put("newHash", stageNewHash)
            put("tempHash", stageTempHash)
        }
        return JSONObject().apply {
            put("switchState", switchState.value)
            put("prodSlot", prodSlot)
            put("stageSlot", stageSlot)
        }
    }

    fun save() {
        prefs.edit()
            .putString(AeropushConfigConstants.KEY_SWITCH_STATE, switchState.value)
            .putString(AeropushConfigConstants.KEY_PROD_CURRENT_SLOT, prodCurrentSlot.value)
            .putString(AeropushConfigConstants.KEY_STAGE_CURRENT_SLOT, stageCurrentSlot.value)
            .putString(AeropushConfigConstants.KEY_PROD_STABLE_HASH, prodStableHash)
            .putString(AeropushConfigConstants.KEY_PROD_NEW_HASH, prodNewHash)
            .putString(AeropushConfigConstants.KEY_PROD_TEMP_HASH, prodTempHash)
            .putString(AeropushConfigConstants.KEY_STAGE_STABLE_HASH, stageStableHash)
            .putString(AeropushConfigConstants.KEY_STAGE_NEW_HASH, stageNewHash)
            .putString(AeropushConfigConstants.KEY_STAGE_TEMP_HASH, stageTempHash)
            .putInt(AeropushConfigConstants.KEY_LAUNCH_COUNT, launchCount)
            .putLong(AeropushConfigConstants.KEY_LAST_ROLLBACK_TIME, lastRollbackTime)
            .putBoolean(AeropushConfigConstants.KEY_CRASH_MARKER, crashMarker)
            .apply()
    }
}
