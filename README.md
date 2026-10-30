# TallyBowl!

**How you bowled, tonight.** A Flutter bowling journal for native macOS, iPadOS, and Android. Planned website: [tallybowl.jws.app](https://tallybowl.jws.app).

The current beta is **0.1.13 (14)**, developed and published by **Joe Steinbring**. [Contact Joe for support](https://jws.dev/contact). It improves mixed-script OCR name matching and delivery ink obscured by bright grid borders. Previous personal-photo results are preserved, but the unfamiliar online scoreboards still expose substantial recognition gaps; see [the measured results](docs/ONLINE_PHOTO_EVALUATION.md). Both Apple builds are available in owner TestFlight and waiting for external beta review. The normal Android update is installed on the Samsung. [TestFlight readiness](docs/TESTFLIGHT.md) records distribution status and remaining device checks.

## What works

- One bowler with scoreboard name/nickname aliases; standard ten-pin scratch scoring.
- An offline ball catalog, unrestricted custom entries, and retiring inventory while retaining history. The next build adds all 50 Brunswick and 13 Radical models in their official Current listings checked October 30, 2026, plus optional basic ball colors shown in My Bag and retained in backups.
- Saved alleys with explicit key-free Photon/OpenStreetMap suggestions, manual entry, and `flutter_map` pin selection.
- Practice/league sessions, date and lane/pair, per-game ball tags, optional primary ball, and notes.
- Camera/photo import with on-device Apple Vision or bundled Android ML Kit; geometry-based frame parsing, editable frames, deterministic scoring, and recoverable drafts.
- Automatic frame filling for a unique matching row only when the complete delivery sequence validates against available cumulative checkpoints. Ambiguous results open review; missing deliveries are never invented from totals.
- Session deletion with confirmation, cascading games/draft removal, and transactional failure recovery.
- History and statistics with sample counts, alley visits, ball usage, strike/spare rates, and scoring trends.
- Branded PNG recaps, privacy switches, native image sharing and export.
- Local SQLite storage, versioned JSON backups with before-restore recovery, and game/delivery CSV exports.
- System light/dark appearance, scalable layouts, accessible scorecard labels, offline help/privacy pages, and installed version/build in Settings.
- Settings links to TallyBowl!'s [Bluesky](https://bsky.app/profile/tallybowl.jws.app) and [GoToSocial](https://jws.social/@tallybowl) profiles (added after build 14; included in the next build).

There is no cloud AI fallback, account, automatic sync, or iPhone target. Real-photo regression coverage includes the [twelve-photo evaluation](docs/PHOTO_CORPUS_RESULTS.md) alongside the earlier monitor examples. All four original October 27 league photos remain exact through local Apple Vision and Android ML Kit. Always compare every delivery before saving. Multi-photo combining, crop/rotation tools, handicap scoring, and per-delivery ball assignment are deferred. Android ML Kit may send SDK diagnostics to Google; map/search providers receive requests. See the [privacy policy](docs/PRIVACY_POLICY.md).

## Documentation

| Need | Document |
| --- | --- |
| Learn recording, sharing, backup and recovery | [User guide](docs/USER_GUIDE.md), also available offline in Settings |
| Prepare an Apple beta and understand remaining gates | [TestFlight readiness and release runbook](docs/TESTFLIGHT.md) |
| Fill in beta/reviewer information | [TestFlight metadata](docs/TESTFLIGHT_METADATA.md) |
| Understand architecture and change it safely | [Architecture and maintenance](docs/ARCHITECTURE.md) |
| Investigate score-photo recognition | [Shared frame recognition](docs/FRAME_RECOGNITION.md) |
| Verify Android image handoff | [Android sharing](docs/ANDROID_SHARING.md) |
| Verify hardware workflows | [Device testing](docs/DEVICE_TESTING.md) |
| Understand scope and what comes next | [Roadmap](docs/ROADMAP.md) |
| Review service policies and attribution | [Data sources](docs/DATA_SOURCES.md) |
| Inspect previous implementation/test evidence | [Development history](docs/DEVELOPMENT.md), [share handoff](docs/SHARING_VERIFICATION.md) |
| Prepare Android store signing | [Android signing](docs/ANDROID_SIGNING.md) |

Audit dispositions are in `docs/AUDIT_RESOLUTION.md`, `docs/AUDIT_ROUND2_RESOLUTION.md`, [round-three verification](docs/AUDIT_ROUND3_RESOLUTION.md), and `docs/REVIEW.md`. Their test counts and build numbers describe those revisions.

## Develop and verify

Use Flutter **3.47.5+**, Dart **3.13.4+**, Xcode 27 for Apple targets, and the Android SDK. Commit `pubspec.lock`; review upgrades deliberately.

```sh
flutter pub get
flutter run -d macos
flutter analyze
flutter test
python3 tool/render_documents.py --check
python3 tool/testflight_preflight.py
```

Use `flutter devices` then `flutter run -d <device-id>` for another target. Native bridge checks are separate from Dart tests:

```sh
./tool/verify_native.sh
flutter test integration_test/on_device_recognition_test.dart -d macos
```

The native integration test uses a synthetic scoreboard and exports a recap; it does not establish real camera accuracy. `integration_test/suggestions_preview_test.dart` is an optional visual harness; a recent rerun stalled in native focus/foreground handling and is not part of the release acceptance evidence. The optional large-journal benchmark is `flutter test benchmark/journal_benchmark.dart` and writes ignored `build/benchmarks/journal.json`.

App help and privacy Markdown are generated from the same bundled JSON shown in Settings. Edit `assets/documents/*.json`, then run `python3 tool/render_documents.py`. Do not edit their generated Markdown copies directly.

## Services and distribution

No API key or scraping is used for alley suggestions. Public OSM tiles and the Photon demo are suitable only while usage complies with their policies; they have no availability guarantee. Manual alley entry and saved alleys remain usable offline. Before expanding the beta, review capacity, provider retention/privacy, attribution and any necessary hosting change. Configuration uses `--dart-define=TALLYBOWL_TILE_URL=...`, `TALLYBOWL_TILE_ATTRIBUTION`, `TALLYBOWL_TILE_ATTRIBUTION_URL`, and `TALLYBOWL_PHOTON_URL`. Update the privacy policy whenever providers change.

For local owner testing, Android debug builds use the existing development key. A Mac build packaged with `tool/package_macos_local.sh` is explicitly **OWNER-TEST-ONLY**, ad hoc signed with a local library-validation exception. It is unsuitable for TestFlight. Apple beta distribution uses separately archived and App Store Connect signed products described in the [runbook](docs/TESTFLIGHT.md). Preserve JSON backups before changing signing/distribution channels; never uninstall a populated app automatically to bypass a signing error.
