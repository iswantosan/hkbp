package com.app.hkbp

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hkbp/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "downloadFile" -> {
                        val url = call.argument<String>("url")
                        val fileName = call.argument<String>("fileName")
                        
                        android.util.Log.d("DownloadManager", "Received download request: url=$url, fileName=$fileName")
                        
                        if (url != null && fileName != null) {
                            try {
                                val downloadId = downloadFile(url, fileName)
                                android.util.Log.d("DownloadManager", "Download started with ID: $downloadId")
                                result.success(downloadId)
                            } catch (e: Exception) {
                                android.util.Log.e("DownloadManager", "Error starting download: ${e.message}", e)
                                result.error("DOWNLOAD_ERROR", "Failed to start download: ${e.message}", null)
                            }
                        } else {
                            android.util.Log.e("DownloadManager", "Invalid arguments: url=$url, fileName=$fileName")
                            result.error("INVALID_ARGUMENT", "URL and fileName are required", null)
                        }
                    }
                    else -> {
                        android.util.Log.w("DownloadManager", "Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("DownloadManager", "Error in method call handler: ${e.message}", e)
                result.error("UNKNOWN_ERROR", "An error occurred: ${e.message}", null)
            }
        }
    }

    private fun downloadFile(url: String, fileName: String): Long {
        try {
            val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
                ?: throw IllegalStateException("DownloadManager service not available")
            
            val request = DownloadManager.Request(Uri.parse(url))
            
            // Set destination to Downloads folder
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            
            // Set notification visibility
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            
            // Set title and description
            request.setTitle(fileName)
            request.setDescription("Mengunduh $fileName")
            
            // Set MIME type
            request.setMimeType("application/pdf")
            
            // Allow scanning by MediaStore
            request.allowScanningByMediaScanner()
            
            // Enqueue download
            val downloadId = downloadManager.enqueue(request)
            
            if (downloadId <= 0) {
                throw IllegalStateException("DownloadManager returned invalid download ID: $downloadId")
            }
            
            return downloadId
        } catch (e: Exception) {
            android.util.Log.e("DownloadManager", "Error in downloadFile: ${e.message}", e)
            throw e
        }
    }
}


