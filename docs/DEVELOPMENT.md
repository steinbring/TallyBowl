# TallyBowl! development status

Updated October 24, 2026. Development build 0.1.4 (5) is intended for owner testing. Production distribution is not configured.

## Feature branches

Features are committed on `codex/` branches and merged locally into `main`. The initial implementation used a feature stack; subsequent suggestion and review branches are separate increments.

| Branch | Feature |
| --- | --- |
| `codex/project-roadmap` | Product scope and milestone plan |
| `codex/flutter-foundation` | Flutter targets, branding, visual theme |
| `codex/scoring-local-storage` | Ten-pin rules, domain records, SQLite persistence |
| `codex/session-journal` | Adaptive journal, inventories, frame editor, drafts, history, insights |
| `codex/on-device-score-capture` | Native camera/import, Apple Vision, bundled Android ML Kit, row/frame review |
| `codex/alley-map-selection` | OpenStreetMap pin selection and saved alley locations |
| `codex/sharing-backup` | Branded PNG recaps, native sharing, backup/restore, recovery copy, CSV exports |
| `codex/recognition-validation` | Bounded Apple image decoding with EXIF normalization, native integration checks, camera window resizing |
| `codex/alley-suggestions` | Key-free Photon place search, saved-venue reuse, manual fallback |
| `codex/ball-suggestions` | Offline manufacturer/model suggestions and custom entries |
| `codex/pretest-review-fixes` | Form retries, edit protection, incremental writes/migration, CSV/photo safeguards, camera lifecycle |
| `codex/test-build-polish` | Native previews, matching launcher icons, coherent dialog colors, test build packaging |
| `codex/audit-platform-verification` | Package-derived User-Agent, map credit configuration, hardened runtime, supported dropdown state, cache/catalog safeguards, native verification script |
| `codex/audit-accessibility` | System dark appearance, large-text layouts, desktop rail, frame/chart semantics, golden and accessibility checks, extracted UI components |
| `codex/audit-history-validation` | Indexed reference validation, one persisted validation pass, reproducible 10,000-game benchmark |
| `codex/audit-photo-recovery` | Retained pending photo review before OCR, reopen/cancel tests, live narrow/wide editor resizing |
| `codex/audit-macos-local-build` | Strict release entitlements plus an explicit, guarded ad hoc owner-package step |
| `codex/audit-verification-report` | Independent disposition of all 27 external findings, physical-device checklist and refreshed local packages |
| `codex/audit2-android-signing` | Protected release signing configuration, explicit missing-key failure, debug-build independence |
| `codex/audit2-mac-artifact-labels` | Owner-only archive filename and sealed signing-policy manifest |
| `codex/audit2-startup-recovery` | Nonblocking metadata refresh, first-frame test and photo failure/cleanup matrix |
| `codex/audit2-verification-record` | Five-finding round-2 disposition, signing timeline and build 0.1.3 evidence |
| `codex/self-audit-input-privacy` | Bounded backup streams and neutral recap attachment names |
| `codex/self-audit-photo-acquisition` | Shared photo acquisition reservation and startup cleanup coordination |
| `codex/self-audit-map-accessibility` | Coordinate entry, dark map contrast and typed alley save completion |
| `codex/self-audit-history-performance` | Shared journal groups, session paging and widget benchmark |
| `codex/self-audit-dialog-lifecycle` | Profile/session State ownership for form controllers |
| `codex/self-audit-validation` | Build 0.1.4 owner packages and combined validation |

The completed stack is integrated into local `main` after verification. Feature branches are retained. All work is local until explicitly pushed to the remote repository.

## Architecture

- `lib/src/domain/`: portable data models and deterministic ten-pin scoring.
- `lib/src/data/`: SQLite storage, backup format, CSV/file export, bounded Photon adapter and offline ball catalog.
- `lib/src/recognition/`: device image acquisition, native recognition interface, conservative row parser.
- `lib/src/features/`: session recording, photo review, history, insights, inventories, maps, sharing, settings.
- `lib/src/ui/`: shared interface elements and forms.
- `lib/src/config.dart`: branding, website, User-Agent, development tile and Photon endpoints.
- `macos/Runner/MainFlutterWindow.swift`: Apple Vision channel and native AVFoundation camera window.
- `ios/Runner/AppDelegate.swift`: Apple Vision channel registered with the Flutter engine.
- `android/app/src/main/kotlin/app/jws/tallybowl/MainActivity.kt`: bundled ML Kit recognition channel.

