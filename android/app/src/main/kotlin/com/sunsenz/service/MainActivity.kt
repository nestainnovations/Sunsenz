package com.sunsenz.service

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    companion object {
        private const val MEDIA_CAPTURE_CHANNEL = "com.sunsenz.service/media_capture"
        private const val MEDIA_CAPTURE_REQUEST = 7021
    }

    private var pendingCaptureResult: MethodChannel.Result? = null
    private var pendingCaptureFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_CAPTURE_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "capture") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val type = call.argument<String>("type")
            if (type != "image" && type != "video") {
                result.error("invalid_media_type", "Expected image or video capture.", null)
                return@setMethodCallHandler
            }
            if (pendingCaptureResult != null) {
                result.error("capture_in_progress", "A media capture is already in progress.", null)
                return@setMethodCallHandler
            }

            launchMediaCapture(type, result)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != MEDIA_CAPTURE_REQUEST) return

        val result = pendingCaptureResult ?: return
        val outputFile = pendingCaptureFile
        pendingCaptureResult = null
        pendingCaptureFile = null

        if (resultCode != Activity.RESULT_OK || outputFile == null) {
            outputFile?.delete()
            result.success(null)
            return
        }

        try {
            if (!outputFile.exists() || outputFile.length() == 0L) {
                val capturedUri: Uri = data?.data
                    ?: throw IOException("The camera did not return a captured file.")
                val input = contentResolver.openInputStream(capturedUri)
                    ?: throw IOException("The captured file could not be opened.")
                input.use { source ->
                    FileOutputStream(outputFile).use { destination ->
                        source.copyTo(destination)
                    }
                }
            }
            result.success(outputFile.absolutePath)
        } catch (error: IOException) {
            outputFile.delete()
            result.error("capture_failed", error.message, null)
        } catch (error: SecurityException) {
            outputFile.delete()
            result.error("capture_failed", error.message, null)
        }
    }

    private fun launchMediaCapture(type: String, result: MethodChannel.Result) {
        val isVideo = type == "video"
        val action = if (isVideo) MediaStore.ACTION_VIDEO_CAPTURE else MediaStore.ACTION_IMAGE_CAPTURE
        val extension = if (isVideo) ".mp4" else ".jpg"
        val outputDirectory = File(cacheDir, "captured_media")
        var outputFile: File? = null

        try {
            if (!outputDirectory.exists() && !outputDirectory.mkdirs()) {
                throw IOException("Unable to create the media capture directory.")
            }
            outputFile = File.createTempFile("capture_", extension, outputDirectory)
            val outputUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                outputFile
            )
            val intent = Intent(action).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, outputUri)
                clipData = ClipData.newUri(contentResolver, "captured media", outputUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            }

            pendingCaptureFile = outputFile
            pendingCaptureResult = result
            startActivityForResult(intent, MEDIA_CAPTURE_REQUEST)
        } catch (error: ActivityNotFoundException) {
            outputFile?.delete()
            pendingCaptureFile = null
            pendingCaptureResult = null
            result.error("camera_unavailable", error.message, null)
        } catch (error: IOException) {
            outputFile?.delete()
            result.error("capture_setup_failed", error.message, null)
        } catch (error: IllegalArgumentException) {
            outputFile?.delete()
            pendingCaptureFile = null
            pendingCaptureResult = null
            result.error("capture_setup_failed", error.message, null)
        } catch (error: SecurityException) {
            outputFile?.delete()
            pendingCaptureFile = null
            pendingCaptureResult = null
            result.error("capture_setup_failed", error.message, null)
        }
    }
}