package com.aeropush.storage

import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import org.json.JSONObject

class AeropushConfig(context: Context) {
    var appToken: String = ""
        private set
    var sdkToken: String = ""
        private set
    var projectId: String = ""
        private set
    var uid: String = ""
        private set
    var appVersion: String = ""
        private set
    var signingKey: String = ""
        private set

    private val prefs: SharedPreferences = context.getSharedPreferences(
        AeropushConfigConstants.SHARED_PREFS_NAME,
        Context.MODE_PRIVATE
    )

    init {
        loadFromResources(context)
        loadFromPrefs()
        resolveAppVersion(context)
    }

    private fun loadFromResources(context: Context) {
        val resources = context.resources
        val packageName = context.packageName

        val appTokenResId = resources.getIdentifier(
            AeropushConfigConstants.RES_APP_TOKEN, "string", packageName
        )
        if (appTokenResId != 0) {
            appToken = resources.getString(appTokenResId)
        }

        val projectIdResId = resources.getIdentifier(
            AeropushConfigConstants.RES_PROJECT_ID, "string", packageName
        )
        if (projectIdResId != 0) {
            projectId = resources.getString(projectIdResId)
        }

        val signingKeyResId = resources.getIdentifier(
            AeropushConfigConstants.RES_SIGNING_KEY, "string", packageName
        )
        if (signingKeyResId != 0) {
            signingKey = resources.getString(signingKeyResId)
        }
    }

    private fun loadFromPrefs() {
        prefs.getString(AeropushConfigConstants.KEY_APP_TOKEN, null)?.let {
            if (it.isNotEmpty()) appToken = it
        }
        prefs.getString(AeropushConfigConstants.KEY_SDK_TOKEN, null)?.let {
            sdkToken = it
        }
        prefs.getString(AeropushConfigConstants.KEY_PROJECT_ID, null)?.let {
            if (it.isNotEmpty()) projectId = it
        }
        prefs.getString(AeropushConfigConstants.KEY_UID, null)?.let {
            uid = it
        }
        prefs.getString(AeropushConfigConstants.KEY_SIGNING_KEY, null)?.let {
            if (it.isNotEmpty()) signingKey = it
        }
    }

    private fun resolveAppVersion(context: Context) {
        try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            appVersion = packageInfo.versionName ?: ""
        } catch (e: PackageManager.NameNotFoundException) {
            appVersion = ""
        }
        prefs.getString(AeropushConfigConstants.KEY_APP_VERSION, null)?.let {
            if (it.isNotEmpty()) appVersion = it
        }
    }

    fun updateSdkToken(token: String) {
        sdkToken = token
        prefs.edit().putString(AeropushConfigConstants.KEY_SDK_TOKEN, token).apply()
    }

    fun updateUid(newUid: String) {
        uid = newUid
        prefs.edit().putString(AeropushConfigConstants.KEY_UID, newUid).apply()
    }

    fun save() {
        prefs.edit()
            .putString(AeropushConfigConstants.KEY_APP_TOKEN, appToken)
            .putString(AeropushConfigConstants.KEY_SDK_TOKEN, sdkToken)
            .putString(AeropushConfigConstants.KEY_PROJECT_ID, projectId)
            .putString(AeropushConfigConstants.KEY_UID, uid)
            .putString(AeropushConfigConstants.KEY_APP_VERSION, appVersion)
            .putString(AeropushConfigConstants.KEY_SIGNING_KEY, signingKey)
            .apply()
    }

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("appToken", appToken)
            put("sdkToken", sdkToken)
            put("projectId", projectId)
            put("uid", uid)
            put("appVersion", appVersion)
        }
    }
}
