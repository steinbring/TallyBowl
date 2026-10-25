# Architecture and maintenance

Updated October 25, 2026. Targets: native macOS 12+, iPadOS 15+ (iPad only), Android 24+. Verify effective minimums in the built products when dependencies/toolchains change. The project uses Flutter 3.47.5 / Dart 3.13.4, Swift Apple bridges and Kotlin Android bridges. There is no backend.

## Boundaries and data flow

| Area | Source and responsibility |
| --- | --- |
| Entry/startup | `lib/main.dart`, `src/app.dart`, `src/config.dart`: normal app entry, recover startup/draft state, nonblocking versioned network identification |
| Journal mutations | `src/app_controller.dart`: serialized writes, photo-acquisition reservation, validated snapshots and UI notifications |
| Domain | `src/domain/models.dart`, `scoring.dart`, `journal_index.dart`: records, relationships, pure ten-pin scoring, cached history/statistics indices |
| Storage | `src/data/bowl_store.dart`: SQLite transactions and schema migration; `exports.dart`: bounded portable backup, CSV, share/save and recovery copy |
| Photo acquisition | `src/recognition/photo_service.dart`: camera/gallery/files, private hashed imports, method-channel recognition, cleanup and picker recovery |
| Recognition/parsing | `src/recognition/recognized_text.dart`, `scoreboard_grid.dart`, `score_parser.dart`: geometry, candidates, marks and score-checkpoint validation |
| Native recognition | `apple/ScoreTextRecognition.swift` shared by Apple targets, Apple app delegates/camera code; Android `MainActivity.kt`: bundled ML Kit and image preprocessing |
| UI | `src/features/` and `src/ui/`: journal, inventory, insights, editors, dialogs, adaptive layout and branded recap |
| External services | `src/data/place_search.dart`, map widgets, `src/config.dart`: explicit Photon queries and OSM tiles; configurable providers |
| Branding/documents | `assets/branding/`, `src/ui/branding.dart`, `assets/documents/`: committed logo and offline JSON help/policy; Markdown rendered by `tool/render_documents.py` |

Flow: acquire one image → retain privately with draft → local OCR/geometry refinement → select/validate bowler and frames → populate reviewable editor → save validated game → compute journal statistics/recap. Cumulative totals are constraints, never a source for invented delivery values. A complete consistent sequence with a unique alias match can skip the row-picker screen, but the resulting editor is still reviewable. Never treat final-total equality alone as a proof of frame accuracy.

## Persistence and recovery contract

The application-support directory holds `tallybowl.db`. SQLite schema **2** stores ordered JSON documents in `balls`, `alleys`, `sessions`, `games`, with profile/draft in `settings`. Foreign keys link sessions to alleys and games to sessions; model validation checks other relationships and game legality. Version 1→2 adds stable record ordering. Changed rows are saved transactionally; a failed write does not advance the in-memory snapshot/cache. BowlStore owns writes on its connection; independent/external writers are unsupported.

Controller updates run through a single pending queue. Photo acquisition reserves its session before a nonmodal desktop camera or external picker can outlive the initiating screen. Don’t bypass this reservation with new restore/delete flows. Restart recovery and orphan cleanup share the reservation so they cannot erase a concurrently retained import.

Private source images live in the application-support imports directory while a draft needs them. Saving/discarding removes them, and startup cleans orphans. JSON backups omit source paths/photos but retain unfinished frame fields. Import accepts a versioned TallyBowl backup after bounded decoding and full relationship/score validation. Restore replaces the entire journal and keeps `before-restore.json` as one recovery snapshot. CSV is spreadsheet-safe analysis output, not a restore format. Limits are currently 40 MiB for an imported photo and 100 MiB for JSON; preserve streamed size checks as well as initial metadata checks.

When modifying a model, update JSON serialization, validation, backup compatibility and every derived metric together. Keep stable IDs for edits/retirement. For a schema change, add an explicit migration and verify an old database fixture plus backup round trip. A data-loss failure blocks beta expansion. Back up real owner data before distribution-channel changes; tests use isolated data.

