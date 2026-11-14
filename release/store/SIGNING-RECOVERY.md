# Release-key recovery

The owner approved dedicated app-signing and Play-upload keys on November 13,
2026. Encrypted PKCS12 keystores are outside Git under
`~/Library/Application Support/JWS App Releases/Android Signing/`.
Passwords are in this Mac's login Keychain, under the corresponding
`app.jws.APP.android.release.keystore` service and `app-signing` / `upload`
account names. The public certificates and SHA-256 fingerprints in this folder
contain no private signing material.

Before public distribution, copy `android-release-keystores-20261113.zip` to
secure off-device storage and independently retain all four Keychain passwords
in the owner's password manager/recovery process. The archive deliberately
contains no passwords. A copy on this Mac is not an off-device backup.

Use the app-signing identity for Galaxy APKs and import/enroll that same identity
with Play App Signing. Use the separate upload key for Play AAB submissions.
Finish enrollment in the actual Play app record before attempting a store upload.
Existing owner-test apps have a development certificate; never uninstall a
populated test app automatically to bypass the production signature difference.
