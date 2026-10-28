# TestFlight readiness and release runbook

## 0.1.11 (12): expanded photo corpus

Recognition source **d7236e6** adds slanted ruling calibration, a bounded retry for missing text grids, same-position native corroboration and physical delivery ordering. **179 tests pass; static analysis is clean.** The twelve added originals recover every delivery in 9/10 complete Apple examples and 8/10 Android examples. Both incomplete-game photos require review; no incorrect automatic original-image result was observed. See [the exact per-photo results and limitations](PHOTO_CORPUS_RESULTS.md).

Build-12 iPad and native Mac packages, signing checks and TestFlight assignments are being prepared. Prior working builds remain available. Release evidence is retained under ignored `build/testflight/build-12/`; private photo diagnostics are in `build/corpus12/`. No new physical owner installation is claimed.

## 0.1.10 (11): league-board recognition

Recognition source **4e2d258** fixes right-aligned frame headers, sloping multi-bowler rows, short rounded misses, duplicate native text blocks, and separate scratch/handicap totals. All four October 27 original league photos produce the exact observed frames and scratch totals (104 and 80) through actual Apple Vision and bundled Android ML Kit. Anonymized two-row fixtures preserve native observations from both engines; import/resume editor tests cover the new games. **155 Flutter tests pass; static analysis is clean.** See [frame recognition](FRAME_RECOGNITION.md) for validation rules and limits.

**Both iPad and native Mac 0.1.10 (11) are Testing in Owner testing.** Both uploads processed successfully, export compliance is cleared using standard encryption and the approved France exclusion, testing notes are saved, and both builds are assigned to External testing with automatic notification enabled. Both show **Waiting for Review** in the external group; external availability awaits Apple approval. Prior working builds remain available.

| Evidence | Result |
| --- | --- |
| iPad ASC build | `91eddf09-b8d7-47ce-bae0-5a650ba9b547`, owner Testing; external Waiting for Review |
| Native Mac ASC build | `8e85fc2a-7931-4787-9318-6753d20c66d0`, owner Testing; external Waiting for Review |
| Apple artifacts | Source `9cbf0ce`, normal `lib/main.dart`; archive/content and exported distribution signing/profile checks pass; Mac installer chain verified |
| Android artifact | `build/releases/TallyBowl-0.1.10-android-debug.apk`, same owner development signer; normal build installed/launched on isolated emulator only |
| Release evidence | Private logs, preflight reports, release record and SHA-256 hashes under ignored `build/testflight/build-11/` |

 Logs and release evidence are kept under ignored `build/testflight/build-11/` and `build/league-fix/`; original photos and personal OCR logs are excluded from Git and app packages. No new physical device installation is claimed for build 11.

The build-10 record below is historical. Both build-10 platforms were observed as Testing for external testers on October 27 before submitting build 11.

## 0.1.9 (10): October 27, 2026

Candidate source includes `22a3d2d` (local frame-glyph recovery), `cc3e2fd` (session deletion) and `9dcfc82` (Android PNG handoff). **137 Dart/widget tests pass**, static analysis has no issues, and **three Android instrumentation tests pass**, including a receiving app under a separate UID reading the image while being denied write access. Original 89- and 109-pin photos produce the exact ten observed frames through local Vision and the Android pipeline; anonymized real-photo fixtures exercise import/resume through filled editor inputs and saving. See [recognition](FRAME_RECOGNITION.md) and [sharing](ANDROID_SHARING.md).

**Both iPad and native Mac 0.1.9 (10) are available through the internal Owner testing group.** Both uploads processed successfully, export compliance is cleared using the previously approved standard-encryption answer and France exclusion, and What to Test is saved. The group's Builds tab shows **Testing** for both new platforms. The prior working builds remain available.