## Privacy and network boundaries

App-controlled network requests are map tiles and explicit Photon searches, plus opening a user-selected external link. Photos/extracted frames never go to a cloud recognition endpoint. Android's bundled Google ML Kit can send its own diagnostics; Apple Vision builds do not include that Android SDK. No advertising, account or developer analytics SDK is present. OS/TestFlight diagnostics and OS backups are separate from app journal sync.

Map providers see IP/request metadata and viewed tile coordinates; Photon sees query text. No GPS permission or nearby-location search is implemented. Use HTTPS endpoints, bounded/timeout-controlled query responses, visible provider attribution, identifying versioned User-Agent, tile caching and no bulk/offline prefetch. Provider changes require policy and App Store privacy review; do not infer “Data Not Collected” from on-device OCR alone.

Both Apple Runner targets bundle their own `PrivacyInfo.xcprivacy`. File metadata reasons are **C617.1** for private-container reads/export cleanup and **3B52.1** for user-granted selected-file metadata. Third-party frameworks supply their own manifests where provided; inspect the final archive's aggregated privacy report after dependency changes. This manifest is a required-reason API declaration, not a substitute for store privacy labels or a legal policy.

Crypto inventory: HTTPS in Dart/Flutter networking (not all necessarily OS URLSession), and SHA-256 for local photo filenames. There is no app-level journal encryption, proprietary cipher, VPN or encrypted messaging. Complete Apple's export questionnaire against the final dependency graph. `ITSAppUsesNonExemptEncryption` is intentionally unset until that decision; don't declare that all networking is OS-provided merely to bypass the question.

## Sharing and native distribution

Recaps render a locally decoded logo and scorecard to a 1080-pixel-wide PNG. The same preview privacy toggles govern rendered content; hiding the date also changes the attachment name. Sharing passes a real `image/png` file to the platform sheet and supplies an iPad popover anchor. Temp files stay under a private export directory and older files are pruned during a subsequent export. Recipients receive only what the user chooses to send; TallyBowl does not log into or post to social accounts.

Release macOS entitlements retain sandbox, camera, selected-file access and outbound networking, hardened runtime, no injected debugger entitlement, and normal library validation. `tool/package_macos_local.sh` changes a **copy** for ad hoc owner testing and embeds a sealed non-distribution marker; it must never become the TestFlight packaging path. See [Apple release runbook](TESTFLIGHT.md) and [Android signing](ANDROID_SIGNING.md). Keep keys, profiles with private material, passwords, owner snapshots and actual scoreboard photos out of Git.

## Verification and changing behavior

Run `flutter analyze`, `flutter test`, generated-document consistency and `tool/testflight_preflight.py`. Use `tool/verify_native.sh` for Kotlin/Swift compilation and Android Lint. Native recognition tests cover bridges separately from Dart parser fixtures. Run only normal `lib/main.dart` release builds for distribution; integration-test entry points can install test harnesses under the same bundle ID.

Before changing recognition, reproduce with a permissioned fixture and independently written expected deliveries. Remove personal names/photos from committed fixtures; ignored `build/` is temporary private working output. Keep held-out evaluation photos separate from parser-tuning examples. A correct total is insufficient. See [device acceptance](DEVICE_TESTING.md) for camera, permissions, app interruption, native sharing, accessibility and recovery checks that widget tests cannot prove.

The app loads history into memory and indexes/paginates its presentation. It is not a server database with unbounded streaming. The optional 10,000-game benchmark records observations without brittle machine-dependent timing assertions. Reassess memory/startup costs if beta journals grow substantially.

Generated icons come from `swift tool/generate_icons.swift` and the committed master asset; preserve licensing/source notes. Generated Markdown comes from `python3 tool/render_documents.py`. TestFlight build numbers must increase for new uploads; keep candidate, uploaded, and installed versions clearly distinguished in release evidence.