The iOS project targets iPad. Android and macOS are also generated targets; web, Windows, and Linux are outside this build's scope. The initial build toolchain is Flutter 3.47.5 / Dart 3.13.4 with Xcode 27 and the installed Android SDK.

## Recognition limits

The initial parser can prefill ten clearly separated, complete frame notations on a horizontal row, with an optional scratch total. It can also partition twelve explicitly recognized strike marks into a perfect game, including when OCR merges adjacent strike symbols. It never fills missing strikes from a displayed 300.

Unclear layout, missing marks, totals-only images, and unsupported symbols require manual frame entry. Some scoreboards position roll marks, names, and cumulative totals on different baselines; those need dedicated geometry/layout parsing in the next increment. Alias matches only suggest a row. A human must select the row and review the frame draft. A displayed total that conflicts with calculated frames requires explicit acknowledgment after review.

A sparse strike-only row labeled only with a short alias was read upside down by Vision in the iPad simulator even though the input PNG was upright. A row with a full readable bowler label passes. Treat sparse or incorrectly oriented reads as a known recognition limitation requiring manual review; the labeled synthetic check does not resolve this class of image.

No real scoreboard photo corpus has been supplied yet. Synthetic integration checks establish the native channel and supported parser behavior, not accuracy on real alleys' displays. Before beta, collect permissioned examples, annotate the intended bowler and each delivery, reserve evaluation photos, and measure complete-game accuracy and correction effort by layout and platform.

Still to implement or expand:

- General grid/header detection, symbol detection, crop/perspective correction, and rotation controls.
- Multi-photo queues, combining photos of one game, import history, and stronger duplicate detection.
- Production-capacity map/search hosting and optional nearby search. Name-and-city suggestions now use the documented Photon API; saved alleys and manual entry remain available offline.
- Lane comparisons, more date filters, and more equipment comparison views.
- Optional retained evidence photos, ball photos, alley merging, and richer session editing.
- Production signing/distribution setup and physical TalkBack/VoiceOver evaluation. Automated 200% text, theme, contrast, semantics and 10,000-game checks now pass. Branded launcher icons reuse the in-app ball artwork.

## Persistence and portability

The database uses stable identifiers, foreign-key checks, and atomic incremental writes. Schema v2 adds explicit record positions and migrates v1 journals without changing their data. Serialized rows are compared before writing; a draft autosave leaves history tables untouched. The controller serializes writes so draft saves cannot overwrite newer game records, and the store advances its row cache only after commit. Reference validation uses indexed identifier lookups, and each persisted update validates once. Snapshot serialization still scales with journal size. The 10,000-game host benchmark observed draft updates fall from 245 ms to 76 ms after this optimization; this is not phone performance evidence. See AUDIT_RESOLUTION.md for measurements and reproduction.

A confirmed history game must contain a valid, complete ten-frame sequence. Unfinished frames are stored separately as a draft and excluded from statistics. Only one session can be in progress. Balls and alleys can be retired/archived without losing referenced history.

A JSON backup contains profile, inventories, sessions, games, and the unfinished frame draft. Source images and device file paths are excluded. Restore validates identifiers, references, frames, coordinates, weights, and draft ball selections before replacing anything. Settings saves a local `before-restore.json` recovery copy before applying a restore; the recovery action remains available after reopening the app. Restore currently replaces the journal rather than merging histories.

CSV exports are for analysis rather than restoration. One file contains game metadata and frame notation; the other contains individual deliveries including tenth-frame fill balls. User-entered text is quoted and protected from spreadsheet formula interpretation. Bowling date and original UTC offset are preserved.

## Data and network behavior

Scoreboard recognition is local. Apple uses Vision; Android links `com.google.mlkit:text-recognition:16.0.1` rather than the downloadable Play Services model. No app code sends photos or extracted scores to an AI service.

The app copies selected photos into its private imports folder while reviewing a new game. A draft retains that photo locally **before** recognition/row selection begins. Interrupted pending review is reopened on launch; selected frames are persisted before opening the editor. Saving or discarding the draft removes it; startup removes orphaned import files. Temporary share/export files are kept long enough for receiving apps and old files are cleaned when another export is created.

Maps contact the selected tile service. Explicit alley searches send only the entered query to Photon. Ball suggestions are offline. There is no background location collection, account, cloud synchronization, or public Nominatim integration. See [data sources](DATA_SOURCES.md) for endpoints, service policies, attribution, limits, caching and offline behavior. OSM attribution remains visible, a package-version-derived TallyBowl User-Agent identifies the app, built-in tile caching honors HTTP headers, and tile buffers are zero to avoid offscreen prefetch. Production hosting and its attribution/usage requirements remain release decisions.