External **External testing** was created with two email testers and no public link. Both platform builds were submitted to Beta App Review on October 27 and show **Waiting for Review**. Both requested addresses are present; their current status is **No Builds Available** until approval. Automatic tester notification is enabled for approval. External installation depends on Apple's approval; submitting a build is not approval. The tester addresses are maintained privately in App Store Connect rather than this repository.

| Evidence | Result |
| --- | --- |
| iPad App Store Connect build | `730e456b-9ccf-4bdb-b2df-55b77d2dd4e5`, 0.1.9 (10), internal Testing; external Waiting for Review |
| Native Mac App Store Connect build | `86479074-582c-440f-93f3-950830570ef1`, 0.1.9 (10), internal Testing; external Waiting for Review |
| External group | `6e6419e3-7a50-4c52-ad98-6303af5a58e1`, both new builds, email-only invitations |
| Apple artifacts | iPad release IPA and universal native Mac App Store package, normal `lib/main.dart`, source `7c4a815`; both archive/content and exported distribution-signature/profile checks pass |
| Android artifact | `build/releases/TallyBowl-0.1.9-android-debug.apk`, source `e3793ca`, normal `lib/main.dart`, same owner development signer and permissions as the prior APK; private probes/test receiver excluded |
| Android native verification | Three instrumentation tests passed; Lint has zero errors and ten advisory warnings. The debug-only test helper's task-reordering permission is explicitly excluded |
| Release evidence | Logs, signature reports and artifact hashes in ignored `build/testflight/build-10/` |

Physical Google Chat composer verification is pending; the owner chose emulator checks for this pass. Neither the chooser nor the separate test receiver proves that a specific installed Chat version accepted an attachment. The planned public privacy URL still fails DNS; the current policy is bundled offline and available in this repository. Public policy hosting and physical Apple/Android workflow acceptance remain open. No broad recognition-accuracy or physical TestFlight installation claim is made.

To install the Apple update, accept the existing owner invitation and choose **0.1.9 (10)** in TestFlight on each device. Export a journal backup first. Android is distributed separately using the APK above. At the owner's request, the Samsung was updated in place from 0.1.7 (8) to this exact APK and launched; the complete journal remained unchanged. See [device evidence](DEVICE_TESTING.md). No app was uninstalled or had its data cleared.

## Historical 0.1.8 preparation and signing runbook

The sections below preserve the October 25 release record. Their candidate numbers, tester counts and remaining-work decisions describe that earlier release; the section above is the current status.


Assessed October 25, 2026. Current candidate **0.1.8 (9)**, bundle ID **app.jws.tallybowl**, existing Apple team **R9DBX89RA5**. Owner build **0.1.7 (8)** is installed on the Mac, iPad, and Samsung. Build **0.1.7 (8)** uploaded successfully for both platforms on October 25, 2026; iPad processing succeeded, but Apple rejected the Mac package for nested resource-bundle certificate mismatches (ITMS-90284). A successful upload and deep signature verification alone are insufficient. Build **0.1.8 (9)** includes verified round-three recognition fixes and a corrected Mac signing configuration; both platforms have now processed successfully, cleared export compliance and been assigned to the private owner group.

## Readiness decision

**Private owner TestFlight is configured for iPad and native Mac 0.1.8 (9).** Account setup, signing, upload, Apple processing, export compliance, testing notes and owner-group assignment are complete. Accepting the invitation and installing through TestFlight remain the owner’s next steps; no physical TestFlight installation is claimed. The first internal TestFlight installation can finish real Apple hardware acceptance while privacy-policy hosting is finalized. Public developer/support identity is Joe Steinbring, with verified contact at https://jws.dev/contact. Publish the privacy policy before onboarding external testers, and expand only after the critical device flows and Apple's beta review requirements pass.

