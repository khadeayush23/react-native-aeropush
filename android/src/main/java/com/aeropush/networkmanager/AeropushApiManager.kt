package com.aeropush.networkmanager

import com.aeropush.storage.AeropushStateManager
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

object AeropushApiManager {

    /**
     * Performs an HTTP POST request with JSON body and auth headers.
     *
     * @param path API path (appended to base URL)
     * @param body JSON body to send
     * @return JSONObject response, or null on failure
     */
    fun post(path: String, body: JSONObject): JSONObject? {
        return try {
            val config = AeropushStateManager.getConfig()
            val url = URL("${AeropushApiConstants.API_BASE_URL}$path")
            val connection = url.openConnection() as HttpURLConnection

            connection.requestMethod = "POST"
            connection.connectTimeout = AeropushApiConstants.CONNECT_TIMEOUT_MS
            connection.readTimeout = AeropushApiConstants.READ_TIMEOUT_MS
            connection.doOutput = true
            connection.doInput = true

            // Set headers
            connection.setRequestProperty(AeropushApiConstants.HEADER_CONTENT_TYPE, AeropushApiConstants.CONTENT_TYPE_JSON)
            if (config.appToken.isNotEmpty()) {
                connection.setRequestProperty(AeropushApiConstants.HEADER_APP_TOKEN, config.appToken)
            }
            if (config.sdkToken.isNotEmpty()) {
                connection.setRequestProperty(AeropushApiConstants.HEADER_SDK_TOKEN, config.sdkToken)
            }

            // Write body
            OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            val stream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }

            val responseBody = BufferedReader(InputStreamReader(stream, Charsets.UTF_8)).use { reader ->
                reader.readText()
            }

            connection.disconnect()

            if (responseCode in 200..299) {
                JSONObject(responseBody)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Performs an HTTP POST with additional custom headers.
     */
    fun postWithHeaders(path: String, body: JSONObject, headers: Map<String, String>): JSONObject? {
        return try {
            val config = AeropushStateManager.getConfig()
            val url = URL("${AeropushApiConstants.API_BASE_URL}$path")
            val connection = url.openConnection() as HttpURLConnection

            connection.requestMethod = "POST"
            connection.connectTimeout = AeropushApiConstants.CONNECT_TIMEOUT_MS
            connection.readTimeout = AeropushApiConstants.READ_TIMEOUT_MS
            connection.doOutput = true
            connection.doInput = true

            connection.setRequestProperty(AeropushApiConstants.HEADER_CONTENT_TYPE, AeropushApiConstants.CONTENT_TYPE_JSON)
            if (config.appToken.isNotEmpty()) {
                connection.setRequestProperty(AeropushApiConstants.HEADER_APP_TOKEN, config.appToken)
            }
            if (config.sdkToken.isNotEmpty()) {
                connection.setRequestProperty(AeropushApiConstants.HEADER_SDK_TOKEN, config.sdkToken)
            }
            headers.forEach { (key, value) ->
                connection.setRequestProperty(key, value)
            }

            OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            val stream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }

            val responseBody = BufferedReader(InputStreamReader(stream, Charsets.UTF_8)).use { reader ->
                reader.readText()
            }

            connection.disconnect()

            if (responseCode in 200..299) {
                JSONObject(responseBody)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
