package app.jws.tallybowl

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val imageExecutor = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.jws.tallybowl/share").setMethodCallHandler { call, result ->
            if (call.method != "shareImage") {
                result.notImplemented()
            } else {
                try {
                    val path = requireNotNull(call.argument<String>("path"))
                    val send = RecapSharing.intent(this, path)
                    startActivity(android.content.Intent.createChooser(send, "Share bowling recap"))
                    // This reports handoff only, never that a message was sent.
                    result.success(null)
                } catch (_: Exception) {
                    result.error("share_image", "Could not open the image share sheet. Export the recap and attach it from the receiving app.", null)
                }
            }
        }
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
            val regions = call.argument<List<Map<String, Number>>>("regions")
            imageExecutor.execute {
                try {
                    val lines = ScoreTextRecognizer.recognize(bytes, regions, call.argument<Number>("aspect")?.toDouble() ?: 1.0, call.argument<Boolean>("context") ?: false)
                    runOnUiThread { result.success(lines) }
                } catch (_: Exception) {
                    runOnUiThread { result.error("recognition", "This image could not be read. Try a clearer photo or enter frames manually.", null) }
                }
            }
        }
    }
    override fun onDestroy() {
        imageExecutor.shutdown()
        super.onDestroy()
    }
}