The canonical website address is `https://tallybowl.jws.app`, included in About, recap images, and map-service identification. This change does not create or deploy that website.

## Verification

Run `flutter analyze` and `flutter test` for scoring, persistence/reopen, backup validation, CSV, parser, desktop/phone recording, pending-photo/draft recovery, conflicting totals, recap privacy/golden behavior, contrast, semantics, target sizes, dark/light appearance and layouts at 200% text.

Run `./tool/verify_native.sh` to build Android debug, macOS release and iPad simulator debug targets and run Android Lint. Dart analysis cannot type-check the Kotlin/Swift bridges. Run `flutter test benchmark/journal_benchmark.dart` for the optional synthetic 10,000-game check; output is in `build/benchmarks/journal.json`.

Run `flutter test benchmark/journal_widgets_benchmark.dart` for the optional 10,000-game/1,000-session view benchmark; output is in `build/benchmarks/journal-widgets.json`. It measures host widget-test timings without machine-dependent timing assertions. History opens with 50 sessions and offers additional pages; shared snapshot indexes group games for journal and comparison views.

Run `flutter test integration_test/on_device_recognition_test.dart -d <device>` for native image recognition and local 1080-pixel-wide recap PNG generation. These checks use generated test content. They do not exercise physical cameras or send a recap to a recipient.

The 27-finding first audit disposition is in [AUDIT_RESOLUTION.md](AUDIT_RESOLUTION.md). [AUDIT_ROUND2_RESOLUTION.md](AUDIT_ROUND2_RESOLUTION.md) covers the five follow-up findings, signing history and current verification. Release signing setup is documented in [ANDROID_SIGNING.md](ANDROID_SIGNING.md). The next owner-testing phase follows [DEVICE_TESTING.md](DEVICE_TESTING.md), beginning with the Samsung Galaxy Z Fold 8.

Before release, test actual camera permission/capture flows, platform photo formats/orientations, native share destinations and file import/export, interrupted Android picking, and app lifecycle recovery on physical iPad and Android devices and supported Macs. A successful native build is not evidence that these hardware flows have been tested.

## Verified build 0.1.4 (5) results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 87 passed, including bounded backup reads, share attachment privacy, delayed photo acquisition, accessible map entry, existing-venue completion, indexed statistics, history paging and form dismissal during keyboard changes |
| Large-journal views | Optional 10,000-game/1,000-session widget benchmark passed; no timing assertions or physical-device performance claim |
| `tool/verify_native.sh` | Passed: Android debug build/Lint, universal macOS release and iPad simulator build. Lint: 0 errors, 7 existing advisory warnings |
| Owner packages | Android APK v2 signature/version verified; extracted Mac signature, sealed policy manifest and ZIP integrity verified. Both packages identify 0.1.4/build 5 |

Native recognition/camera bridges are unchanged in this pass. Earlier native integration and smoke-launch evidence remains labeled by build below. Current physical-device checks are in DEVICE_TESTING.md.

## Verified build 0.1.3 (4) results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 68 passed, including delayed metadata, recognition failure/manual entry, failed draft persistence and real retained-photo cleanup |
| Android release guard | APK and AAB commands explicitly rejected missing credentials before Flutter release compilation |
| Disposable signing fixture | Release APK built and its v2 signature/certificate verified; test key and installable fixture outputs removed |
| `tool/verify_native.sh` | Passed: Android debug build/Lint, universal macOS release and iPad simulator build. Lint: 0 errors, 7 existing advisory warnings |
| Mac owner packaging | OWNER-TEST-ONLY archive and sealed manifest match actual runtime/entitlement policy; modified manifest fails strict signature verification; extracted 0.1.3/build 4 archive smoke-launched |

Native recognition/camera bridges are unchanged in this pass. The 15 native integration checks below are retained as **0.1.2 evidence**, not a claim of new physical-device coverage. Current physical-device gates are in DEVICE_TESTING.md.

