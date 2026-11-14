package app.jws.tallybowl

import android.content.ContentProvider
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Intent
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.SdkSuppress
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileNotFoundException
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class RecapImageExportTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    private fun png(): File {
        val file = File(context.cacheDir, "tallybowl-exports/${UUID.randomUUID()}/recap.png")
        file.parentFile!!.mkdirs()
        val bitmap = Bitmap.createBitmap(2, 2, Bitmap.Config.ARGB_8888)
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        return file
    }

    @SdkSuppress(minSdkVersion = 29)
    @Test fun exportsPublishedPngsWithoutReplacingPreviousImage() {
        val file = png()
        val saved = mutableListOf<Uri>()
        try {
            repeat(2) { saved.add(RecapImageExport.saveToPictures(context, file.path)) }
            assertNotEquals(saved[0], saved[1])
            for (uri in saved) {
                assertArrayEquals(file.readBytes(), context.contentResolver.openInputStream(uri)!!.use { it.readBytes() })
                context.contentResolver.query(uri, arrayOf(
                    MediaStore.Images.Media.MIME_TYPE, MediaStore.Images.Media.IS_PENDING,
                    MediaStore.Images.Media.RELATIVE_PATH, MediaStore.Images.Media.DISPLAY_NAME,
                ), null, null, null)!!.use { cursor ->
                    assertTrue(cursor.moveToFirst())
                    assertEquals("image/png", cursor.getString(0))
                    assertEquals(0, cursor.getInt(1))
                    assertEquals("Pictures/TallyBowl/", cursor.getString(2))
                    assertTrue(cursor.getString(3).endsWith(".png"))
                }
            }
        } finally {
            saved.forEach { context.contentResolver.delete(it, null, null) }
            file.parentFile!!.deleteRecursively()
        }
    }

    @Test fun olderAndroidUsesSavePickerInsteadOfShareSheet() {
        val intent = RecapImageExport.documentIntent("recap.png")
        assertEquals(Intent.ACTION_CREATE_DOCUMENT, intent.action)
        assertTrue(intent.hasCategory(Intent.CATEGORY_OPENABLE))
        assertEquals("image/png", intent.type)
        assertEquals("recap.png", intent.getStringExtra(Intent.EXTRA_TITLE))
        assertFalse(intent.hasExtra(Intent.EXTRA_STREAM))
    }

    @SdkSuppress(minSdkVersion = 29)
    @Test fun failedWriteOrPublicationRemovesUnfinishedMediaEntry() {
        val file = png()
        try {
            for (failWrite in listOf(true, false)) {
                val provider = FailingMediaProvider(file, failWrite)
                provider.attachInfo(context, ProviderInfo().apply { authority = "test.recap.export" })
                try {
                    RecapImageExport.saveToPictures(context, file.path, ContentResolver.wrap(provider))
                    fail("The failed export reported success")
                } catch (_: java.io.IOException) { }
                assertTrue(provider.inserted)
                assertTrue("Partial image was not removed", provider.deleted)
                assertEquals(!failWrite, provider.triedPublication)
            }
        } finally { file.parentFile!!.deleteRecursively() }
    }

    @SdkSuppress(minSdkVersion = 29)
    @Test fun rejectsPrivateFilesAndInvalidPngBeforeCreatingPublicMedia() {
        val file = png()
        val privateFile = File(context.filesDir, "export-private-test.png").apply { writeBytes(file.readBytes()) }
        val invalid = File(file.parentFile, "invalid.png").apply { writeText("not a png") }
        try {
            for (source in listOf(privateFile, invalid)) {
                val provider = FailingMediaProvider(file, true)
                provider.attachInfo(context, ProviderInfo().apply { authority = "test.recap.export" })
                try {
                    RecapImageExport.saveToPictures(context, source.path, ContentResolver.wrap(provider))
                    fail("Invalid source accepted")
                } catch (_: IllegalArgumentException) { }
                assertFalse(provider.inserted)
            }
        } finally { privateFile.delete(); file.parentFile!!.deleteRecursively() }
    }

    private class FailingMediaProvider(private val source: File, private val failWrite: Boolean) : ContentProvider() {
        var inserted = false
        var deleted = false
        var triedPublication = false
        override fun onCreate() = true
        override fun getType(uri: Uri) = "image/png"
        override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
        override fun insert(uri: Uri, values: ContentValues?): Uri {
            inserted = true
            assertEquals(1, values!!.getAsInteger(MediaStore.Images.Media.IS_PENDING))
            return Uri.parse("content://test.recap.export/1")
        }
        override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
            if (failWrite) throw FileNotFoundException("Simulated storage failure")
            return ParcelFileDescriptor.open(File(source.parentFile, "destination.png"),
                ParcelFileDescriptor.MODE_CREATE or ParcelFileDescriptor.MODE_WRITE_ONLY or ParcelFileDescriptor.MODE_TRUNCATE)
        }
        override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int {
            triedPublication = true
            return 0
        }
        override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
            deleted = true
            return 1
        }
    }
}
