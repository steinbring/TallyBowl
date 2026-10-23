# TallyBowl! development status

Updated October 23, 2026. This is the first development increment, not a production release.

## Feature branches

Work is committed as a stack of feature branches; each later branch includes the earlier features.

| Branch | Feature |
| --- | --- |
| `codex/project-roadmap` | Product scope and milestone plan |
| `codex/flutter-foundation` | Flutter targets, branding, visual theme |
| `codex/scoring-local-storage` | Ten-pin rules, domain records, SQLite persistence |
| `codex/session-journal` | Adaptive journal, inventories, frame editor, drafts, history, insights |
| `codex/on-device-score-capture` | Native camera/import, Apple Vision, bundled Android ML Kit, row/frame review |
| `codex/alley-map-selection` | OpenStreetMap pin selection and saved alley locations |
| `codex/sharing-backup` | Branded PNG recaps, native sharing, backup/restore, recovery copy, CSV exports |

The completed stack is integrated into local `main` after verification. Feature branches are retained. All work is local until explicitly pushed to the remote repository.

## Architecture

- `lib/src/domain/`: portable data models and deterministic ten-pin scoring.
- `lib/src/data/`: SQLite storage, backup format, CSV and file export.
- `lib/src/recognition/`: device image acquisition, native recognition interface, conservative row parser.
- `lib/src/features/`: session recording, photo review, history, insights, inventories, maps, sharing, settings.
- `lib/src/ui/`: shared interface elements and forms.
- `lib/src/config.dart`: branding, website, User-Agent, development tile endpoint.
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
- A hosted/self-hosted OSM-compatible place directory and nearby search; the current map has manual pin/name/address selection.
- Lane comparisons, more date filters, and more equipment comparison views.
- Optional retained evidence photos, ball photos, alley merging, and richer session editing.
- Store-ready application icons, signing/distribution setup, accessibility review at larger text scales, and performance evaluation with large histories.

## Persistence and portability

The database uses stable identifiers, foreign-key checks, a schema version, and transactional snapshot writes. Writes are serialized so background draft saves cannot overwrite newer game records. The first schema favors a small, understandable local journal; incremental writes should be considered when profiling larger histories.

A confirmed history game must contain a valid, complete ten-frame sequence. Unfinished frames are stored separately as a draft and excluded from statistics. Only one session can be in progress. Balls and alleys can be retired/archived without losing referenced history.

A JSON backup contains profile, inventories, sessions, games, and the unfinished frame draft. Source images and device file paths are excluded. Restore validates identifiers, references, frames, coordinates, weights, and draft ball selections before replacing anything. Settings saves a local `before-restore.json` recovery copy before applying a restore; the recovery action remains available after reopening the app. Restore currently replaces the journal rather than merging histories.

CSV exports are for analysis rather than restoration. One file contains game metadata and frame notation; the other contains individual deliveries including tenth-frame fill balls. User-entered text is quoted and protected from spreadsheet formula interpretation. Bowling date and original UTC offset are preserved.

## Data and network behavior

Scoreboard recognition is local. Apple uses Vision; Android links `com.google.mlkit:text-recognition:16.0.1` rather than the downloadable Play Services model. No app code sends photos or extracted scores to an AI service.

The app copies selected photos into its private imports folder while reviewing a new game. A draft retains that photo locally. Saving or discarding the draft removes it; startup removes orphaned import files. Temporary share/export files are kept long enough for receiving apps and old files are cleaned when another export is created.

Maps contact the selected tile service. There is no background location collection, account, cloud synchronization, or public Nominatim integration. OSM attribution remains visible, a TallyBowl User-Agent identifies the app, built-in tile caching honors HTTP headers, and tile buffers are zero to avoid offscreen prefetch. Production hosting and its attribution/usage requirements remain release decisions.

The canonical website address is `https://tallybowl.jws.app`, included in About, recap images, and map-service identification. This change does not create or deploy that website.

## Verification

Run `flutter analyze` and `flutter test` for scoring, persistence/reopen, backup validation, CSV, parser, desktop/phone recording, draft recovery, conflicting totals, and recap privacy behavior.

Run `flutter test integration_test/on_device_recognition_test.dart -d <device>` for native image recognition and local 1080-pixel-wide recap PNG generation. These checks use generated test content. They do not exercise physical cameras or send a recap to a recipient.

Before release, test actual camera permission/capture flows, platform photo formats/orientations, native share destinations and file import/export, interrupted Android picking, and app lifecycle recovery on physical iPad and Android devices and supported Macs. A successful native build is not evidence that these hardware flows have been tested.

## Verified first-build results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 24 tests passed |
| Native macOS integration | Labeled synthetic recognition and 1080-pixel PNG rendering passed |
| Native iPad simulator integration | Labeled synthetic recognition and 1080-pixel PNG rendering passed |
| `flutter build macos --debug` | Built on Apple silicon |
| `flutter build ios --simulator --debug --no-codesign` | Built |
| `flutter build apk --debug` | Built |

The running macOS landing screen and a generated recap PNG were visually inspected. A sample recap is available locally at `build/previews/tallybowl-recap.png` after this session's checks; build artifacts are ignored by Git. Android recognition is compile-verified, with runtime device checks still outstanding. See the recognition limitations above; a labeled synthetic fixture is not a real-photo accuracy benchmark.
