# TallyBowl! development status

November 14 Android owner build **0.1.21 (22)** is installed and launched on the
attached Fold 8. It includes the recognition correction below, uses the same
installed development signer and permissions, and preserves all 12 app-data
files during installation. Post-launch integrity and complete logical-journal
comparisons preserve **27 games, 9 sessions, 3 balls**, profile and draft settings.
The installed APK and running kernel match the verified normal-entry-point
artifact; the Tonight screen was visually checked. This step makes no TestFlight
upload or physical recognition-accuracy claim. See [device evidence](DEVICE_TESTING.md).

November 14 source correction for the November 10/13 photos: both native
engines now recover all ten frames and scratch totals in **8/8 finished views**,
covering **6/6 unique games**. The six-frame view remains in Review. The final
measured-band retry handles tall delivery ink, compact/merged frame headings,
right-aligned totals, sparse console headings and repeated stacked scratch/
handicap totals without changing native helpers, glyph assets or thresholds.
Across **113 regression cases / 64 originals per engine**, all **35 prior exact
imports on each engine** are preserved. Apple gains one additional older case;
Android gains three. Both leave all **35 negative rows** unselected, with no
incorrect automatic candidates, evaluation errors or excess native calls.
**318 Flutter tests and 16 lab tests pass**; static analysis is clean. This is
source-level verification, separate from the build-21 release and installation
records below. See [the results and limits](NOV13_PHOTO_EVALUATION.md).


