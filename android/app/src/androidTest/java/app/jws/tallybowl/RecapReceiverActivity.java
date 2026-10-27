package app.jws.tallybowl;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Process;
import android.os.ResultReceiver;
import android.provider.OpenableColumns;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Arrays;

/** Separate test-APK UID; deliberately uses only framework classes. */
@SuppressWarnings("deprecation")
public final class RecapReceiverActivity extends Activity {
    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Bundle result = new Bundle();
        try {
            Uri uri = getIntent().getClipData().getItemAt(0).getUri();
            if (!uri.equals(getIntent().getParcelableExtra(Intent.EXTRA_STREAM))) throw new IllegalStateException("Stream and clip disagree");
            result.putInt("uid", Process.myUid());
            result.putString("mime", getContentResolver().getType(uri));
            try (Cursor cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
                if (!cursor.moveToFirst()) throw new IllegalStateException("No filename");
                result.putString("name", cursor.getString(0));
            }
            byte[] signature = new byte[8];
            try (InputStream stream = getContentResolver().openInputStream(uri)) {
                result.putBoolean("png", stream.read(signature) == 8 && Arrays.equals(signature, new byte[]{(byte)137,80,78,71,13,10,26,10}));
            }
            try (OutputStream ignored = getContentResolver().openOutputStream(uri, "wa")) {
                result.putBoolean("writeDenied", false);
            } catch (SecurityException expected) { result.putBoolean("writeDenied", true); }
        } catch (Exception error) { result.putString("error", error.toString()); }
        ResultReceiver callback = getIntent().getParcelableExtra("callback");
        callback.send(0, result);
        finish();
    }
}
