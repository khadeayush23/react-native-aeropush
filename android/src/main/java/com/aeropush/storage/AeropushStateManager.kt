package com.aeropush.storage

import android.content.Context

object AeropushStateManager {
    @Volatile
    private var config: AeropushConfig? = null

    @Volatile
    private var meta: AeropushMeta? = null

    @Volatile
    private var isMounted: Boolean = false

    @Volatile
    private var applicationContext: Context? = null

    @Synchronized
    fun initialize(context: Context) {
        applicationContext = context.applicationContext
        config = AeropushConfig(context.applicationContext)
        meta = AeropushMeta(context.applicationContext)
    }

    @Synchronized
    fun getConfig(): AeropushConfig {
        return config ?: throw IllegalStateException("AeropushStateManager not initialized. Call initialize() first.")
    }

    @Synchronized
    fun getMeta(): AeropushMeta {
        return meta ?: throw IllegalStateException("AeropushStateManager not initialized. Call initialize() first.")
    }

    fun getApplicationContext(): Context {
        return applicationContext ?: throw IllegalStateException("AeropushStateManager not initialized. Call initialize() first.")
    }

    fun isInitialized(): Boolean = config != null && meta != null

    fun setMounted(mounted: Boolean) {
        isMounted = mounted
    }

    fun isMounted(): Boolean = isMounted

    fun getBaseDir(): String {
        val context = getApplicationContext()
        return context.filesDir.absolutePath
    }

    fun getProdDir(): String {
        return "${getBaseDir()}/${AeropushConfigConstants.PROD_DIRECTORY}"
    }

    fun getStageDir(): String {
        return "${getBaseDir()}/${AeropushConfigConstants.STAGE_DIRECTORY}"
    }

    fun getSlotDir(isProduction: Boolean, slotState: SlotState): String {
        val baseDir = if (isProduction) getProdDir() else getStageDir()
        return when (slotState) {
            SlotState.STABLE -> "$baseDir/${AeropushConfigConstants.STABLE_FOLDER_SLOT}"
            SlotState.NEW -> "$baseDir/${AeropushConfigConstants.NEW_FOLDER_SLOT}"
            SlotState.DEFAULT -> "$baseDir/${AeropushConfigConstants.DEFAULT_FOLDER_SLOT}"
        }
    }

    fun getTempDir(isProduction: Boolean): String {
        val baseDir = if (isProduction) getProdDir() else getStageDir()
        return "$baseDir/${AeropushConfigConstants.TEMP_FOLDER}"
    }

    fun getBundlePath(isProduction: Boolean, slotState: SlotState): String {
        return "${getSlotDir(isProduction, slotState)}/${AeropushConfigConstants.BUNDLE_FILE_NAME}"
    }
}
