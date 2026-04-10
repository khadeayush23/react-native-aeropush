package com.aeropush.storage

object AeropushConfigConstants {
    const val MODULE_NAME = "Aeropush"
    const val SHARED_PREFS_NAME = "aeropush_shared_prefs"

    const val PLATFORM_ANDROID = "android"
    const val PLATFORM_ID = "ANDROID"

    // Directory paths
    const val PROD_DIRECTORY = "AeropushProd"
    const val STAGE_DIRECTORY = "AeropushStage"
    const val NEW_FOLDER_SLOT = "AeropushNew"
    const val STABLE_FOLDER_SLOT = "AeropushStable"
    const val DEFAULT_FOLDER_SLOT = "Default"
    const val TEMP_FOLDER = "temp"

    // SharedPreferences keys
    const val KEY_APP_TOKEN = "aeropush_app_token"
    const val KEY_SDK_TOKEN = "aeropush_sdk_token"
    const val KEY_PROJECT_ID = "aeropush_project_id"
    const val KEY_UID = "aeropush_uid"
    const val KEY_APP_VERSION = "aeropush_app_version"
    const val KEY_SIGNING_KEY = "aeropush_signing_key"

    // Meta keys
    const val KEY_SWITCH_STATE = "aeropush_switch_state"
    const val KEY_PROD_CURRENT_SLOT = "aeropush_prod_current_slot"
    const val KEY_STAGE_CURRENT_SLOT = "aeropush_stage_current_slot"
    const val KEY_PROD_STABLE_HASH = "aeropush_prod_stable_hash"
    const val KEY_PROD_NEW_HASH = "aeropush_prod_new_hash"
    const val KEY_PROD_TEMP_HASH = "aeropush_prod_temp_hash"
    const val KEY_STAGE_STABLE_HASH = "aeropush_stage_stable_hash"
    const val KEY_STAGE_NEW_HASH = "aeropush_stage_new_hash"
    const val KEY_STAGE_TEMP_HASH = "aeropush_stage_temp_hash"
    const val KEY_LAUNCH_COUNT = "aeropush_launch_count"
    const val KEY_LAST_ROLLBACK_TIME = "aeropush_last_rollback_time"
    const val KEY_CRASH_MARKER = "aeropush_crash_marker"

    // Resource keys (from app's resources)
    const val RES_APP_TOKEN = "aeropush_app_token"
    const val RES_PROJECT_ID = "aeropush_project_id"
    const val RES_SIGNING_KEY = "aeropush_signing_key"

    // Bundle file name
    const val BUNDLE_FILE_NAME = "index.android.bundle"
    const val BUNDLE_ZIP_FILE_NAME = "bundle.zip"
    const val MANIFEST_FILE_NAME = "manifest.json"
}
