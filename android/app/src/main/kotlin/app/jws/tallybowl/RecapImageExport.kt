package app.jws.tallybowl

import android.app.Activity
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/** Save a recap without invoking ACTION_SEND or asking for library access. */
internal class RecapImageExport(private val activity: Activity) {
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingDocument: Pair<String, MethodChannel.Result>? = null

    fun save(path: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            executor.execute {
                try {
                    saveToPictures(activity, path)
                    activity.runOnUiThread { result.success(PICTURES_FOLDER) }
                } catch (_: Exception) {
                    activity.runOnUiThread { failure(result) }
                }
            }
        } else {
            if (pendingDocument != null) {
                result.error("export_busy", "Finish the open image save first.", null)
                return
            }
            try {
                val file = RecapSharing.image(activity, path)
                pendingDocument = path to result
                activity.startActivityForResult(documentIntent(file.name), SAVE_DOCUMENT)
            } catch (_: Exception) {
                pendingDocument = null
                failure(result)
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_DOCUMENT) return false
        val pending = pendingDocument ?: return true
        pendingDocument = null
        if (resultCode != Activity.RESULT_OK) {
            pending.second.success(null)
            return true
        }
        val uri = data?.data
        if (uri == null || uri.scheme != "content") {
            failure(pending.second)
            return true
        }
        executor.execute {
            try {
                val file = RecapSharing.image(activity, pending.first)
                write(activity.contentResolver, uri, file)
                activity.runOnUiThread { pending.second.success("your selected location") }
            } catch (_: Exception) {
                // ACTION_CREATE_DOCUMENT creates a new document, never an overwrite.
                try { DocumentsContract.deleteDocument(activity.contentResolver, uri) }
                catch (_: Exception) { /* Some providers don't support deletion. */ }
                activity.runOnUiThread { failure(pending.second) }
            }
        }
        return true
    }

    fun close() {
        pendingDocument?.second?.let { failure(it) }
        pendingDocument = null
        executor.shutdown()
    }

    companion object {
        const val PICTURES_FOLDER = "Pictures/TallyBowl"
        private const val SAVE_DOCUMENT = 0x5442

        fun documentIntent(name: String) = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/png"
            putExtra(Intent.EXTRA_TITLE, name)
        }

        @RequiresApi(Build.VERSION_CODES.Q)
        fun saveToPictures(
            context: Context,
            path: String,
            resolver: ContentResolver = context.contentResolver,
        ): Uri {
            val file = RecapSharing.image(context, path)
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/TallyBowl")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            // Insert a new item each time. MediaStore resolves duplicate names;
            // an existing recap is never replaced.
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("Could not create the image.")
            try {
                write(resolver, uri, file)
                val published = resolver.update(uri, ContentValues().apply {
                    put(MediaStore.Images.Media.IS_PENDING, 0)
                }, null, null)
                if (published != 1) throw IOException("Could not publish the image.")
                return uri
            } catch (error: Exception) {
                try { resolver.delete(uri, null, null) }
                catch (_: Exception) { /* Preserve the original failure. */ }
                throw error
            }
        }

        private fun write(resolver: ContentResolver, uri: Uri, file: File) {
            val output = resolver.openOutputStream(uri, "w")
                ?: throw IOException("Could not open the destination.")
            output.use { destination -> file.inputStream().use { it.copyTo(destination) } }
        }

        private fun failure(result: MethodChannel.Result) = result.error(
            "export_image", "Could not save the image. Check available storage and try again.", null,
        )
    }
}