| Gate | Evidence / remaining work |
| --- | --- |
| Scope and help | README, current roadmap, architecture, user guide, privacy policy, device checklist and reviewer instructions provided; user guide/privacy are bundled offline in Settings |
| Pure Dart/widget behavior | Candidate results recorded below; scoring, drafts, recognition parsing, migrations/backups, share export and accessibility regressions included |
| Apple packaging | App-owned required-reason manifests in both Resources phases, custom launch art and Mac Sports category; inspect actual archives, not just source files |
| Release protection | Mac sandbox/hardened runtime retained; owner ad hoc library exception is excluded from TestFlight packaging |
| Public developer/support | **Complete:** owner-approved Joe Steinbring and https://jws.dev/contact; verified HTTP 200 and the actual contact page on October 25, 2026. Bundled policy/help and beta metadata use this contact |
| Privacy website | **Open:** planned home and `/privacy` on `tallybowl.jws.app` fail DNS lookup on this Mac. Publish `PRIVACY_POLICY.md`; a separate TallyBowl `/support` page is no longer required for the selected public contact |
| Apple account and app records | **Verified:** explicit bundle registration and App Store Connect app **6826931962**, with iOS and native macOS platforms, team **R9DBX89RA5**. Xcode automatic distribution signing/export succeeded |
| Store privacy/export answers | **Both build-9 export questionnaires cleared:** standard algorithms in addition to OS encryption; no France distribution, as approved by the owner. External-listing provider/privacy review remains open |
| Upload and Apple validation | **Complete for internal availability:** iPad and Mac **0.1.8 (9)** processed successfully, cleared Missing Compliance, have saved What to Test notes, and are assigned to **Owner testing** (one owner). Mac build 8 failed ITMS-90284 and is superseded. Actual TestFlight installation/acceptance remains open |
| Physical Apple workflows | **Open for this candidate:** iPad camera/import, denied permission recovery, offline recognition, correct populated frames, popover sharing to real recipients, VoiceOver, backup/restore, upgrade/migration and interruption; repeat critical flows on native Mac |
| Recognition breadth | One real monitor regression plus synthetic fixtures; expand the permissioned corpus during internal beta. No broad accuracy claim |
| External beta | After internal acceptance: beta metadata/contact and Apple's review, invited group, support process and service-capacity/privacy decision. No external testers have been invited |

## Current candidate verification: 0.1.8 (9)

Source revision **9558674**, including recognition fixes **713d9cc**. Verified October 25, 2026:

| Check | Result |
| --- | --- |
| Static analysis and Dart/widget suite | **No issues; 117 tests passed** |
| Native stroke contract | **10 raster cases passed on Mac and the same 10 on isolated Android**, through the production Vision/ML Kit channels |
| Original private monitor regression | Updated Apple helper plus Dart orchestration and updated Android ML Kit both produced all ten exact frames/checkpoints, total **90** and automatic row selection |
| iPad | Release archive and App Store IPA export passed, normal `lib/main.dart`, iPad-only, minimum iPadOS 15 |
| Native Mac | Release build/archive and App Store package export passed, normal entry point, universal Intel/Apple silicon, minimum macOS 12, strict sandbox/hardened runtime |
| Signed export preflight | Both passed; app certificate belongs to the explicit App Store profile, every signed nested bundle/framework matches it, no debugger/JIT/library exception. Mac has five unsigned resource-only bundles sealed by the app signature. Installer certificate chain verified |
| Archive/content preflight | Both signed archives passed; privacy manifests, documents, device family, category, symbols and absence of owner-only package markers checked |
| Android | Normal debug APK rebuilt; valid signer matches prior owner APK. Native Lint: **0 errors, 10 advisory warnings** |
| Apple processing | Both uploads **Complete**, export compliance cleared, both build details show **Owner testing / Internal / 1 tester**, with testing notes saved; the group’s Builds tab shows **Testing** for each platform |
| Hardware acceptance | Existing populated owner apps remain 0.1.7 (8); private test harnesses used isolated targets. Actual TestFlight upgrade, camera, recipient sharing, accessibility and backup acceptance remain owner testing tasks |

