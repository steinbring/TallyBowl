package app.jws.tallybowl

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val imageExecutor = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.jws.tallybowl/vision").setMethodCallHandler { call, result ->
            if (call.method != "recognizeText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            if (bytes == null) {
                result.error("invalid_image", "Select an image first.", null)
                return@setMethodCallHandler
            }
            imageExecutor.execute {
                var file: File? = null
                try {
                    // This URI stays inside this process; it is never exposed in
                    // an Intent to another app. ML Kit's documented file loader
                    // handles EXIF rotation. ByteBuffer expects raw YUV, not the
                    // compressed photo bytes received here. No network service
                    // receives the image; the Latin model is bundled in the APK.
                    val source = File.createTempFile("tallybowl-ocr-", ".jpg", cacheDir)
                    file = source
                    source.writeBytes(bytes)
                    val image = InputImage.fromFilePath(this, Uri.fromFile(source))
                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    val width = (if (image.rotationDegrees % 180 == 0) image.width else image.height).toDouble()
                    val height = (if (image.rotationDegrees % 180 == 0) image.height else image.width).toDouble()
                    recognizer.process(image).addOnSuccessListener { text ->
                        val lines = text.textBlocks.flatMap { block -> block.lines.mapNotNull { line ->
                            line.boundingBox?.let { box -> mapOf("text" to line.text, "x" to box.left / width, "y" to box.top / height, "width" to box.width() / width, "height" to box.height() / height) }
                        } }
                        result.success(lines)
                    }.addOnFailureListener {
                        result.error("recognition", "This image could not be read. Try a clearer photo or enter frames manually.", null)
                    }.addOnCompleteListener {
                        recognizer.close()
                        source.delete()
                    }
                } catch (_: Exception) {
                    file?.delete()
                    runOnUiThread { result.error("recognition", "This image could not be opened.", null) }
                }
            }
        }
    }
    override fun onDestroy() {
        imageExecutor.shutdown()
        super.onDestroy()
    }
}
