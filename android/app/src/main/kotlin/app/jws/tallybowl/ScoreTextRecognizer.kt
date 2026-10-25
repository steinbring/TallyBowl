package app.jws.tallybowl

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import android.graphics.Rect
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.ByteArrayInputStream
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

/** Runs only on the activity's image executor. The Latin model is bundled. */
internal object ScoreTextRecognizer {
    private const val MAX_BYTES = 40 * 1024 * 1024
    private const val MAX_DIMENSION = 4096

    fun recognize(bytes: ByteArray, requested: List<Map<String, Number>>?, aspect: Double = 1.0): List<Map<String, Any>> {
        require(bytes.size <= MAX_BYTES && aspect.isFinite() && aspect in 1.0..3.0)
        val bitmap = decodeUpright(bytes)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            val regions = requested ?: listOf(mapOf("x" to 0, "y" to 0, "width" to 1, "height" to 1))
            require(regions.size in 1..20)
            val output = mutableListOf<Map<String, Any>>()
            for (region in regions) {
                val x = region["x"]!!.toDouble()
                val y = region["y"]!!.toDouble()
                val width = region["width"]!!.toDouble()
                val height = region["height"]!!.toDouble()
                require(listOf(x, y, width, height).all { it.isFinite() })
                require(x >= 0 && y >= 0 && width > 0 && height > 0 && x + width <= 1.000001 && y + height <= 1.000001)
                val left = floor(x * bitmap.width).toInt().coerceIn(0, bitmap.width - 1)
                val top = floor(y * bitmap.height).toInt().coerceIn(0, bitmap.height - 1)
                val right = ceil((x + width) * bitmap.width).toInt().coerceIn(left + 1, bitmap.width)
                val bottom = ceil((y + height) * bitmap.height).toInt().coerceIn(top + 1, bitmap.height)
                val crop = Bitmap.createBitmap(bitmap, left, top, right - left, bottom - top)
                // Scoreboard fonts are often tall and condensed. A bounded
                // horizontal normalization makes a cell legible without a
                // language model or inferring deliveries from its total.
                val input = if (requested == null) {
                    if (aspect == 1.0) crop else Bitmap.createScaledBitmap(crop, crop.width, max(1, (crop.height / aspect).toInt()), true)
                } else Bitmap.createScaledBitmap(crop,
                    (crop.width.toDouble() / crop.height * 128 * 2.5).toInt().coerceIn(128, 640), 128, true)
                try {
                    // Await on the worker, keeping bitmap storage alive until
                    // ML Kit has finished. No image work runs on the UI thread.
                    val text = Tasks.await(recognizer.process(InputImage.fromBitmap(input, 0)))
                    fun bounds(value: String, box: Rect): Map<String, Any> = mapOf(
                        "text" to value,
                        "x" to (left + box.left.toDouble() / input.width * crop.width) / bitmap.width,
                        "y" to (top + box.top.toDouble() / input.height * crop.height) / bitmap.height,
                        "width" to box.width().toDouble() / input.width * crop.width / bitmap.width,
                        "height" to box.height().toDouble() / input.height * crop.height / bitmap.height)
                    for (block in text.textBlocks) for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        output.add(bounds(line.text, box) + mapOf("elements" to line.elements.mapNotNull { word ->
                            word.boundingBox?.let { wordBox -> bounds(word.text, wordBox) + mapOf(
                                "elements" to word.symbols.mapNotNull { symbol ->
                                    symbol.boundingBox?.let { bounds(symbol.text, it) }
                                }) }
                        }))
                    }
                    if (requested != null) for (stroke in DashStrokeDetector.find(crop)) {
                        val mark = mapOf<String, Any>("text" to "-", "stroke" to true,
                            "x" to (left + stroke.left).toDouble() / bitmap.width,
                            "y" to (top + stroke.top).toDouble() / bitmap.height,
                            "width" to stroke.width().toDouble() / bitmap.width,
                            "height" to stroke.height().toDouble() / bitmap.height)
                        output.add(mark + mapOf("elements" to listOf(mark)))
                    }
                } finally {
                    if (input !== crop) input.recycle()
                    if (crop !== bitmap) crop.recycle()
                }
            }
            return output
        } finally {
            recognizer.close()
            bitmap.recycle()
        }
    }

    private fun decodeUpright(bytes: ByteArray): Bitmap {
        val dimensions = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, dimensions)
        require(dimensions.outWidth > 0 && dimensions.outHeight > 0)
        var sample = 1
        while (dimensions.outWidth / sample > MAX_DIMENSION || dimensions.outHeight / sample > MAX_DIMENSION) sample *= 2
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inSampleSize = sample; inPreferredConfig = Bitmap.Config.ARGB_8888 })
            ?: throw IllegalArgumentException("Unsupported image")
        val orientation = try {
            ByteArrayInputStream(bytes).use {
                ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            }
        } catch (_: java.io.IOException) {
            // A missing or unreadable optional EXIF block must not prevent
            // recognition of an otherwise decodable image.
            ExifInterface.ORIENTATION_NORMAL
        }
        val transform = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> transform.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> transform.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> transform.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { transform.setRotate(90f); transform.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_90 -> transform.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> { transform.setRotate(-90f); transform.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_270 -> transform.setRotate(-90f)
        }
        if (transform.isIdentity) return bitmap
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, transform, true).also {
            if (it !== bitmap) bitmap.recycle()
        }
    }
}