## Prior verified build 0.1.2 (3) results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 65 tests passed |
| Native macOS integration | Recognition, 1080-pixel recap PNG, suggestion workflows and launcher rendering passed (5 checks) |
| Native iPad simulator integration | Recognition, 1080-pixel recap PNG, suggestion workflows and launcher rendering passed (5 checks) |
| `flutter build macos --release` | Built universal x86_64/arm64 app with hardened runtime; strict signature verified |
| `flutter build ios --simulator --debug --no-codesign` | Built |
| `flutter build apk --debug` | Built |
| Packaged owner Mac smoke launch | Extracted 0.1.2 archive launched on Apple silicon with hardened runtime/local library exception; strict signature and archive integrity passed |
| Normal Android APK smoke launch | Installed/launched on the local emulator after rebuilding `lib/main.dart`; package version 0.1.2/code 3 and APK v2 signature verified |
| Android Lint `:app:lintDebug` | Passed, 0 errors; 7 advisory warnings (Gradle update, redundant v21 resource folder, legacy square launcher silhouettes) |
| Native Android emulator integration | Bundled ML Kit recognition, 1080-pixel recap, suggestions, dark-mode dashboard and artwork passed (5 checks) |

The macOS landing screen, recap PNG, new suggestion dialogs and launcher artwork were visually inspected. Final dialog previews are in `build/previews/ball-suggestions.png` and `build/previews/alley-suggestions.png`. A sample recap is available locally at `build/previews/tallybowl-recap.png` after this session's checks; build artifacts are ignored by Git. Android native recognition also passed on a local ARM64 Android 17 / API 37 emulator with a 16 KiB-page system image. Physical Samsung camera/gallery/share and interruption checks remain outstanding. See the recognition limitations above; a labeled synthetic fixture is not a real-photo accuracy benchmark.


## Launcher artwork

The native launcher icons reuse `BallArt`, with the same colors and three finger holes as the application. `integration_test/suggestions_preview_test.dart` renders 1024-pixel masters and native form previews in the app cache; it prints their paths. To regenerate platform icons on macOS, run:

```sh
flutter test integration_test/suggestions_preview_test.dart -d macos
swift tool/generate_icons.swift <tallybowl-icon.png-path> <tallybowl-icon-mac.png-path>
```

The generator uses Core Graphics/ImageIO, preserves transparency on macOS, and writes opaque iPad/Android icons at every configured size. Rebuild the normal `lib/main.dart` target after integration tests before packaging an app for installation. For the local Mac archive, run `./tool/package_macos_local.sh` after the release build.


## Install the local test build

Version **0.1.4**, build **5**. These packages are generated locally and ignored by Git:

| Target | Local package | Installation |
| --- | --- | --- |
| macOS | `build/releases/TallyBowl-0.1.4-macos-OWNER-TEST-ONLY.zip` (about 20 MB) | Unzip, move `TallyBowl!.app` to Applications if desired, then open it. The app is a universal Intel/Apple silicon release build with an ad hoc signature and an explicit local library-validation exception; it is not a notarized distribution. |
| Android | `build/releases/TallyBowl-0.1.4-android-debug.apk` (about 224 MB) | Transfer the APK to the device and open it, allowing installation from the selected source if Android prompts. This uses the local development key. Production releases use explicit protected key properties; missing credentials stop release builds. |
| iPad simulator | `build/ios/iphonesimulator/Runner.app` | Run `flutter run -d <simulator-id>` or install this app through the simulator tools. A simulator binary cannot be installed on a physical iPad. |

For a physical iPad, select a development team and provisioning/signing setup in the iOS Runner project using Xcode, then run `flutter run -d <device-id>`. No physical-device IPA has been signed or exported.

The strict release build enables hardened runtime and disables Xcode's injected `get-task-allow`. Ad hoc apps/frameworks have no Team ID: the strict build failed the runtime library check during smoke launch. `tool/package_macos_local.sh` therefore signs a **copy** with only the local `disable-library-validation` exception, retaining sandbox/runtime protections and no JIT/debug entitlement. It refuses to change a team-signed app. The archive filename includes `OWNER-TEST-ONLY`; a signed/sealed `Contents/Resources/TallyBowlBuild.json` records its version, build, non-distribution warning and exact signing/runtime policy. Production entitlements retain library validation; proper Apple signing of the app and its embedded code, plus notarization, remains required.

`build/releases/checksums.json` records SHA-256 values, code revision and owner-only distribution policy for the packaged Mac and Android builds. The current Mac archive is built from the normal `lib/main.dart` entry point. Package signature/ZIP integrity and Android APK signature/version checks are recorded with each build; previous smoke-launch evidence is labeled by build above.

Start by adding a profile, a searched or manual alley, and balls from suggestions or custom names. Record a manual game, then try a real scoreboard photo and compare every frame. Finish the session, inspect the branded recap and try a share destination. Export a JSON backup before experimenting with restore. Physical camera/share workflows, Android picker process recovery, TalkBack/VoiceOver and representative scoreboard recognition are the key remaining device checks. See [review findings](REVIEW.md) for the full record.
