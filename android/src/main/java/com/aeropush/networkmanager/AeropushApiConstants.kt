package com.aeropush.networkmanager

object AeropushApiConstants {
    const val API_BASE_URL = "https://api.example.com"

    const val PATH_SYNC = "/api/v1/sdk/sync"
    const val PATH_LOG_EVENTS = "/api/v1/analytics/log-bulk-events"
    const val PATH_GET_META_FROM_HASH = "/api/v1/sdk/get-meta-from-hash"

    const val HEADER_SDK_TOKEN = "x-sdk-access-token"
    const val HEADER_APP_TOKEN = "x-app-token"
    const val HEADER_CONTENT_TYPE = "Content-Type"
    const val CONTENT_TYPE_JSON = "application/json"

    const val CONNECT_TIMEOUT_MS = 15_000
    const val READ_TIMEOUT_MS = 30_000

    const val DOWNLOAD_BUFFER_SIZE = 8192
    const val DOWNLOAD_PROGRESS_THROTTLE_MS = 200L

    const val BUNDLE_FILE_NAME = "index.android.bundle"
    const val BUNDLE_ZIP_FILE_NAME = "bundle.zip"
}
