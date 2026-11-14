# Final Flip 7 build 23 — November 13, 2026

The Flip 7 now has **TallyBowl! 0.1.20 (23)**. This supersedes the earlier
[build-22 checkpoint](NOV13_FLIP7_BUILD22.md) on the same day. The final merged
source `b637a73` retains the current Android export disclosure and
main's purchases, children and store privacy sections. The policy date is
November 13; Markdown was generated from the bundled JSON, and the final APK
was inspected to confirm those sections were actually packaged.

Static analysis, all **303 Flutter tests** and the generated-document check
passed again after the merge. The arm64 owner APK matched the phone's existing
development certificate and was installed in place over 22. Its SHA-256 is
`af4c6bcebb1f2c2517b0b6bd0969ec602623f60fb757a3d622b774afd51f6348`. Original installation time remained unchanged, with no
uninstall or data clear. The app launched with a live process and no observed
fatal/Unhandled Flutter error in its scoped startup log. The stopped-app SQLite
database passed integrity checks and was **byte-identical before and after**.
The journal was empty before this update, so this does not establish populated
history migration coverage. No journal records or social actions were created.

Separate protected production-signing builds **1.0.0 (23)** produced a Play AAB
with the upload certificate and Galaxy APK with the app-signing certificate.
Package identity/version, non-debuggable flags, bundle/signature validation,
target API 36, native 16 KiB alignment and APK ZIP alignment passed. These
production packages were neither installed on the phone nor uploaded to stores.
The older build-22 artifacts were retained; current public-package hashes are
in [the store packet](../release/store/package-verification.json).

No TallyBowl build 23 was uploaded to TestFlight; Apple beta remains build 21.
Camera/recognition, image handoff, TalkBack and fold/rotation acceptance were
not repeated on the phone. Source photos and personal screenshots were not
committed. See [launch readiness](LAUNCH-READINESS.md) for remaining store gates.
