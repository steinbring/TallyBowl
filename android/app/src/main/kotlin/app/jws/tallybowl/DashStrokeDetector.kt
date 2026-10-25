package app.jws.tallybowl

import android.graphics.Bitmap
import android.graphics.Rect
import kotlin.math.max

/** Finds visible, isolated horizontal miss strokes that OCR can omit.
 * Only called for a bounded frame region; no score is used to create a mark. */
internal object DashStrokeDetector {
    fun find(source: Bitmap): List<Rect> {
        val scale = (512.0 / max(source.width, source.height)).coerceAtMost(1.0)
        val image = if (scale == 1.0) source else Bitmap.createScaledBitmap(source,
            max(1, (source.width * scale).toInt()), max(1, (source.height * scale).toInt()), true)
        try {
            val w = image.width
            val h = image.height
            val pixels = IntArray(w * h)
            image.getPixels(pixels, 0, w, 0, 0, w, h)
            val seen = BooleanArray(pixels.size)
            val queue = IntArray(pixels.size)
            fun foreground(index: Int): Boolean {
                val p = pixels[index]
                val r = p shr 16 and 255; val g = p shr 8 and 255; val b = p and 255
                return minOf(r, g, b) >= 165 && maxOf(r, g, b) - minOf(r, g, b) <= 80
            }
            // Keep substantial horizontal runs. This removes thin diagonal
            // artwork/grid connections touching a real dash on the monitor.
            val horizontal = BooleanArray(pixels.size)
            val minimumRun = max(5.0, w * .06).toInt()
            for (y in 0 until h) {
                var x = 0
                while (x < w) {
                    if (!foreground(y * w + x)) { x++; continue }
                    val begin = x
                    while (x < w && foreground(y * w + x)) x++
                    if (x - begin >= minimumRun) for (mark in begin until x) horizontal[y * w + mark] = true
                }
            }
            val found = mutableListOf<Rect>()
            for (seed in pixels.indices) {
                if (seen[seed] || !horizontal[seed]) continue
                var head = 0; var tail = 0
                queue[tail++] = seed; seen[seed] = true
                var left = w; var top = h; var right = 0; var bottom = 0
                while (head < tail) {
                    val position = queue[head++]; val x = position % w; val y = position / w
                    left = minOf(left, x); right = maxOf(right, x); top = minOf(top, y); bottom = maxOf(bottom, y)
                    for (dy in -1..1) for (dx in -1..1) {
                        val nx = x + dx; val ny = y + dy
                        if (nx !in 0 until w || ny !in 0 until h) continue
                        val next = ny * w + nx
                        if (!seen[next] && horizontal[next]) { seen[next] = true; queue[tail++] = next }
                    }
                }
                val width = right - left + 1; val height = bottom - top + 1
                val aspect = width.toDouble() / height
                val middle = (top + bottom) / 2.0 / h
                if (width >= max(5.0, w * .06) && height >= 2 && height <= h * .20 &&
                    aspect in 1.6..8.0 && middle in .25.. .75 && tail >= width * height * .45) {
                    found.add(Rect((left / scale).toInt(), (top / scale).toInt(),
                        ((right + 1) / scale).toInt(), ((bottom + 1) / scale).toInt()))
                }
            }
            val merged = mutableListOf<Rect>()
            for (rect in found.sortedBy { it.top }) {
                val match = merged.firstOrNull { prior ->
                    val overlap = minOf(prior.right, rect.right) - maxOf(prior.left, rect.left)
                    overlap >= minOf(prior.width(), rect.width()) * .8 && rect.top - prior.bottom <= source.height * .08
                }
                if (match == null) merged.add(Rect(rect)) else match.union(rect)
            }
            return merged.sortedByDescending { it.width() * it.height() }.take(3)
        } finally { if (image !== source) image.recycle() }
    }
}
