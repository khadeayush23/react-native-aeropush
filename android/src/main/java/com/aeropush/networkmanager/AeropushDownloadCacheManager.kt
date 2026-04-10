package com.aeropush.networkmanager

import java.util.concurrent.ConcurrentHashMap

/**
 * Tracks active downloads to prevent duplicate concurrent downloads.
 */
object AeropushDownloadCacheManager {

    enum class DownloadState {
        IDLE,
        DOWNLOADING,
        EXTRACTING,
        VERIFYING,
        COMPLETE,
        FAILED
    }

    data class DownloadEntry(
        val hash: String,
        val url: String,
        var state: DownloadState = DownloadState.IDLE,
        var progress: Int = 0,
        var error: String? = null
    )

    private val downloads = ConcurrentHashMap<String, DownloadEntry>()

    fun isDownloading(hash: String): Boolean {
        val entry = downloads[hash] ?: return false
        return entry.state == DownloadState.DOWNLOADING || entry.state == DownloadState.EXTRACTING || entry.state == DownloadState.VERIFYING
    }

    fun startDownload(hash: String, url: String): Boolean {
        if (isDownloading(hash)) return false
        downloads[hash] = DownloadEntry(hash, url, DownloadState.DOWNLOADING)
        return true
    }

    fun updateState(hash: String, state: DownloadState) {
        downloads[hash]?.state = state
    }

    fun updateProgress(hash: String, progress: Int) {
        downloads[hash]?.progress = progress
    }

    fun markComplete(hash: String) {
        downloads[hash]?.state = DownloadState.COMPLETE
    }

    fun markFailed(hash: String, error: String) {
        downloads[hash]?.apply {
            state = DownloadState.FAILED
            this.error = error
        }
    }

    fun removeEntry(hash: String) {
        downloads.remove(hash)
    }

    fun clear() {
        downloads.clear()
    }
}