November 10 release **0.1.20 (21)**: optional **Cover material** and
**Cover type** fields are editable in the ball form and shown in My Bag. The
71-entry offline specification table covers all 63 retained Brunswick/Radical
variants, seven additional starter models and generic TZone, using verified
manufacturer sources. Exact normalized make/model matches populate untouched
fields on new balls; manual choices and clears take precedence. Existing balls
preserve stored fields until the owner chooses **Use model specifications**.
Optional JSON fields preserve old backups and stable game/draft references.
**303 Flutter tests pass** and static analysis is clean, including the retained
recognition suite, save retries, backup/restore and light/dark 200% text checks.
Recognition helpers, scoring and glyph assets are unchanged. See
[the specification provenance and rules](DATA_SOURCES.md#offline-coverstock-defaults).
Both iPad and native Mac are **Testing in Owner testing** and assigned to
**External testing**, **Waiting for Review**, with automatic notification enabled.
Signing, package and asset checks pass. See [the release record](TESTFLIGHT.md).
The Fold 8 was subsequently updated in place to the normal Android owner build
**0.1.20 (21)** on November 10. Signing, permissions and all 12 persistent
app-data files are preserved; startup succeeds and the journal remains
identical, with 24 games across 8 sessions plus profile and draft settings.
The Flip 7 remains on build 19. See [device evidence](DEVICE_TESTING.md).

Included in build 21: ball labels now include model and weight,
with an optional nickname kept separate from the catalog model. Matching labels
use color, then a number in saved bag order, including retired records, so used
and primary selectors stay distinct. My Bag, history, insights, recaps and CSV
use the same labels. Nicknames survive storage/backup; existing ball IDs and
saved game/draft references are preserved. The full **303-test** release suite
passes, including recognition and 200% text checks; static analysis is clean.
Recognition source, native helpers and glyph assets are unchanged.

November 9 release **0.1.19 (20)** improves gutter marks, intermediate italic
lettering and overlapping scratch-total fragments. Both native engines recover
all ten frames in the three clearer November 8 games (**88, 115 and 117**); the
distant duplicate still needs review. All 35 prior exact imports on each engine
are retained across 208 native row checks with no incorrect automatic candidates.
The fresh four-photo online sample recovers 0/4 complete games on both engines;
unfamiliar layouts remain limited. **286 Flutter tests and 16 lab tests pass**;
static analysis is clean. See [the verification](NOV09_RECOGNITION_CHECK.md) and
[the gutter correction](NOV08_PHOTO_EVALUATION.md).

Both iPad and native Mac build 20 are **Testing in Owner testing** and assigned
to **External testing** with status **Waiting for Review**, with automatic tester
notification enabled. Packages pass archive/content, signing and asset checks.
See [the release record](TESTFLIGHT.md). No new Android installation or physical
iPadOS camera/gallery acceptance was performed for this release; the Samsung
installation records below remain build 19. Later source changes are separate.

November 8 release **0.1.18 (19)** for the November 7 practice photos: all three originals
now yield exact frames and totals **93, 148 and 105** through both native engines
and the shared production pipeline. The additional fallback corrects condensed
italic glyphs, independently supported header heights and primary/crop evidence
handling. Existing validated paths run first; native helpers, the 78-template
glyph bank, confidence thresholds, journal and backup formats are unchanged.
All **272 Flutter tests and 16 lab safety/training tests pass**; static analysis
is clean, including the retained conflicting-player identity check.
See [the evaluation and regression evidence](NOV07_PHOTO_EVALUATION.md).
Both iPad and native Mac build 19 are **Testing in Owner testing** and assigned
to **External testing** with status **Waiting for Review**. Automatic tester
notification is enabled; external access awaits Apple approval. Signing,
archive/content and bundled-asset checks pass. See [the release record](TESTFLIGHT.md).
The Fold 8 was subsequently updated in place to the normal Android owner build
**0.1.18 (19)** on November 8. Signing, permissions and all 12 persistent app-data
files are preserved; startup succeeds and the journal remains identical, with
15 games across 5 sessions plus profile and draft settings. The locked phone
prevented visual acceptance. The Flip 7 (SM-F766U) was also updated in place to
the same build 19 APK on November 8, preserving all 8 persistent files and its
empty journal. Startup succeeds; the lock screen prevented visual acceptance.
See [device evidence](DEVICE_TESTING.md). No new physical Apple acceptance was
performed. The following build-18 paragraphs retain their historical scope.

Updated November 6, 2026. Build **0.1.17 (18)** improves scoreboard row alignment, light/dark and mixed delivery ink, and current-game scratch-total selection. **259 Flutter tests and 16 lab safety/training tests pass**, and static analysis is clean. Across 77 regression row cases from 42 original photos per native engine, all 24 prior exact complete games are preserved on each engine. Apple now recovers 26/53 complete games and Android 25/53; no incorrect automatic candidate is observed and all 24 negative cases remain unselected. The two complete games in a separate frozen holdout still need review, and its four clipped rows remain unselected. See [scoreboard recovery and limits](SCOREBOARD_RECOVERY.md).

Build 18 retains the official social links in Settings, the 50 Brunswick and 13 Radical suggestions checked for build 15, and 11 optional basic ball colors. The catalog remains offline and accepts custom/older equipment. Colors update My Bag artwork and labels, persist in the journal and backups, and can be cleared; older records remain unset. Persistence, backup compatibility, save retries and light/dark forms at 200% text remain covered. See [catalog provenance](DATA_SOURCES.md) and [the guide](USER_GUIDE.md).

Both signed iPad and native Mac build-18 packages are **Testing in Owner testing**, verified November 5. This release was assigned only to Owner testing as requested. Both targets pass archive/content and exported distribution certificate/profile checks; the universal Mac package also passes installer-chain and payload-readability checks. Approved encryption/France answers and build notes are saved. Existing external assignments and group settings were retained. See [TESTFLIGHT.md](TESTFLIGHT.md). The Samsung Galaxy Z Fold 8 was updated in place to the normal Android owner build **0.1.17 (18)** on November 6, with matching signing certificates, unchanged permissions and all 12 persistent app-data files unchanged immediately after installation. Startup succeeds and its journal remains identical, preserving 12 games across 4 sessions, profile and draft settings. The locked phone prevented visual in-app acceptance. See [device evidence](DEVICE_TESTING.md).

Build 18 also retains the build-17 Android export fix: Export image saves directly to Pictures/TallyBowl on Android 10+, with a save-location picker on older Android; Share image opens the chooser. That release passed seven Android native checks and Lint with no errors. See [the quick audit](NOV03_QUICK_AUDIT.md). Journal and backup formats are unchanged. Recognition continues to require review for many unfamiliar or small scoreboards; see [recognition safeguards](FRAME_RECOGNITION.md). Physical Apple TestFlight installation, Google Chat composer acceptance, camera workflows and public privacy-policy hosting remain separate work. Results below retain historical build labels.

The same verified Android build 18 was also installed fresh on a separately attached Samsung SM-F766U running Android 17 on November 6. Its installed APK matches the release artifact and activity startup succeeds. No other device's journal was copied; the locked phone prevented visual acceptance. See [the installation record](DEVICE_TESTING.md).

## Feature branches

Features are committed on `codex/` branches and merged locally into `main`. The initial implementation used a feature stack; subsequent suggestion and review branches are separate increments.

| Branch | Feature |
| --- | --- |
| `codex/scoreboard-recovery` | Conservative layout/ink/total and italic-glyph recovery, frozen regression/holdout evidence, and build 20 owner/external TestFlight release |
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
| `codex/scoreboard-grid-recognition` | Layout-aware deliveries, bounded local refinement, checkpoint validation, automatic entry and old-draft recovery |
| `codex/recap-handoff-validation` | Camera URI handler visibility, SDK diagnostic disclosure and PNG recipient verification |
| `codex/owner-build-0-1-5` | AndroidX EXIF format compatibility, owner packages and in-place installation verification |
| `codex/bowler-branding` | Pointing bowler master, matching app/recap/launcher identity, three-hole bowling-ball navigation and theme checks |
| `codex/owner-build-0-1-6` | Branding preview timing, verified owner packages and data-preserving updates |
| `codex/testflight-readiness` | Offline help/privacy, version display, Apple manifests/launch art/category, current documentation and archive preflight |
| `codex/public-support-contact` | Approved Joe Steinbring identity and verified jws.dev contact link in bundled help/privacy and release metadata |
| `codex/owner-install-0-1-7` | Verified 0.1.7 Mac/iPad owner installations, protected backups and unchanged-journal comparisons |
| `codex/samsung-owner-install-0-1-7` | Matching-signer 0.1.7 Samsung update, final bundled documents, protected APK/data backups and unchanged-journal comparison |
| `codex/testflight-setup` | Explicit Apple ID/app record, signed iPad/Mac exports and uploads, private owner testing group and release runbook |
| `codex/audit3-recognition` | Verified round-three dispositions, light/dark native stroke recovery, shared native fixtures and F/X name parsing |
| `codex/testflight-distribution-fix` | App-target Mac signing overrides, nested certificate/profile preflight and candidate 0.1.8 (9) |
| `codex/scoreboard-photo-autofill` | Shared local glyph recovery, EXIF-aware real-photo fixtures and editor auto-fill/resume regressions |
| `codex/delete-sessions` | Confirmed session removal, transactional games/draft cascade, retained-photo cleanup and retry tests |
| `codex/android-image-sharing` | Scoped PNG provider, ClipData/read grants and separate-UID receiver instrumentation |
| `codex/testflight-0-1-9` | Build 10 packages, helper-permission exclusion, Apple owner/external beta configuration and Samsung update evidence |
| `codex/league-scoreboard-recognition` | Perspective-aware grid alignment, league totals, rounded misses, overlapping OCR blocks and four-photo native regressions |
| `codex/testflight-0-1-10` | Build 11 packages, signing verification and owner/external TestFlight update |
| `codex/score-photo-corpus` | Twelve-photo native regression corpus, tilted grid calibration, bounded retries and physical delivery ordering |
| `codex/testflight-0-1-11` | Build 12 packages, distribution signing checks and owner/external TestFlight update |
| `codex/five-photo-evaluation` | Unchanged build-12 baseline on five more original scoreboards |
| `codex/focus-small-scoreboards` | Local context crops, sparse/stylized grids, colored ink and five-photo regressions |
| `codex/testflight-0-1-12` | Build 13 packages, signing checks and owner/external TestFlight update |
| `codex/oct31-practice-recognition` | Color-cast and outlined-glyph recovery, sparse ruling spacing, name/checkpoint binding and 102 native regression checks |
| `codex/samsung-owner-0-1-15` | Normal build 16 and verified in-place Samsung installation with unchanged journal, profile and draft |
| `codex/testflight-0-1-15` | Build 16 Apple packages, Mac payload readability guard, owner availability and external beta-review submission |
| `codex/android-image-export-audit` | Direct Android recap saves, export/audit hardening, build 17 packages and owner/external TestFlight assignments |

The completed stack is integrated into local `main` after verification. Feature branches are retained. All work is local until explicitly pushed to the remote repository.

## Architecture

- `lib/src/domain/`: portable data models and deterministic ten-pin scoring.
- `lib/src/data/`: SQLite storage, backup format, CSV/file export, bounded Photon adapter and offline ball catalog.
- `lib/src/recognition/`: device image acquisition, native recognition interface, conservative row parser.
- `lib/src/features/`: session recording, photo review, history, insights, inventories, maps, sharing, settings.
- `lib/src/ui/`: shared interface elements and forms.
- `lib/src/config.dart`: branding, website, User-Agent, development tile and Photon endpoints.
- `apple/ScoreTextRecognition.swift`: shared Apple Vision image decoding, geometry and bounded refinement.
- `macos/Runner/MainFlutterWindow.swift`: native channel and AVFoundation camera window.
- `ios/Runner/AppDelegate.swift`: Apple Vision channel registered with the Flutter engine.
- `android/app/src/main/kotlin/app/jws/tallybowl/MainActivity.kt`: bundled ML Kit recognition channel.

The iOS project targets iPad. Android and macOS are also generated targets; web, Windows, and Linux are outside this build's scope. The initial build toolchain is Flutter 3.47.5 / Dart 3.13.4 with Xcode 27 and the installed Android SDK.

## Recognition behavior and limits

The parser supports complete horizontal frame sequences and separate delivery/cumulative bands on regular ten-column grids. Native bridges return word bounds and Android symbol bounds in upright, EXIF-normalized coordinates. The shared Dart parser associates those bands with the bowler's name or aliases. It checks every available cumulative checkpoint and the scratch total against ordinary ten-pin scoring.

A unique matching row with a complete, consistent sequence opens the populated editor automatically. Two matching bowlers, missing marks, or conflicting totals require review. A bounded aspect correction and at most 20 frame crops improve condensed monitor fonts. For word-only Vision output, a contextual read can add non-overlapping observed marks. Known characters cannot be replaced by a disagreeing crop. A local horizontal-stroke detector can recover visible miss marks; cumulative totals never manufacture missing deliveries. Existing all-empty drafts with a retained photo reprocess on Resume while preserving lane, balls, primary ball and notes.

One permissioned real monitor photo now produces `53 63 9- 7/ 16 7- 35 6- 42 X9-`, cumulative checkpoints `8 17 26 37 44 51 59 65 71 90`, and total 90. This was exercised through bundled ML Kit on an isolated Android 17 emulator. The shared Apple Vision helper was exercised against the same EXIF-rotated photo, with the resulting native geometry verified through the Dart refinement pipeline. Anonymized geometry fixtures and workflow tests are committed; the source photo, device backups, and diagnostic targets remain only in ignored build output.

This is one real layout, not a broad accuracy result. Perspective, glare, low contrast, clipped frames, unsupported symbols, unusual name scripts, irregular grids and sparse strike-only displays can still need manual correction. During internal beta, expand the permissioned evaluation corpus and measure complete-game accuracy and correction effort by layout and platform before making broader accuracy claims.

Still to implement or expand:

- General grid/header detection, symbol detection, crop/perspective correction, and rotation controls.
- Multi-photo queues, combining photos of one game, import history, and stronger duplicate detection.
- Production-capacity map/search hosting and optional nearby search. Name-and-city suggestions now use the documented Photon API; saved alleys and manual entry remain available offline.
- Lane comparisons, more date filters, and more equipment comparison views.
- Optional retained evidence photos, ball photos, alley merging, and richer session editing.
- Production signing/distribution setup and physical TalkBack/VoiceOver evaluation. Automated 200% text, theme, contrast, semantics and 10,000-game checks now pass. Launcher icons use the committed pointing-bowler brand master.

## Persistence and portability

The database uses stable identifiers, foreign-key checks, and atomic incremental writes. Schema v2 adds explicit record positions and migrates v1 journals without changing their data. Serialized rows are compared before writing; a draft autosave leaves history tables untouched. The controller serializes writes so draft saves cannot overwrite newer game records, and the store advances its row cache only after commit. Reference validation uses indexed identifier lookups, and each persisted update validates once. Snapshot serialization still scales with journal size. The 10,000-game host benchmark observed draft updates fall from 245 ms to 76 ms after this optimization; this is not phone performance evidence. See AUDIT_RESOLUTION.md for measurements and reproduction.

A confirmed history game must contain a valid, complete ten-frame sequence. Unfinished frames are stored separately as a draft and excluded from statistics. Only one session can be in progress. Balls and alleys can be retired/archived without losing referenced history.

A JSON backup contains profile, inventories, sessions, games, and the unfinished frame draft. Source images and device file paths are excluded. Restore validates identifiers, references, frames, coordinates, weights, and draft ball selections before replacing anything. Settings saves a local `before-restore.json` recovery copy before applying a restore; the recovery action remains available after reopening the app. Restore currently replaces the journal rather than merging histories.

CSV exports are for analysis rather than restoration. One file contains game metadata and frame notation; the other contains individual deliveries including tenth-frame fill balls. User-entered text is quoted and protected from spreadsheet formula interpretation. Bowling date and original UTC offset are preserved.

## Data and network behavior

Scoreboard recognition is local. Apple uses Vision; Android links `com.google.mlkit:text-recognition:16.0.1` rather than the downloadable Play Services model. No app code sends photos or extracted scores to an AI service. Google ML Kit may send SDK diagnostic metadata; see the disclosure in Settings and DATA_SOURCES.md. Bundled inference does not imply that the SDK is network-silent.

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

## Verified build 0.1.6 (7) branding results

- `flutter analyze`: no issues. `flutter test`: 103 passed, including large-text light/dark navigation and editor layouts, theme-invariant recap rendering, actual PNG export and privacy behavior.
- The committed bowler master was inspected at 128-pixel Mac icon size and in the recap golden. A synthetic live Mac preview rendered the production shell side by side in light and dark themes; the new mark and three-hole navigation symbol were visually checked in both. The optional form-preview integration runner stalled before its branding stage on a rerun, so it is not counted as passed; the isolated live preview was used for visual verification.
- All configured iPad, Mac and Android launcher sizes are regenerated from the same committed master. No image generation API, new network dependency or cloud AI feature was added to the app.
- `tool/verify_native.sh` passed: normal Android debug, universal Mac release, iPad simulator debug and Android Lint (0 errors, 10 existing/style advisories). Package versions, signatures, normal entry points and the exact bundled master PNG were verified.
- Installed version 0.1.6/build 7 on the Samsung and this Mac. The installed Mac header and My Bag navigation/empty state were visually checked. Before/after database comparisons verified all records, profile and draft unchanged on both devices; Samsung retained 3 alleys, 2 balls, 1 session and its unsaved complete photo draft. The previous Mac bundle and private safety snapshots are retained in ignored build output.


## Verified build 0.1.5 (6) results

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 103 passed, including real monitor geometry on both OCR pipelines, disagreeing crop preservation, ambiguous aliases, intermediate checkpoint conflicts, automatic frame entry, legacy draft metadata retention and actual PNG MIME/dimensions |
| Native builds | Android debug and Lint, universal macOS release and iPad simulator debug passed. A follow-up Android build/Lint passed with AndroidX EXIF 1.4.2 for consistent orientation/format support across Android versions |
| Native Lint | 0 errors, 10 warnings: existing build/resource/icon advisories and three bitmap extension-style suggestions remain |
| Real Samsung photo | Android 17 / SM_F971U1: Resume reprocessed the retained draft to all ten correct frames, total 90, and enabled Save. Alleys (3), balls (2), session (1), profile and history were unchanged; lane/notes/ball tags/primary ball/source path were preserved. No game was saved by this verification |
| AeroSloth handoff | Native share sheet copied an identical PNG to AeroSloth and its normal composer displayed the image attachment. No post or message sent; see SHARING_VERIFICATION.md |
| Owner installation | Normal 0.1.5/build 6 Android APK installed in place. Mac owner package signature/policy verified, installed to `/Applications/TallyBowl!.app`, and launched. Prior bundle retained in ignored build output |

The original photo and read-only device safety snapshots remain private ignored build output. One real scoreboard example is regression evidence, not general recognition accuracy or comprehensive physical camera/accessibility coverage. New captures, additional layouts, iPad hardware and recipient-specific sending remain owner testing tasks.

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

The launcher icons and in-app identity use `assets/branding/tallybowl-logo.png`, the committed pointing-bowler master. Its dark teal badge keeps the cream figure and orange bowling ball legible in both themes. Source and generation prompt are documented in [branding notes](../assets/branding/README.md). `BowlingBallIcon` supplies the three-hole My Bag symbol; ball illustrations have no seam.

Regenerate every configured icon size on macOS:

```sh
swift tool/generate_icons.swift
```

The generator uses Core Graphics/ImageIO, writes an inset rounded tile with transparent margins for macOS, and opaque iPad/Android icons. The source PNG is bundled by Flutter and reused in phone/desktop navigation, Settings and recap headers. Recap export awaits image decoding before capturing its PNG. The golden check verifies the recap remains identical across app themes and text sizes.

`integration_test/suggestions_preview_test.dart` renders native form, dashboard/theme and launcher previews to the app cache and prints their paths. Rebuild the normal `lib/main.dart` target after integration tests before packaging an app for installation. Run `./tool/package_macos_local.sh` after the Mac release build.


## Install the local test build

All three owner devices have version **0.1.7 (8)**. These packages are generated locally and ignored by Git:

| Target | Local package | Installation |
| --- | --- | --- |
| macOS | `build/releases/TallyBowl-0.1.7-macos-OWNER-TEST-ONLY.zip` | Installed in Applications and launched. The app is a universal Intel/Apple silicon release build with an ad hoc signature and an explicit local library-validation exception; it is not a notarized distribution. |
| Android | `build/releases/TallyBowl-0.1.7-android-debug.apk` | Installed over 0.1.6 (7) and launched on the Samsung. This uses the existing local development key. Production releases use explicit protected key properties; missing credentials stop release builds. |
| iPad simulator | `build/ios/iphonesimulator/Runner.app` | Run `flutter run -d <simulator-id>` or install this app through the simulator tools. A simulator binary cannot be installed on a physical iPad. |
| Physical iPad | `build/ios/iphoneos/Runner.app` | Development-signed 0.1.7 (8), installed over 0.1.4 (5) and launched on the owner's connected iPad. |

For a physical iPad owner build, use the existing development signing setup in the iOS Runner project and build the normal `lib/main.dart` release target, then install with `devicectl` (or use `flutter run` for development). The current owner build is 0.1.7 (8); before/after comparisons confirmed the existing three alleys, two balls and profile/draft were unchanged. A separate TestFlight distribution IPA was subsequently exported and uploaded successfully on October 25, 2026. Follow the separate [Apple runbook](TESTFLIGHT.md) for that path.

The strict release build enables hardened runtime and disables Xcode's injected `get-task-allow`. Ad hoc apps/frameworks have no Team ID: the strict build failed the runtime library check during smoke launch. `tool/package_macos_local.sh` therefore signs a **copy** with only the local `disable-library-validation` exception, retaining sandbox/runtime protections and no JIT/debug entitlement. It refuses to change a team-signed app. The archive filename includes `OWNER-TEST-ONLY`; a signed/sealed `Contents/Resources/TallyBowlBuild.json` records its version, build, non-distribution warning and exact signing/runtime policy. Production entitlements retain library validation. TestFlight/App Store distribution requires its own correct signing and Apple validation; a separate direct Mac download would use Developer ID signing and notarization.

`build/releases/checksums-0.1.7.json` records the Mac/Android package hashes and source revisions, owner-only policy and iPad development-install identity. `build/releases/checksums.json` retains the prior 0.1.6 Mac/Android package record. Current owner packages use the normal `lib/main.dart` entry point. Package signatures/versions and the private before/after journal comparisons were verified; previous smoke-launch evidence is labeled by build above.

Start by adding a profile, a searched or manual alley, and balls from suggestions or custom names. Record a manual game, then try a real scoreboard photo and compare every frame. Finish the session, inspect the branded recap and try a share destination. Export a JSON backup before experimenting with restore. Physical camera/share workflows, Android picker process recovery, TalkBack/VoiceOver and representative scoreboard recognition are the key remaining device checks. See [review findings](REVIEW.md) for the full record.
