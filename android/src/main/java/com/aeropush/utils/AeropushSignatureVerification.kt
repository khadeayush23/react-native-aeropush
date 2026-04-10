package com.aeropush.utils

import android.util.Base64
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

object AeropushSignatureVerification {

    /**
     * Verifies a JWT token's RSA signature against a public key.
     * The JWT format is: header.payload.signature (RS256)
     *
     * @param jwt The JWT string to verify
     * @param publicKeyPem The PEM-encoded RSA public key
     * @return The payload as a JSONObject if verification succeeds, null otherwise
     */
    fun verifyJwt(jwt: String, publicKeyPem: String): JSONObject? {
        return try {
            val parts = jwt.split(".")
            if (parts.size != 3) return null

            val headerPayload = "${parts[0]}.${parts[1]}"
            val signatureBytes = Base64.decode(
                parts[2].replace('-', '+').replace('_', '/'),
                Base64.NO_WRAP or Base64.NO_PADDING
            )

            // Parse the public key
            val keyString = publicKeyPem
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replace("\\s".toRegex(), "")

            val keyBytes = Base64.decode(keyString, Base64.DEFAULT)
            val keySpec = X509EncodedKeySpec(keyBytes)
            val keyFactory = KeyFactory.getInstance("RSA")
            val publicKey = keyFactory.generatePublic(keySpec)

            // Verify signature
            val sig = Signature.getInstance("SHA256withRSA")
            sig.initVerify(publicKey)
            sig.update(headerPayload.toByteArray(Charsets.UTF_8))

            if (sig.verify(signatureBytes)) {
                val payloadJson = String(
                    Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING),
                    Charsets.UTF_8
                )
                JSONObject(payloadJson)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Computes SHA-256 hash of a file and returns hex string.
     */
    fun sha256File(filePath: String): String? {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val file = File(filePath)
            FileInputStream(file).use { fis ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                while (fis.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Computes SHA-256 hash of a string and returns hex string.
     */
    fun sha256String(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Verifies the manifest hash against the expected hash.
     * The manifest is a JSON file containing file hashes.
     */
    fun verifyManifestHash(manifestPath: String, expectedHash: String): Boolean {
        return try {
            val computedHash = sha256File(manifestPath)
            computedHash != null && computedHash.equals(expectedHash, ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Verifies a bundle's signature using the signing key from config.
     * If no signing key is configured, verification is skipped (returns true).
     */
    fun verifyBundleSignature(jwt: String, signingKey: String): JSONObject? {
        if (signingKey.isEmpty()) {
            // No signing key configured, skip verification
            return try {
                val parts = jwt.split(".")
                if (parts.size != 3) null
                else {
                    val payloadJson = String(
                        Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING),
                        Charsets.UTF_8
                    )
                    JSONObject(payloadJson)
                }
            } catch (e: Exception) {
                null
            }
        }
        return verifyJwt(jwt, signingKey)
    }
}
