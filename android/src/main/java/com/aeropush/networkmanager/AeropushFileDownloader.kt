package com.aeropush.networkmanager

import com.aeropush.storage.AeropushStateManager
import com.aeropush.utils.AeropushFileManager
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Downloads bundle zip files with progress reporting and zip validation.
 */
object AeropushFileDownloader {

    /**
     * Downloads a bundle from the given URL to the temp directory.
     *
     * @param downloadUrl The URL to download from
     * @param hash The expected hash of the bundle
     * @param isProduction Whether this is a production or stage download
     * @param callback Progress and completion callbacks
     */
    fun downloadBundle(
        downloadUrl: String,
        hash: String,
        isProduction: Boolean,
        callback: AeropushDownloadCallback
    ) {
        if (!AeropushDownloadCacheManager.startDownload(hash, downloadUrl)) {
            callback.onReject("Download already in progress for hash: $hash")
            return
        }

        Thread {
            var connection: HttpURLConnection? = null
            try {
                val tempDir = AeropushStateManager.getTempDir(isProduction)
                val tempDirFile = AeropushFileManager.ensureDirectory(tempDir)
                val zipFile = File(tempDirFile, AeropushApiConstants.BUNDLE_ZIP_FILE_NAME)

                // Clear any existing temp files
                if (zipFile.exists()) zipFile.delete()

                val url = URL(downloadUrl)
                connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = AeropushApiConstants.CONNECT_TIMEOUT_MS
                connection.readTimeout = AeropushApiConstants.READ_TIMEOUT_MS
                connection.requestMethod = "GET"

                val config = AeropushStateManager.getConfig()
                if (config.appToken.isNotEmpty()) {
                    connection.setRequestProperty(AeropushApiConstants.HEADER_APP_TOKEN, config.appToken)
                }
                if (config.sdkToken.isNotEmpty()) {
                    connection.setRequestProperty(AeropushApiConstants.HEADER_SDK_TOKEN, config.sdkToken)
                }

                connection.connect()

                val responseCode = connection.responseCode
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    AeropushDownloadCacheManager.markFailed(hash, "HTTP $responseCode")
                    callback.onReject("Download failed with HTTP $responseCode")
                    return@Thread
                }

                val totalBytes = connection.contentLength.toLong()
                var downloadedBytes = 0L
                var lastProgressEmitTime = 0L

                BufferedInputStream(connection.inputStream).use { input ->
                    FileOutputStream(zipFile).use { output ->
                        val buffer = ByteArray(AeropushApiConstants.DOWNLOAD_BUFFER_SIZE)
                        var bytesRead: Int

                        while (input.read(buffer).also { bytesRead = it } != -1) {
                            output.write(buffer, 0, bytesRead)
                            downloadedBytes += bytesRead

                            // Throttle progress updates
                            val now = System.currentTimeMillis()
                            if (now - lastProgressEmitTime >= AeropushApiConstants.DOWNLOAD_PROGRESS_THROTTLE_MS) {
                                val progress = if (totalBytes > 0) {
                                    ((downloadedBytes * 100) / totalBytes).toInt().coerceIn(0, 100)
                                } else {
                                    -1
                                }
                                AeropushDownloadCacheManager.updateProgress(hash, progress)
                                callback.onProgress(progress)
                                lastProgressEmitTime = now
                            }
                        }
                    }
                }

                // Validate zip
                AeropushDownloadCacheManager.updateState(hash, AeropushDownloadCacheManager.DownloadState.VERIFYING)
                if (!AeropushFileManager.isValidZip(zipFile.absolutePath)) {
                    zipFile.delete()
                    AeropushDownloadCacheManager.markFailed(hash, "Invalid zip file")
                    callback.onReject("Downloaded file is not a valid zip")
                    return@Thread
                }

                // Extract zip
                AeropushDownloadCacheManager.updateState(hash, AeropushDownloadCacheManager.DownloadState.EXTRACTING)
                val extractDir = tempDirFile.absolutePath
                val extractSuccess = AeropushFileManager.unzip(zipFile.absolutePath, extractDir)
                if (!extractSuccess) {
                    AeropushFileManager.deleteDirectory(tempDirFile)
                    AeropushDownloadCacheManager.markFailed(hash, "Extraction failed")
                    callback.onReject("Failed to extract bundle zip")
                    return@Thread
                }

                // Clean up zip file
                zipFile.delete()

                // Verify bundle file exists after extraction
                val bundleFile = File(extractDir, AeropushApiConstants.BUNDLE_FILE_NAME)
                if (!bundleFile.exists()) {
                    AeropushFileManager.deleteDirectory(tempDirFile)
                    AeropushDownloadCacheManager.markFailed(hash, "Bundle file not found after extraction")
                    callback.onReject("Bundle file not found in extracted archive")
                    return@Thread
                }

                AeropushDownloadCacheManager.markComplete(hash)
                callback.onProgress(100)
                callback.onSuccess(hash)

            } catch (e: Exception) {
                AeropushDownloadCacheManager.markFailed(hash, e.message ?: "Unknown error")
                callback.onReject(e.message ?: "Download failed")
            } finally {
                connection?.disconnect()
                AeropushDownloadCacheManager.removeEntry(hash)
            }
        }.start()
    }
}
