# TallyBowl! development status

Updated October 23, 2026. Development build 0.1.1 (2) is intended for owner testing. Production distribution is not configured.

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
- Signing/distribution setup, accessibility review at larger text scales, and performance evaluation with large histories. Branded launcher icons now reuse the in-app ball artwork.

## Persistence and portability

The database uses stable identifiers, foreign-key checks, and atomic incremental writes. Schema v2 adds explicit record positions and migrates v1 journals without changing their data. Serialized rows are compared before writing; a draft autosave leaves history tables untouched. The controller serializes writes so draft saves cannot overwrite newer game records, and the store advances its row cache only after commit. Snapshot validation/serialization still scales with journal size; profile large histories before further optimization.

A confirmed history game must contain a valid, complete ten-frame sequence. Unfinished frames are stored separately as a draft and excluded from statistics. Only one session can be in progress. Balls and alleys can be retired/archived without losing referenced history.

A JSON backup contains profile, inventories, sessions, games, and the unfinished frame draft. Source images and device file paths are excluded. Restore validates identifiers, references, frames, coordinates, weights, and draft ball selections before replacing anything. Settings saves a local `before-restore.json` recovery copy before applying a restore; the recovery action remains available after reopening the app. Restore currently replaces the journal rather than merging histories.

CSV exports are for analysis rather than restoration. One file contains game metadata and frame notation; the other contains individual deliveries including tenth-frame fill balls. User-entered text is quoted and protected from spreadsheet formula interpretation. Bowling date and original UTC offset are preserved.

## Data and network behavior

Scoreboard recognition is local. Apple uses Vision; Android links `com.google.mlkit:text-recognition:16.0.1` rather than the downloadable Play Services model. No app code sends photos or extracted scores to an AI service.

The app copies selected photos into its private imports folder while reviewing a new game. A draft retains that photo locally. Saving or discarding the draft removes it; startup removes orphaned import files. Temporary share/export files are kept long enough for receiving apps and old files are cleaned when another export is created.

Maps contact the selected tile service. Explicit alley searches send only the entered query to Photon. Ball suggestions are offline. There is no background location collection, account, cloud synchronization, or public Nominatim integration. See [data sources](DATA_SOURCES.md) for endpoints, service policies, attribution, limits, caching and offline behavior. OSM attribution remains visible, a TallyBowl User-Agent identifies the app, built-in tile caching honors HTTP headers, and tile buffers are zero to avoid offscreen prefetch. Production hosting and its attribution/usage requirements remain release decisions.

The canonical website address is `https://tallybowl.jws.app`, included in About, recap images, and map-service identification. This change does not create or deploy that website.

## Verification

Run `flutter analyze` and `flutter test` for scoring, persistence/reopen, backup validation, CSV, parser, desktop/phone recording, draft recovery, conflicting totals, and recap privacy behavior.

Run `flutter test integration_test/on_device_recognition_test.dart -d <device>` for native image recognition and local 1080-pixel-wide recap PNG generation. These checks use generated test content. They do not exercise physical cameras or send a recap to a recipient.

Before release, test actual camera permission/capture flows, platform photo formats/orientations, native share destinations and file import/export, interrupted Android picking, and app lifecycle recovery on physical iPad and Android devices and supported Macs. A successful native build is not evidence that these hardware flows have been tested.

## Verified build 0.1.1 (2) results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 42 tests passed |
| Native macOS integration | Recognition, 1080-pixel recap PNG, suggestion workflows and launcher rendering passed (4 checks) |
| Native iPad simulator integration | Recognition, 1080-pixel recap PNG, suggestion workflows and launcher rendering passed (4 checks) |
| `flutter build macos --release` | Built universal x86_64/arm64 app; tested on Apple silicon; signature verified |
| `flutter build ios --simulator --debug --no-codesign` | Built |
| `flutter build apk --debug` | Built |

The macOS landing screen, recap PNG, new suggestion dialogs and launcher artwork were visually inspected. Final dialog previews are in `build/previews/ball-suggestions.png` and `build/previews/alley-suggestions.png`. A sample recap is available locally at `build/previews/tallybowl-recap.png` after this session's checks; build artifacts are ignored by Git. Android recognition is compile-verified, with runtime device checks still outstanding. See the recognition limitations above; a labeled synthetic fixture is not a real-photo accuracy benchmark.


## Launcher artwork

The native launcher icons reuse `BallArt`, with the same colors and three finger holes as the application. `integration_test/suggestions_preview_test.dart` renders 1024-pixel masters and native form previews in the app cache; it prints their paths. To regenerate platform icons on macOS, run:

```sh
flutter test integration_test/suggestions_preview_test.dart -d macos
swift tool/generate_icons.swift <tallybowl-icon.png-path> <tallybowl-icon-mac.png-path>
```

The generator uses Core Graphics/ImageIO, preserves transparency on macOS, and writes opaque iPad/Android icons at every configured size. Rebuild the normal `lib/main.dart` target after integration tests before packaging an app for installation.


## Install the local test build

Version **0.1.1**, build **2**. These packages are generated locally and ignored by Git:

| Target | Local package | Installation |
| --- | --- | --- |
| macOS | `build/releases/TallyBowl-0.1.1-macos.zip` (about 20 MB) | Unzip, move `TallyBowl!.app` to Applications if desired, then open it. The app is a universal Intel/Apple silicon release build with an ad hoc signature, not a notarized distribution. |
| Android | `build/releases/TallyBowl-0.1.1-android-debug.apk` (about 200 MB) | Transfer the APK to the device and open it, allowing installation from the selected source if Android prompts. This uses the local development key; release signing is not configured. |
| iPad simulator | `build/ios/iphonesimulator/Runner.app` | Run `flutter run -d <simulator-id>` or install this app through the simulator tools. A simulator binary cannot be installed on a physical iPad. |

For a physical iPad, select a development team and provisioning/signing setup in the iOS Runner project using Xcode, then run `flutter run -d <device-id>`. No physical-device IPA has been signed or exported.

`build/releases/checksums.json` records SHA-256 values for the packaged Mac and Android builds. The Mac archive was built from the normal `lib/main.dart` entry point after integration testing; `codesign --verify --deep --strict` passed.

Start by adding a profile, a searched or manual alley, and balls from suggestions or custom names. Record a manual game, then try a real scoreboard photo and compare every frame. Finish the session, inspect the branded recap and try a share destination. Export a JSON backup before experimenting with restore. Physical camera/share workflows and Android recognition runtime are the key remaining device checks. See [review findings](REVIEW.md) for the full record.
