package app.jws.tallybowl

import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.security.MessageDigest

/** Opt-in, emulator-only native worker. Never included in an app APK. */
@RunWith(AndroidJUnit4::class)
class RecognitionLabTest {
    @Test fun nativeWorker() {
        assumeTrue(InstrumentationRegistry.getArguments().getString("recognitionLab") == "true")
        require(Build.HARDWARE in listOf("ranchu", "goldfish")) { "Emulator required" }
        val root = File(InstrumentationRegistry.getInstrumentation().targetContext.cacheDir, "recognition-lab")
        root.mkdirs()
        val requestFile = File(root, "request.json")
        val ready = File(root, "ready")
        requestFile.delete()
        ready.writeText("ready")
        var lastId = ""
        val deadline = System.nanoTime() + 30L * 60 * 1_000_000_000
        try {
            while (System.nanoTime() < deadline) {
                if (!requestFile.exists()) { Thread.sleep(40); continue }
                val request = JSONObject(requestFile.readText())
                val id = request.getString("id")
                if (id == lastId) { Thread.sleep(40); continue }
                lastId = id
                if (request.optBoolean("stop")) break
                val response = JSONObject().put("id", id)
                try {
                    val hash = request.getString("sha256")
                    require(hash.matches(Regex("[a-f0-9]{64}")))
                    val bytes = File(root, "$hash.photo").readBytes()
                    require(bytes.size <= 40 * 1024 * 1024)
                    val actual = MessageDigest.getInstance("SHA-256").digest(bytes)
                        .joinToString("") { "%02x".format(it) }
                    require(actual == hash) { "Photo hash mismatch" }
                    val args = request.getJSONObject("args")
                    val regions = args.optJSONArray("regions")?.let { array ->
                        (0 until array.length()).map { i ->
                            val item = array.getJSONObject(i)
                            listOf("x", "y", "width", "height").associateWith { item.getDouble(it) as Number }
                        }
                    }
                    val output = ScoreTextRecognizer.recognize(bytes, regions,
                        args.optDouble("aspect", 1.0), args.optBoolean("context", false))
                    response.put("output", org.json.JSONArray(output))
                } catch (_: Exception) { response.put("error", "Native recognition failed") }
                val temporary = File(root, "response.tmp")
                temporary.writeText(response.toString())
                check(temporary.renameTo(File(root, "response.json")))
            }
        } finally { ready.delete() }
    }
}
