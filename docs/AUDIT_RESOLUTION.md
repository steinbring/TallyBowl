# External audit verification — October 24, 2026

Every one of the 27 findings in the [October 23 external report](audits/2026-10-23-external.md) was checked against this checkout, dependency implementations, platform documentation, or runtime tests. The supplied report is retained as evidence; its recommendations were evaluated independently. Its assertion that every finding was accurate does not hold for this checkout.

The resulting owner-test build is **0.1.2 (3)**. Confirmed code defects and useful accessibility/maintenance improvements are implemented. Production distribution credentials/hosting and physical-device testing remain separate gates. No physical Samsung or iPad has been installed or tested during this review.

## Disposition of every finding

“Accepted” means a documented product/scope decision, not an unresolved implementation task. “Release gate” means evidence or configuration is still required before public distribution.

| ID | Verdict | Evidence, action, and verification |
| --- | --- | --- |
| SEC-01 | Already fixed; production signing gate | The quoted debug signing configuration was absent in the starting checkout: commit `58d5a50` already set Android release `signingConfig = null`. Confirmed in `android/app/build.gradle.kts`. Debug APKs intentionally use the development key for local testing. A protected upload key and distribution setup are still required for production; no credentials were invented or committed. |
| SEC-02 | Claimed defect not confirmed | `image_picker` delegates to the installed camera app through an intent; it does not directly open Android camera hardware. Its own manifest does **not** declare CAMERA. The package documents no Android setup requirement. An app CAMERA permission is unnecessary for this path; a source comment explains the choice. See [image_picker setup and activity recovery](https://pub.dev/packages/image_picker#android). Physical Samsung camera behavior remains a device check. |
| SEC-03 | Claimed URI exposure not applicable | The temporary URI stays inside this app while ML Kit reads a private file. Android's [FileUriExposedException](https://developer.android.com/reference/android/os/FileUriExposedException) concerns file URIs exposed to another app. [ML Kit documents file-URI input](https://developers.google.com/ml-kit/vision/text-recognition/v2/android); a compressed JPEG buffer cannot simply replace a decoded YUV buffer. Kept the bounded file loader and added an explanation. The actual loader passed native recognition on the Android emulator, including its 16 KiB-page system image. |
| SEC-04 | Accepted, documented | SQLite, the local restore recovery copy, and user-exported JSON/CSV have no app-level encryption. They use OS sandbox/storage protections and chosen export destinations; those are distinct from app-level encryption. This matches the local journal scope. No unplanned encryption or migration was introduced. |
| SEC-05 | Fixed | `AppConfig.initialize` reads installed package metadata through `package_info_plus`; the map/search User-Agent includes version/build. Failure uses a versionless app identity. Tests cover both paths. |
| COM-01 | Runtime gap reduced; physical test gate | Bundled ML Kit and local recap rendering passed on an Android emulator; Apple Vision and recap checks run on macOS/iPad simulator. Physical camera/gallery, recipient sharing, interrupted picking and screen-reader use still need hardware evidence. Review also found a real gap: photos were not retained until row acceptance. Pending review is now persisted **before recognition**, resumed after reopening, and stripped from portable backups. Reopen, cancellation, and incomplete-OCR tests pass. See [device checklist](DEVICE_TESTING.md). |
| COM-02 | Hardened runtime enabled; distribution gate | Release configuration now enables hardened runtime without debug/JIT entitlements. Xcode's injected `get-task-allow` is explicitly disabled. Smoke launch exposed ad hoc frameworks failing hardened library validation. A guarded `tool/package_macos_local.sh` signs only an owner-test copy with the local library-validation exception; production entitlements stay strict and team-signed apps are refused. Signature/launch results are recorded in [development status](DEVELOPMENT.md). Developer ID/App Store signing and notarization require the owner's signing setup; the local ad hoc app is not a notarized public distribution. |
| COM-03 | Development choice retained; public-release gate | Public OSM raster tiles and Photon remain optional, key-free development defaults, with bounds, caching, request spacing, cooldown, attribution and manual/offline fallback. No capacity is reserved. Tile credit text/link are now configurable with `TALLYBOWL_TILE_ATTRIBUTION` / `_URL`, alongside endpoint overrides. [OSM policy](https://operations.osmfoundation.org/policies/tiles/) and [Photon policy](https://github.com/komoot/photon#demo-server) must guide hosting before a wider release. No paid service or deployment was selected without a traffic/distribution plan. |
| COM-04 | API valid; state workaround removed | Flutter 3.47.5 supports `initialValue`; `value` is deprecated and maps to it. The SDK's `didUpdateWidget` updates changed initial values. Kept the supported API and removed the primary-ball `ValueKey`. A widget test verifies untagging the primary ball resets the displayed selection while retaining the same FormField state, then accepts another selection. See [Flutter API](https://api.flutter.dev/flutter/material/DropdownButtonFormField-class.html). |
| COM-05 | Accepted scope | Native `dart:io`, file images, and platform branches are appropriate to the requested Android/macOS/iPadOS targets. Web/Windows/Linux remain unsupported. A speculative platform abstraction was not added; adding targets requires revisiting these capabilities. |
| COM-06 | Fixed | `pubspec.yaml` now declares Flutter >=3.47.5 alongside Dart ^3.13.4. README/development docs identify the verified toolchain and native verification command. |
| COM-07 | Intent confirmed | iPad-only device family 2 matches the user's explicit iPadOS target. iPhone support was not added. |
| A11Y-01 | Fixed | Added a complete dark theme; app follows system appearance. Screen surfaces, fields, dialogs and charts use active ColorScheme values. Fixed recap artwork retains brand colors. Light/dark widget tests and native preview checks cover the change. |
| A11Y-02 | Explanation inaccurate; real layout issues fixed | A literal TextStyle font size still scales through Flutter's inherited TextScaler ([API](https://api.flutter.dev/flutter/widgets/Text/textScaler.html)). Actual problems were tiny base labels, FittedBox suppression, fixed-height rows and dense controls. Raised small UI labels, removed shrinking wordmark layout, made toolbars/frame grids/summary/cards/navigation text-aware, and put Save in a safe-area footer on narrow editors. Main screens are checked at 200% text. The exported recap is intentionally fixed typography; its page includes a scalable text summary. |
| A11Y-03 | Automated coverage added; assistive hardware check remains | Chart values already had partial labels. Retained meaningful labels, removed duplicate decorative semantics, added frame descriptions and labeled touch-target checks. Tests exercise navigation, five main screens, editor and recap with enlarged text. Actual TalkBack/VoiceOver interaction remains in the physical checklist. |
| A11Y-04 | Fixed | Each scorecard frame announces its number, deliveries, and cumulative score as a coherent semantic node. This preserves frame navigation rather than making one very long utterance. Decorative BallArt is excluded. Semantics test passes. |
| A11Y-05 | Original contrast concern not reproduced; regression coverage added | The original muted-on-white and both cited hero text colors against both gradient endpoints exceed the 4.5:1 threshold. Tests also check light/dark text pairs at 4.5:1 and chart marks at 3:1. Chart colors use the active scheme. This is evidence for the tested color pairs, not a blanket accessibility certification. |
| COH-01 | Fixed | Relabeled “Save image” to “Export image.” Desktop uses the save dialog; touch platforms offer native export/share destinations. No false claim of saving directly to Photos and no new photo-library permission. |
| COH-02 | Refined; hidden-Settings claim inaccurate | Narrow macOS windows now use a compact navigation rail; wide windows retain the scrollable sidebar. Touch platforms retain bottom navigation. Settings was already in the narrow AppBar and remains accessible. Large-text and desktop-width tests cover both layouts. |
| COH-03 | Fixed shared policy | `ui/layout.dart` centralizes named navigation/content/editor/recap/settings widths, toolbar height and text-aware column selection. Component-specific geometry remains local where it serves a different purpose. Resize tests retain frame edits across narrow/wide transitions. |
| COH-04 | Fixed | Removed the forced primary dropdown recreation; state-transition test described under COM-04 proves the visual reset. |
| COH-05 | Fixed | Captures ScaffoldMessenger before popping the editor, then shows the saved message through that reference. Save workflow test confirms the snackbar appears without a context error. |
| MNT-01 | Analyzer diagnosis inaccurate; native check gap addressed | Dart analysis cannot parse/type-check Swift or Kotlin regardless of exclusions. Kept generated/native Dart exclusions. Added `tool/verify_native.sh` to compile Android, macOS and iPad simulator targets and run Android Lint. Native diffs were reviewed. No claim that Dart analysis covers native code or that SwiftLint was run. |
| MNT-02 | Refactored focused components | Extracted FrameGrid/ScoringSummary, GameCard/SessionCard and app navigation into dedicated UI files. This also fixed actual large-text card overflow. Scoring/persistence behavior remains covered by the workflow suite. |
| MNT-03 | Map order valid; cache behavior strengthened | [Dart's map literal preserves insertion order](https://api.dart.dev/dart-core/Map/Map.html). Added an explicit order comment and LRU promotion on hit; ten-minute TTL remains based on fetch time. Expired refreshes do not evict an unrelated entry. Injected-clock tests cover capacity, eviction and expiry. |
| MNT-04 | Automated gaps fixed; physical matrix remains | Added a checked-in recap golden, theme/text-scale consistency, contrast, semantics, target sizes, layout/resizing tests, and a reproducible 10,000-game persistence benchmark with SQL triggers verifying no history writes on draft save. Benchmark exposed repeated reference scans/duplicate validation; indexed lookups and one validation per persisted update reduce work. See measurements below. Physical camera/share/assistive testing is still a gate, not represented by a golden or emulator. |
| MNT-05 | Fixed consistency; manual catalog retained | Brand suggestions now derive from model brands plus explicit brand-only entries. Tests enforce nonempty, unique names and known model brands. The user-approved offline catalog still permits unrestricted manual entry; [source names/date](DATA_SOURCES.md) remain documented. No scraping dependency or hidden catalog API was added. |

## Verification evidence

- `flutter analyze`: no issues.
- `flutter test`: **65 passed**, including a recap golden, large text/light/dark layouts, semantic/touch checks, dropdown state, database reopen and photo recovery.
- Android emulator: **5 native checks passed** across recognition/recap and suggestion/dark-mode/artwork tests. Device was a local ARM64 Android 17 / API 37 emulator with a 16 KiB-page system image; it is not the Samsung phone.
- Android Lint: passed with 0 errors and 7 advisory warnings for tooling/template resources/legacy launcher silhouettes.
- macOS and iPad simulator: **5 native checks passed on each target**.
- Native verification script: Android debug build + Lint, universal macOS release, and iPad simulator build passed.
- Normal Android APK and extracted owner Mac archive both smoke-launched. APK signature, Mac strict code signature, version/build and archive integrity passed. The Mac owner package uses the explicit local signing exception described above. Full checks are recorded in [development status](DEVELOPMENT.md).

Run native checks explicitly; a clean Dart analyzer is insufficient:

```sh
flutter test integration_test/on_device_recognition_test.dart -d <device>
flutter test integration_test/suggestions_preview_test.dart -d <device>
./tool/verify_native.sh
```

The suggestion integration uses a mocked Photon response, so it verifies native form behavior rather than service availability. Recognition uses generated content, not a representative scoreboard photo corpus. Always rebuild the normal `lib/main.dart` entry point after integration tests before packaging.

## Large-history observations

`flutter test benchmark/journal_benchmark.dart` creates 10,000 synthetic games across 1,000 sessions, validates/saves/reloads them, and autosaves a draft. SQL triggers prove that autosave does not insert/update/delete history games. The benchmark has correctness assertions but no timing thresholds. Results are local Dart JIT/SQLite-FFI observations, not phone performance claims.

| Operation | Before indexed validation | After |
| --- | ---: | ---: |
| Validate snapshot | 170 ms | 71 ms |
| Initial save | 339 ms | 187 ms |
| Load | 240 ms | 141 ms |
| Draft update | 245 ms | 76 ms |

Observed output is generated at `build/benchmarks/journal.json`. Snapshot serialization still scales with history size; this change removes repeated linear reference searches and redundant validation rather than promising constant-time draft processing.

## Remaining gates

1. Complete the [physical-device checklist](DEVICE_TESTING.md), starting with the owner's Samsung Galaxy Z Fold 8. Collect real scoreboard examples and measure corrections/accuracy by layout. Complete equivalent iPad/Mac camera and assistive-technology checks.
2. Before public distribution, configure protected Android release signing, Apple signing/notarization/provisioning, and traffic-appropriate map/search hosting/attribution. The current packages are owner-test builds.
3. Revisit app-level encryption if the data sensitivity or sync scope changes; current storage/export behavior is explicit and intentional.

All fixes are committed on retained `codex/audit-*` feature branches and integrated locally into `main`. No remote push or public deployment is part of this review.
