package app.jws.tallybowl

import android.content.ClipData
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

/** Single PNG attachment with explicit, read-only grants through the chooser. */
internal object RecapSharing {
    fun intent(context: Context, path: String): Intent {
        val root = File(context.cacheDir, "tallybowl-exports").canonicalFile
        val file = File(path).canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.isFile &&
            file.extension.equals("png", ignoreCase = true) && file.length() in 8..20L * 1024 * 1024)
        val signature = file.inputStream().use { stream -> ByteArray(8).also { require(stream.read(it) == 8) } }
        require(signature.contentEquals(byteArrayOf(137.toByte(), 80, 78, 71, 13, 10, 26, 10)))
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.recap_provider", file)
        return Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newUri(context.contentResolver, "TallyBowl! recap", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }
}

class RecapFileProvider : FileProvider()
