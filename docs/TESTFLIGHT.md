# TestFlight readiness and release runbook

Assessed October 25, 2026. Candidate **0.1.7 (8)**, bundle ID **app.jws.tallybowl**, existing Apple team **R9DBX89RA5**. Owner build **0.1.7 (8)** is installed on the Mac, iPad, and Samsung. No TestFlight build has been uploaded or approved by this preparation work.

## Readiness decision

The source is prepared for a **small internal owner beta**, subject to account, signing and Apple processing checks. A local source/build check is not a distribution approval. The first internal TestFlight installation can finish real Apple hardware acceptance while privacy-policy hosting is finalized. Public developer/support identity is Joe Steinbring, with verified contact at https://jws.dev/contact. Publish the privacy policy before onboarding external testers, and expand only after the critical device flows and Apple's beta review requirements pass.

| Gate | Evidence / remaining work |
| --- | --- |
| Scope and help | README, current roadmap, architecture, user guide, privacy policy, device checklist and reviewer instructions provided; user guide/privacy are bundled offline in Settings |
| Pure Dart/widget behavior | Candidate results recorded below; scoring, drafts, recognition parsing, migrations/backups, share export and accessibility regressions included |
| Apple packaging | App-owned required-reason manifests in both Resources phases, custom launch art and Mac Sports category; inspect actual archives, not just source files |
| Release protection | Mac sandbox/hardened runtime retained; owner ad hoc library exception is excluded from TestFlight packaging |
| Public developer/support | **Complete:** owner-approved Joe Steinbring and https://jws.dev/contact; verified HTTP 200 and the actual contact page on October 25, 2026. Bundled policy/help and beta metadata use this contact |
| Privacy website | **Open:** planned home and `/privacy` on `tallybowl.jws.app` fail DNS lookup on this Mac. Publish `PRIVACY_POLICY.md`; a separate TallyBowl `/support` page is no longer required for the selected public contact |
| Apple account and app records | **Not verified:** active program/team access, agreements, app record with iOS and macOS platforms, bundle registration, roles and App Store signing/profiles. Local machine currently has an Apple Development identity; this does not rule out Xcode cloud-managed distribution signing |
| Store privacy/export answers | **Open:** provider retention/privacy review and export questionnaire against final libraries; see below |
| Upload and Apple validation | **Not performed:** Organizer validation, App Store Connect export/upload, processed build, selected internal group, accepted TestFlight install |
| Physical Apple workflows | **Open for this candidate:** iPad camera/import, denied permission recovery, offline recognition, correct populated frames, popover sharing to real recipients, VoiceOver, backup/restore, upgrade/migration and interruption; repeat critical flows on native Mac |
| Recognition breadth | One real monitor regression plus synthetic fixtures; expand the permissioned corpus during internal beta. No broad accuracy claim |
| External beta | After internal acceptance: beta metadata/contact and Apple's review, invited group, support process and service-capacity/privacy decision. This preparation does not invite anyone |

## Candidate verification record

Verified against candidate **0.1.7 (8)** on October 25, 2026:

| Check | Result |
| --- | --- |
| Static analysis | No issues in `lib` and `test` |
| Unit/widget suite | **105 passed**, including real bundled help/privacy navigation, installed build display, narrow 200% text and document heading semantics |
| iPad Release archive | `flutter build ipa --release --no-codesign --target lib/main.dart` passed; version/build/ID/minimum iPadOS 15.0 validated; placeholder launch warning resolved; no signed IPA exported |
| Native Mac Release build/archive | Both passed; universal arm64/x86_64; minimum macOS 12.0; Sports category present. Signing was disabled for the archive rehearsal; linker ad hoc metadata has no distribution Team ID |
| Archive contents | Both contain the app-owned privacy manifest matching source, identical bundled help/policy, and dSYMs; no sealed owner-only package marker |
| Local preflight | Source and both archive checks passed. JSON: `build/readiness/local-preflight.json` |
| Android compatibility | Normal-entry-point debug APK compiled; native Lint passed with 0 errors and 10 advisory warnings (existing dependency/SDK, launcher shape and Kotlin-style notices) |
| Public URL check | Support contact **passed** at `https://jws.dev/contact`; planned `https://tallybowl.jws.app/privacy` **still fails DNS**. JSON: `build/readiness/public-url-check.json` |
| Final public contact update | Joe Steinbring and the approved support link are in both bundled documents and generated Markdown; the two document/navigation/accessibility checks were rerun successfully after this content update |
| Physical distribution install / Apple validation | **Not performed**; no current-candidate camera/share/VoiceOver or account/upload pass claimed |
| Local owner installations | 0.1.7 (8) installed/launched on Mac mini and physical iPad; all journal records/profile/draft unchanged. Existing Development signing was used for iPad and the labeled owner-only package for Mac. See `DEVICE_TESTING.md`; this is separate from TestFlight acceptance |

