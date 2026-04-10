package com.aeropush.utils

import java.io.*
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream

object AeropushFileManager {

    private const val BUFFER_SIZE = 8192
    private const val MAX_ENTRY_SIZE = 100 * 1024 * 1024L // 100 MB per entry
    private const val MAX_TOTAL_SIZE = 500 * 1024 * 1024L // 500 MB total
    private const val MAX_ENTRIES = 1000

    /**
     * Unzips a file to the target directory with path traversal protection.
     * @return true if extraction succeeded
     */
    fun unzip(zipFilePath: String, targetDir: String): Boolean {
        val targetDirectory = File(targetDir)
        if (!targetDirectory.exists()) {
            targetDirectory.mkdirs()
        }

        val canonicalTarget = targetDirectory.canonicalPath

        var totalSize = 0L
        var entryCount = 0

        try {
            ZipInputStream(BufferedInputStream(FileInputStream(zipFilePath))).use { zis ->
                var entry: ZipEntry? = zis.nextEntry
                while (entry != null) {
                    entryCount++
                    if (entryCount > MAX_ENTRIES) {
                        throw SecurityException("Too many entries in zip file (max: $MAX_ENTRIES)")
                    }

                    val destFile = File(targetDirectory, entry.name)
                    val canonicalDest = destFile.canonicalPath

                    // Path traversal protection
                    if (!canonicalDest.startsWith(canonicalTarget)) {
                        throw SecurityException("Zip entry attempts path traversal: ${entry.name}")
                    }

                    if (entry.isDirectory) {
                        destFile.mkdirs()
                    } else {
                        destFile.parentFile?.mkdirs()

                        var entrySize = 0L
                        FileOutputStream(destFile).use { fos ->
                            BufferedOutputStream(fos, BUFFER_SIZE).use { bos ->
                                val buffer = ByteArray(BUFFER_SIZE)
                                var count: Int
                                while (zis.read(buffer).also { count = it } != -1) {
                                    entrySize += count
                                    totalSize += count

                                    if (entrySize > MAX_ENTRY_SIZE) {
                                        throw SecurityException("Zip entry too large: ${entry!!.name}")
                                    }
                                    if (totalSize > MAX_TOTAL_SIZE) {
                                        throw SecurityException("Total unzipped size exceeds limit")
                                    }

                                    bos.write(buffer, 0, count)
                                }
                            }
                        }
                    }

                    zis.closeEntry()
                    entry = zis.nextEntry
                }
            }
            return true
        } catch (e: SecurityException) {
            deleteDirectory(targetDirectory)
            throw e
        } catch (e: Exception) {
            deleteDirectory(targetDirectory)
            return false
        }
    }

    /**
     * Copies a file from source to destination.
     */
    fun copyFile(source: File, dest: File): Boolean {
        return try {
            dest.parentFile?.mkdirs()
            source.inputStream().use { input ->
                dest.outputStream().use { output ->
                    input.copyTo(output, BUFFER_SIZE)
                }
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Moves a file from source to destination.
     * Tries rename first, falls back to copy+delete.
     */
    fun moveFile(source: File, dest: File): Boolean {
        dest.parentFile?.mkdirs()
        if (source.renameTo(dest)) {
            return true
        }
        // Fallback: copy then delete
        return if (copyFile(source, dest)) {
            source.delete()
            true
        } else {
            false
        }
    }

    /**
     * Recursively deletes a directory and all its contents.
     */
    fun deleteDirectory(dir: File): Boolean {
        if (dir.isDirectory) {
            dir.listFiles()?.forEach { child ->
                deleteDirectory(child)
            }
        }
        return dir.delete()
    }

    /**
     * Ensures a directory exists, creating it if necessary.
     */
    fun ensureDirectory(path: String): File {
        val dir = File(path)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    /**
     * Checks if a bundle file exists at the given path.
     */
    fun bundleExists(bundlePath: String): Boolean {
        return File(bundlePath).exists() && File(bundlePath).isFile
    }

    /**
     * Validates that a zip file is not corrupted by checking its header.
     */
    fun isValidZip(zipFilePath: String): Boolean {
        return try {
            val file = File(zipFilePath)
            if (!file.exists() || file.length() < 4) return false

            FileInputStream(file).use { fis ->
                val header = ByteArray(4)
                fis.read(header)
                // PK zip magic number: 0x504B0304
                header[0] == 0x50.toByte() &&
                    header[1] == 0x4B.toByte() &&
                    header[2] == 0x03.toByte() &&
                    header[3] == 0x04.toByte()
            }
        } catch (e: Exception) {
            false
        }
    }
}
