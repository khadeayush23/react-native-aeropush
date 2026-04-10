package com.aeropush.networkmanager

interface AeropushDownloadCallback {
    fun onSuccess(hash: String)
    fun onReject(error: String)
    fun onProgress(progress: Int)
}
