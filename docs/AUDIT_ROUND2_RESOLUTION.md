# Round-2 audit verification — October 24, 2026

The [supplied round-2 report](audits/2026-10-24-round2-external.md) was checked against its stated baseline, `20f23cd`, the Git history and current implementation. Its recommendations were evaluated independently as review input. This pass addresses all five IDs.

| ID | Verification and disposition |
| --- | --- |
| N-01 | **Confirmed missing release-signing configuration; fixed.** The prior `null` setting could produce unsigned release output. Android now uses an explicit release signing configuration from an ignored properties file, optionally selected through `TALLYBOWL_ANDROID_SIGNING_PROPERTIES`. Missing/incomplete configuration or a missing keystore stops release builds with an actionable error before Flutter release compilation. Debug builds require no release key. See [Android signing](ANDROID_SIGNING.md). No production upload key or Play setup has been created. |
| N-02 | **Timeline clarified from Git.** The original generated build used debug signing. Commit `58d5a50` removed that fallback before the independently reviewed checkout `cdde721`; baseline `20f23cd` also had signing unset. The external report's quoted grep has no source revision, so it cannot establish when that snapshot was observed. The original resolution's “absent in the starting checkout” claim was correct for that checkout but has been rewritten to state the complete sequence and the remaining gap. N-01 now supplies the missing guarded configuration. |
| N-03 | **Tradeoff confirmed; artifact labeling strengthened.** The owner-test Mac copy deliberately disables library validation because its ad hoc frameworks lack a Team ID. Runtime/sandbox protections remain enabled: calling the entire build “not hardened” would be imprecise. Archives now carry `OWNER-TEST-ONLY` in the filename and a signed/sealed `Contents/Resources/TallyBowlBuild.json` warning that they must not be publicly distributed. The manifest records the exact signing/runtime/library-validation state. Team/distribution signing guards and strict production entitlements remain in place. |
| N-04 | **Confirmed avoidable startup dependency; fixed.** `runApp` now runs before a fire-and-forget metadata refresh. The versionless app identity is immediately available; later requests gain installed version/build when metadata arrives. A test holds the native metadata reply pending and verifies the entry point still paints its first frame. Metadata failure remains caught. |
| N-05 | **Physical-device gate confirmed; automated failure coverage expanded.** Existing tests establish persisted pending review and resumption, not camera hardware or actual OS process termination. Added coverage for recognition failure/manual correction, failed draft persistence, and real private-file orphan cleanup across database reopen. Physical kill/reopen during OCR on Android/iPad, camera/gallery, share destinations and assistive technology remain explicit [device checks](DEVICE_TESTING.md). No physical-device result is claimed. |

## Signing history evidence

These commands inspect committed files, independently of the attached reports:

```sh
git show 15a8f8f:android/app/build.gradle.kts
git show 58d5a50 -- android/app/build.gradle.kts
git show cdde721:android/app/build.gradle.kts
git show 20f23cd:android/app/build.gradle.kts
```

`58d5a50` replaces `signingConfigs.getByName("debug")` with `null`. The subsequent audit baseline already contains `null`. This pass replaces that unset configuration with a guarded release identity; it does not reinstate automatic debug signing.

## Verification

Build **0.1.3 (4)** verification:

- `flutter analyze`: no issues.
- `flutter test`: **68 passed**.
- Native build script: Android debug/Lint, universal macOS release and iPad simulator builds passed.
- APK/AAB release commands without credentials: rejected explicitly by `checkTallyBowlReleaseSigning` before Flutter release compilation.
- Release APK with a disposable key: built; APK v2 signature and expected test certificate verified. Test credentials and their installable outputs were removed afterward.
- Debug APK without release credentials: built; package version/code and signature verified.
- Mac owner archive: filename/warning manifest, actual runtime/entitlements, strict code signature and ZIP integrity verified. Editing the embedded policy manifest in a temporary copy caused signature verification to fail. The extracted final archive smoke-launched on this Apple silicon Mac.

Current owner-test package links and advisory lint details are recorded in [development status](DEVELOPMENT.md). Release-signing verification uses a disposable key outside the repository solely as a build fixture. That fixture is not a production identity and its APK is not an owner-install package. Real release credentials, Apple distribution/notarization and map/search hosting remain production gates.

The normal Android debug APK remains the package for the next Galaxy test session. Physical Samsung/iPad installation is outside this audit pass.