App Store Connect build IDs are iPad **a071db5a-46d8-4d4c-b299-262673c5a4a2** and Mac **7254e810-ccfc-45b6-a4b5-28c28803dd9e**. The owner group’s Builds tab shows both platforms as **Testing**, expiring in 90 days. No external beta review has been requested. Accept the existing invitation using the owner’s Apple account, open TestFlight on each Apple device, and select **0.1.8 (9)**. Export a journal backup first and retain it outside the app. App Store distribution drafts have not been submitted or published.

Private build/upload logs, signed-export checks, hashes and release record are under ignored `build/testflight/build-9/`; regression logs are `build/audit3-*`. The normal Android owner APK is `build/releases/TallyBowl-0.1.8-android-debug.apk`. Android does not distribute through TestFlight. The report and accepted performance tradeoff are in [round-three dispositions](AUDIT_ROUND3_RESOLUTION.md).

## Earlier readiness evidence: 0.1.7 (8)

The following results describe the earlier preparation on October 25, 2026:

| Check | Result |
| --- | --- |
| Static analysis | No issues in `lib` and `test` |
| Unit/widget suite | **105 passed**, including real bundled help/privacy navigation, installed build display, narrow 200% text and document heading semantics |
| iPad Release archive | `flutter build ipa --release --no-codesign --target lib/main.dart` passed; version/build/ID/minimum iPadOS 15.0 validated; placeholder launch warning resolved; no signed IPA exported during the initial rehearsal; a later signed export/upload is recorded below |
| Native Mac Release build/archive | Both passed; universal arm64/x86_64; minimum macOS 12.0; Sports category present. Signing was disabled for the archive rehearsal; linker ad hoc metadata has no distribution Team ID |
| Archive contents | Both contain the app-owned privacy manifest matching source, identical bundled help/policy, and dSYMs; no sealed owner-only package marker |
| Local preflight | Source and both archive checks passed. JSON: `build/readiness/local-preflight.json` |
| Android compatibility | Normal-entry-point debug APK compiled; native Lint passed with 0 errors and 10 advisory warnings (existing dependency/SDK, launcher shape and Kotlin-style notices) |
| Public URL check | Support contact **passed** at `https://jws.dev/contact`; planned `https://tallybowl.jws.app/privacy` **still fails DNS**. JSON: `build/readiness/public-url-check.json` |
| Final public contact update | Joe Steinbring and the approved support link are in both bundled documents and generated Markdown; the two document/navigation/accessibility checks were rerun successfully after this content update |
| Physical distribution install / Apple validation | **Device acceptance pending**; account/export/upload succeeded subsequently, but current-candidate camera/share/VoiceOver acceptance is not claimed |
| Local owner installations | 0.1.7 (8) installed/launched on Mac mini and physical iPad; all journal records/profile/draft unchanged. Existing Development signing was used for iPad and the labeled owner-only package for Mac. See `DEVICE_TESTING.md`; this is separate from TestFlight acceptance |

Build logs are `build/testflight-ios-archive.log`, `build/testflight-macos-build.log`, `build/testflight-macos-archive.log`, `build/testflight-tests.log` and `build/testflight-analyze.log`. Keep failures visible until resolved; the most recent successful command and its exact version matter more than the presence of an old file. These outputs are ignored by Git. Initial readiness work was on `codex/testflight-readiness`; account/signing/upload setup is on `codex/testflight-setup`. No populated installation was replaced during upload setup.

## App Store Connect setup and signed upload record

