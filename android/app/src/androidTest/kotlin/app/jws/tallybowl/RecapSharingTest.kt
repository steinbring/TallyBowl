package app.jws.tallybowl

import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.ResultReceiver
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class RecapSharingTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext

    private fun png(): File {
        val file = File(context.cacheDir, "tallybowl-exports/${UUID.randomUUID()}/tallybowl-recap.png")
        file.parentFile!!.mkdirs()
        val bitmap = Bitmap.createBitmap(2, 2, Bitmap.Config.ARGB_8888)
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        return file
    }

    @Test fun singleAttachmentHasMatchingStreamClipAndReadOnlyGrants() {
        val file = png()
        try {
            val send = RecapSharing.intent(context, file.path)
            val uri = send.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)!!
            assertEquals(Intent.ACTION_SEND, send.action)
            assertEquals("image/png", send.type)
            assertEquals(uri, send.clipData!!.getItemAt(0).uri)
            assertEquals(Intent.FLAG_GRANT_READ_URI_PERMISSION, send.flags)
            assertFalse(send.hasExtra(Intent.EXTRA_TEXT))
            val chooser = Intent.createChooser(send, "Share bowling recap")
            assertEquals(uri, chooser.clipData!!.getItemAt(0).uri)
            assertEquals(Intent.FLAG_GRANT_READ_URI_PERMISSION, chooser.flags and 3)
            // A later share must not invalidate a receiver's delayed first read.
            val second = png()
            try { RecapSharing.intent(context, second.path); assertTrue(file.exists()) }
            finally { second.parentFile!!.deleteRecursively() }
        } finally { file.parentFile!!.deleteRecursively() }
    }

    @Test fun differentUidCanReadPngButCannotWrite() {
        val file = png()
        try {
            val latch = CountDownLatch(1)
            var response: Bundle? = null
            val callback = object : ResultReceiver(Handler(Looper.getMainLooper())) {
                override fun onReceiveResult(code: Int, data: Bundle?) { response = data; latch.countDown() }
            }
            val send = RecapSharing.intent(context, file.path).apply {
                setClassName(instrumentation.context.packageName, RecapReceiverActivity::class.java.name)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("callback", callback)
            }
            context.startActivity(send)
            assertTrue("Receiver did not respond", latch.await(10, TimeUnit.SECONDS))
            assertNull(response!!.getString("error"))
            assertNotEquals(Process.myUid(), response!!.getInt("uid"))
            assertEquals("image/png", response!!.getString("mime"))
            assertEquals("tallybowl-recap.png", response!!.getString("name"))
            assertTrue(response!!.getBoolean("png"))
            assertTrue(response!!.getBoolean("writeDenied"))
        } finally { file.parentFile!!.deleteRecursively() }
    }

    @Test fun privateJournalAndNonImagesCannotBeShared() {
        val privateFile = File(context.filesDir, "share-test-private.json")
        privateFile.writeText("{}");
        try {
            try { RecapSharing.intent(context, privateFile.path); fail("Private path accepted") }
            catch (_: IllegalArgumentException) { }
        } finally { privateFile.delete() }
    }
}

