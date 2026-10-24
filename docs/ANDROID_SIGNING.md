# Android signing

Owner testing uses `flutter build apk --debug` and the local development key. A release APK/AAB requires an explicit upload/signing key; it never falls back to debug signing or silently produces unsigned output.

## Configure a release

1. Follow the official [Flutter Android signing guide](https://docs.flutter.dev/deployment/android#sign-the-app) and [Android signing documentation](https://developer.android.com/studio/publish/app-signing) to choose and protect the upload/app-signing keys. No production key has been created for this project.
2. Copy `android/key.properties.example` to `android/key.properties`. Set `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. Relative keystore paths resolve from **android/**; an absolute path avoids ambiguity. The real file and `.jks`/`.keystore` files are ignored by Git.
3. For CI or an external protected configuration, set `TALLYBOWL_ANDROID_SIGNING_PROPERTIES` to that properties file's absolute path. It takes precedence over `android/key.properties`; no credentials go into command arguments or the repository.
4. Run `flutter build apk --release` or `flutter build appbundle --release`. Missing/incomplete properties or a missing keystore produce an explicit signing error before Flutter release compilation. The Android signing task validates the actual alias/password/key.

Debug builds and `tool/verify_native.sh` require no release credentials. Existing artifacts from earlier build attempts are not evidence that the current build succeeded; always check its exit status and signature. Changing from the local debug key to a production identity may prevent an in-place install. Preserve a JSON backup; do not automatically uninstall an app containing history to work around a signature mismatch.

Keep production keys/passwords in protected storage with a recovery plan, and configure Play App Signing before a Play release. Build verification with a disposable test key does not establish production signing or Play setup.