On October 25, 2026, registered explicit App ID `app.jws.tallybowl` and created [TallyBowl! in App Store Connect](https://appstoreconnect.apple.com/apps/6826931962/distribution), ID **6826931962**, SKU `app.jws.tallybowl`, English (U.S.), with iOS and native macOS platforms. The generated App Store version 1.0 drafts are not a store submission; the current TestFlight binary version is **0.1.8 (9)**.

Created internal **Owner testing**, with only the account owner and **manual distribution**. No external group or public testing link was created. Feedback email and private reviewer contact/instructions were saved with owner approval; private contact stays in App Store Connect, not this repository. The hosted policy and external-beta gates remain open. The first iPad build 0.1.7 (8) generated the owner invitation. Both new 0.1.8 (9) builds are now assigned to the same group, each with the saved testing checklist and known limitations. The group’s Builds tab shows **Testing** for both platforms, and its sole owner tester is **Invited**. The owner still needs to accept/install; this is separate from the external-review status.

Xcode 27 exported an Apple Distribution-signed iPad IPA and an App Store installer-signed Mac package, then uploaded both successfully. Strict/deep app signature checks passed against the Apple trust store. Archive preflight was also rerun on both signed archives and passed. Both apps have the correct team/bundle identifiers and no debugging/JIT/library-validation exception; Mac sandbox/camera/selected-file/network-client entitlements remain intact. iPad has `beta-reports-active=true` and `get-task-allow=false`. Initial build-8 artifacts and rejection evidence are under ignored `build/testflight/setup/`; build-9 evidence is under `build/testflight/build-9/`; do not commit profiles, credentials, populated backups or distribution logs.

The following commands produce signed archives/exports (normal `lib/main.dart`; they require an authorized Xcode account). The corrected Mac command uses **app-target-scoped** overrides. Do not pass `CODE_SIGN_IDENTITY` or `DEVELOPMENT_TEAM` globally: that signed Swift Package privacy resource bundles with the development certificate, which Xcode did not replace during build 8 export:

```sh
flutter build ipa --release --target lib/main.dart \
  --export-options-plist release/apple/ExportOptions.plist
flutter build macos --release --target lib/main.dart
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/testflight/build-9/TallyBowl-macOS.xcarchive \
  TALLYBOWL_APP_SIGNING_TEAM=R9DBX89RA5 \
  TALLYBOWL_APP_SIGNING_IDENTITY='Apple Development' \
  FLUTTER_TARGET=lib/main.dart -allowProvisioningUpdates archive
xcodebuild -exportArchive \
  -archivePath build/testflight/build-9/TallyBowl-macOS.xcarchive \
  -exportPath build/testflight/build-9/macos-export \
  -exportOptionsPlist release/apple/ExportOptions.plist \
  -allowProvisioningUpdates
```

After export, expand the Mac package with `pkgutil --expand-full` (or unzip the IPA), then run `python3 tool/apple_distribution_preflight.py <exported.app> --output <ignored-report.json>`. This checks App Store profile/team/identifier, root protections and the distribution certificate on every signed nested bundle/framework. Resource-only bundles can be unsigned and remain sealed by the app signature. The check reproduced exactly the five ITMS-90284 mismatches in the rejected Mac export, passed the known-good iPad export, and passed both new build-9 exports. Keep `tool/testflight_preflight.py --archive ...` for source/archive contents as a separate check.

The committed options export locally. For build-9 uploads, an ignored copy at `build/testflight/build-9/UploadOptions.plist` set `destination=upload`, leaving the committed template unchanged. Each platform used `xcodebuild -exportArchive` with its signed archive, separate export directory, upload options and `-allowProvisioningUpdates`. Never repeat a successful upload to check processing; inspect the existing build in App Store Connect instead. The build-8 iPad archive/IPA were preserved under ignored `build/testflight/setup/` before rebuilding build 9. Flutter replaces `build/ios/archive/Runner.xcarchive`; label retained artifacts by version/build.

## Upload preparation and external-beta checklist

1. Export a JSON backup from each populated owner installation and save it outside TallyBowl. Preserve the existing app/container. A simulator app or an unsigned archive cannot be installed on a real iPad; deleting a populated app to bypass signing is not an update strategy.
2. Confirm membership, team **R9DBX89RA5**, account permissions/agreements and the App Store Connect record. Register/select bundle `app.jws.tallybowl` and add the native macOS platform to the same app record if using one cross-platform listing. Keep native Mac and iPad builds separate; don't substitute “Designed for iPad” on Apple silicon for testing the native Mac app. Review the iPad-on-Mac availability choice before broad distribution.
3. Public contact is finalized as **Joe Steinbring**, https://jws.dev/contact. Before onboarding external testers, publish the HTTPS privacy policy from `PRIVACY_POLICY.md` at `https://tallybowl.jws.app/privacy`. Keep the bundled policy/help and generated Markdown in sync with `python3 tool/render_documents.py`. Verify actual policy/contact content without login. Set TestFlight's separate Feedback Email and private reviewer contact fields in App Store Connect; a website URL does not fill an email field. Feedback email and the private reviewer contact/instructions are now saved in App Store Connect with owner approval. Hosting is not yet configured. An owner-only internal install can proceed while the hosted policy is completed.
4. Review app privacy for the actual providers/platform. No journal/photos go to a developer server or cloud AI. OSM/Photon receive IP and request/query metadata and may retain logs. Android has Google ML Kit SDK diagnostics; it is absent from the Apple app. Do not automatically select “Data Not Collected” solely because OCR is local. Complete Apple's definitions/third-party review before external review or a public listing; the required-reason manifest is a different declaration.
5. Complete Apple's export questionnaire. Technical inventory: standard HTTPS through Dart/Flutter networking and SHA-256 photo filenames; no proprietary cipher, VPN, encrypted messaging or app-level journal encryption. Dart TLS is not necessarily OS URLSession. `ITSAppUsesNonExemptEncryption` is deliberately unset pending the final determination. For both build-9 platforms, the questionnaire was answered **standard algorithms in addition to OS encryption**, then **no France distribution**, as approved by the owner. Apple cleared Missing Compliance. Recheck this answer before including France or changing libraries. Encode a Boolean/compliance code in future binaries only if the determination supports it. An unset key is answered in App Store Connect; it is not an assertion of exemption.
6. Choose the next unused build number for each platform. Build **9** has now been uploaded successfully for iOS and macOS. Use **10 or later** for another changed binary; inspect App Store Connect history first. Increment `pubspec.yaml` and regenerate/recheck archives. Never overwrite evidence with a different build number silently.

## Local checks and unsigned archive rehearsal

```sh
flutter pub get
flutter analyze
flutter test
python3 tool/render_documents.py --check
python3 tool/testflight_preflight.py
./tool/verify_native.sh
```

The native script type-checks bridges and runs Android Lint but does not archive/sign for TestFlight. Produce unsigned rehearsal archives without accessing or changing signing assets:

```sh
flutter build ipa --release --no-codesign --target lib/main.dart
flutter build macos --release --target lib/main.dart
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/testflight/TallyBowl-macOS-UNSIGNED-NOT-FOR-UPLOAD.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive
python3 tool/testflight_preflight.py \
  --archive build/ios/archive/Runner.xcarchive \
  --archive build/testflight/TallyBowl-macOS-UNSIGNED-NOT-FOR-UPLOAD.xcarchive \
  --output build/readiness/local-preflight.json
```

These are compilation/packaging rehearsals only, **not uploadable distribution products**. Archive checks cover ID/version/device family, app privacy-manifest presence, dSYMs, Mac universal binary/category and absence of the sealed owner-only marker. They record signing diagnostics without calling a missing/ad hoc signature production ready. `--check-urls` optionally requires the public URLs to respond; it cannot judge policy completeness. Account/review/device gates remain manual.

## Create and validate signed distribution archives

Prefer Xcode Organizer for the first distribution because it can resolve managed signing and explain account/profile errors. Use `open ios/Runner.xcworkspace` or `open macos/Runner.xcworkspace`. Select **Runner**, **Release**, normal `lib/main.dart`, the correct team, and an “Any iOS Device”/generic Mac destination; archive each platform separately. Enable automatic signing for Runner, preserving all release entitlements. For native Mac, set the team and appropriate App Store distribution signing in Xcode; the local project's ad hoc default is not distribution signing. Do not call `tool/package_macos_local.sh` or add its library-validation exception.

In Organizer, inspect the app ID, version/build, capabilities and generated Privacy Report. Resolve all validation errors, including third-party manifest/signature requirements. Choose App Store Connect distribution and use its validation step. Retain the `.xcarchive`, dSYMs, export logs and source commit in a private release record. The template `release/apple/ExportOptions.plist` uses current Xcode's `app-store-connect` method, automatic team signing, symbols, fixed build number and **destination=export**; it does not upload on its own. With a properly signed archive and authorized account/profile setup, a local CLI export can use:

```sh
xcodebuild -exportArchive -archivePath <signed-archive.xcarchive> \
  -exportPath build/testflight/export \
  -exportOptionsPlist release/apple/ExportOptions.plist
```

Some teams use cloud-managed signing via Organizer rather than local distribution certificates. Missing local certificates alone does not prove the account lacks signing access. Do not create/revoke certificates, turn off production protections, or put account credentials into Git to bypass a signing failure. A direct-download Mac Developer ID/notarized package is a different distribution path; the owner ZIP is neither that nor a TestFlight package.

Uploading, changing App Store Connect state and inviting testers are separate explicit actions. After authorized upload, confirm Apple processing has completed, fill export information, and verify the processed platform/version/build before selecting it for testing. Use the [metadata](TESTFLIGHT_METADATA.md) for description/What to Test/reviewer instructions; no login is needed.

## Internal acceptance and external expansion

Install the processed build through TestFlight on the real iPad and native Mac. Record its installed version from Settings. Use a fresh isolated journal first and separately verify a backed-up in-place owner upgrade. Complete [DEVICE_TESTING.md](DEVICE_TESTING.md), with particular attention to permissions, a real final scoreboard, offline recognition, every delivery/total, an interrupted draft, native PNG handoff/popover, recovery after restore, and accessibility. The iPad became available after the initial readiness assessment: development-signed 0.1.7 (8) is now installed and running with unchanged data. This owner-install check does not replace distribution-signed TestFlight or full device-flow acceptance.

AeroSloth's Android image-receive path previously passed a real emulator handoff; Apple share-extension availability still needs testing. “Share sheet opened” alone does not prove the destination received a valid image. Use a recipient composer/local attachment without publishing unless the owner intentionally sends it.

Start with a small invited group. OSM tiles and Photon demo have usage rules and no SLA; reasonable internal testing does not automatically require paid hosting. Before expansion, review usage/capacity, log retention and privacy labels, and choose a compliant provider/self-hosting plan if needed. Keep visible attribution and manual offline fallback. Track crash/data-loss/recognition/share defects and collect permissioned photos with expected deliveries. Set wider-beta/public-release accuracy targets from that evidence.

Record release commit, archive checksums, exported signature/profile/team, upload/build ID, tester group, device results and unresolved issues in a private release log. Backups must outlive TestFlight builds. For rollback, restore only a compatible backup on an isolated installation; do not promise a downgrade preserves a database changed by a newer schema. Monitor beta feedback, fix blockers, and upload a new numbered build. TestFlight builds expire; schedule replacement/closure with the owner rather than treating beta hosting as permanent storage.

## Authoritative references

Checked October 25, 2026. Recheck Apple/provider requirements for later releases.

- [Apple TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Beta test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)
- [App Review Guidelines: privacy and beta review](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Encryption documentation determination](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/)
- [Current App Store Connect SDK support](https://developer.apple.com/help/app-store-connect/release-notes/)
- [OSM tile usage](https://operations.osmfoundation.org/policies/tiles/) and [Photon demo terms](https://github.com/komoot/photon#demo-server)
