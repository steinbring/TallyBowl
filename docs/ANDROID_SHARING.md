# Android recap image sharing

The reported symptom was Google Chat opening without an attachment while Messages accepted the same recap. `share_plus` 13.3.1 supplies `EXTRA_STREAM` and a read flag, but does not explicitly attach `ClipData`; its cache also replaces previous attachments on each new share. That leaves recipients relying on different URI propagation/read timing paths.

PNG recaps now use the small `app.jws.tallybowl/share` adapter. `RecapSharing` creates a standard `ACTION_SEND`, `image/png`, matching `EXTRA_STREAM` and `ClipData` content URIs, and `FLAG_GRANT_READ_URI_PERMISSION`. The normal Android chooser propagates the clip and read grant. No write/prefix/persistable grant, recipient enumeration, account posting, or text containing hidden recap metadata is added. The non-exported provider exposes only `cache/tallybowl-exports/`; the adapter validates canonical containment, PNG signature/extension and a 20 MiB size limit. Each export has its own directory, so a later share does not destroy an earlier attachment. Existing one-day opportunistic cleanup remains.

Apple image sharing retains `share_plus`, PNG MIME, filename and iPad popover anchor. JSON/CSV exports keep their existing platform transport. A successful share return means the chooser was opened, not that a message was sent.

## Direct image export — November 3, 2026

Android's Export image previously called `shareImage`, producing the same chooser as Share image. It now calls the distinct `saveImage` method on the existing private channel. `RecapImageExport` writes a new PNG to MediaStore's **Pictures/TallyBowl** collection on Android 10+, with no photo-library or storage permission. It writes on a worker, keeps the media entry pending until the stream closes, and removes the unfinished entry on write/publication failure. Repeated exports create new entries rather than overwriting earlier images. The UI confirms success only after publication; cancellation is silent and failures allow retry with a plain-language message.

Android 9 and earlier use `ACTION_CREATE_DOCUMENT` to select a save location without broad storage permissions. This is a save picker, not an `ACTION_SEND` chooser. Its pending callback is cleared on activity destruction. Both save paths reuse the same canonical-path/PNG/size validation as sharing. The Dart staging helper rejects path separators and control characters, cleans up failed writes, and treats unavailable old exports as best-effort cleanup. The recap renderer disposes its image even if encoding throws, and labels the active operation correctly.

The bundled guide and policy describe the saved location and the device's independent gallery/backup behavior. Sources: [MediaStore and app-owned media](https://developer.android.com/training/data-storage/shared/media), [system document creation](https://developer.android.com/training/data-storage/shared/documents-files).

References: [Android ACTION_SEND and ClipData](https://developer.android.com/reference/android/content/Intent#ACTION_SEND), [URI read grants](https://developer.android.com/reference/android/content/Intent#FLAG_GRANT_READ_URI_PERMISSION), [Google Chat supported images](https://support.google.com/chat/answer/7651457?co=GENIE.Platform%3DAndroid&hl=en).

## Verification

`test/recap_export_privacy_test.dart` exercises the real recap renderer and Dart transport for Android and Apple platform variants, including a 1080-pixel PNG, neutral filename when Date is hidden, and no caption carrying private fields.

`RecapSharingTest` checks the production intent/chooser and launches a framework-only receiving activity under a **different test-APK UID**. That receiver must open the PNG, read MIME/display name and be denied write access. The provider must reject a private journal path. This tests actual Android permissions, not just matching extra strings. The receiving activity exists only in `src/androidTest`; it is excluded from shipped builds.

`RecapImageExportTest` saves and reads real MediaStore PNGs, checks published MIME/location/state and distinct URIs for repeated exports, rejects private paths and invalid PNGs before insertion, and injects write/publication failures to verify rollback. It also checks the older-Android save intent. Dart tests exercise the rendered Export image action, its separate native method and saved confirmation, cancellation/failure/retry, neutral filenames and the existing three-platform sharing path.

Run only against an isolated emulator, never a populated owner installation:

```sh
cd android
ANDROID_SERIAL=emulator-5554 ./gradlew :app:connectedDebugAndroidTest -Ptarget=lib/main.dart
```

The debug runner versions are aligned with AGP's consistent runtime resolution and Flutter's `integration_test` plugin. They do not enter the release dependency configuration.

The emulator checks establish the file handoff contract. A physical Google Chat composer check remains necessary because installed Chat versions and account/work-profile policies can affect recipient behavior. Choose Chat and verify the image preview; cancel without sending during diagnostics. Also check Messages and AeroSloth. An OS chooser opening alone is not evidence that the recipient received an image.
