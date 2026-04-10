package com.aeropush.utils

import android.content.Context
import android.os.Build
import org.json.JSONObject

object AeropushDeviceInfo {

    fun collect(context: Context): JSONObject {
        return JSONObject().apply {
            put("os", "android")
            put("osVersion", Build.VERSION.RELEASE)
            put("sdkInt", Build.VERSION.SDK_INT)
            put("manufacturer", Build.MANUFACTURER)
            put("model", Build.MODEL)
            put("brand", Build.BRAND)
            put("device", Build.DEVICE)
            put("product", Build.PRODUCT)
            put("hardware", Build.HARDWARE)
            put("isEmulator", isEmulator())
            put("packageName", context.packageName)
            try {
                val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                put("appVersionName", packageInfo.versionName ?: "")
                put("appVersionCode", if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode.toLong()
                })
            } catch (e: Exception) {
                put("appVersionName", "")
                put("appVersionCode", 0)
            }
            put("supportedAbis", Build.SUPPORTED_ABIS.joinToString(","))
        }
    }

    fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
            || Build.FINGERPRINT.startsWith("unknown")
            || Build.MODEL.contains("google_sdk")
            || Build.MODEL.contains("Emulator")
            || Build.MODEL.contains("Android SDK built for x86")
            || Build.MANUFACTURER.contains("Genymotion")
            || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
            || "google_sdk" == Build.PRODUCT
            || Build.HARDWARE.contains("goldfish")
            || Build.HARDWARE.contains("ranchu"))
    }
}