Build logs are `build/testflight-ios-archive.log`, `build/testflight-macos-build.log`, `build/testflight-macos-archive.log`, `build/testflight-tests.log` and `build/testflight-analyze.log`. Keep failures visible until resolved; the most recent successful command and its exact version matter more than the presence of an old file. These outputs are ignored by Git. Current changes are on `codex/testflight-readiness`; no populated installation was replaced by this preparation work.

## Upload preparation and external-beta checklist

1. Export a JSON backup from each populated owner installation and save it outside TallyBowl. Preserve the existing app/container. A simulator app or an unsigned archive cannot be installed on a real iPad; deleting a populated app to bypass signing is not an update strategy.
2. Confirm membership, team **R9DBX89RA5**, account permissions/agreements and the App Store Connect record. Register/select bundle `app.jws.tallybowl` and add the native macOS platform to the same app record if using one cross-platform listing. Keep native Mac and iPad builds separate; don't substitute “Designed for iPad” on Apple silicon for testing the native Mac app. Review the iPad-on-Mac availability choice before broad distribution.
3. Public contact is finalized as **Joe Steinbring**, https://jws.dev/contact. Before onboarding external testers, publish the HTTPS privacy policy from `PRIVACY_POLICY.md` at `https://tallybowl.jws.app/privacy`. Keep the bundled policy/help and generated Markdown in sync with `python3 tool/render_documents.py`. Verify actual policy/contact content without login. Set TestFlight's separate Feedback Email and private reviewer contact fields in App Store Connect; a website URL does not fill an email field. Hosting and account-field entry are not performed by this runbook. An owner-only internal install can proceed while the hosted policy is completed.
4. Review app privacy for the actual providers/platform. No journal/photos go to a developer server or cloud AI. OSM/Photon receive IP and request/query metadata and may retain logs. Android has Google ML Kit SDK diagnostics; it is absent from the Apple app. Do not automatically select “Data Not Collected” solely because OCR is local. Complete Apple's definitions/third-party review before external review or a public listing; the required-reason manifest is a different declaration.
5. Complete Apple's export questionnaire. Technical inventory: standard HTTPS through Dart/Flutter networking and SHA-256 photo filenames; no proprietary cipher, VPN, encrypted messaging or app-level journal encryption. Dart TLS is not necessarily OS URLSession. `ITSAppUsesNonExemptEncryption` is deliberately unset pending the final determination. Once approved, encode the appropriate Boolean/compliance code in both Info.plists if applicable and rebuild. An unset key is answered in App Store Connect; it is not an assertion of exemption.
6. Choose the next unused build number for each platform. The local candidate is build **8**, but App Store Connect history has not been inspected. If already used, increment `pubspec.yaml` and regenerate/recheck archives. Never overwrite evidence with a different build number silently.

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

Uploading, changing App Store Connect state and inviting testers are separate explicit actions. After authorized upload, confirm Apple processing has completed, fill export information, and verify the processed platform/version/build before selecting it for testing. Use the [metadata draft](TESTFLIGHT_METADATA.md) for description/What to Test/reviewer instructions; no login is needed.

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
