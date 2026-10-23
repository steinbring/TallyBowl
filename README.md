# TallyBowl!

**How you bowled, tonight.**

A Flutter bowling journal for macOS, iPadOS, and Android. Its website will be [tallybowl.jws.app](https://tallybowl.jws.app).

Development build 0.1.1 (2) includes:

- A personal profile with scoreboard names and aliases.
- Ball inventory with an offline manufacturer/model starter catalog and custom entries.
- Saved alleys with key-free Photon/OpenStreetMap name-and-city suggestions, manual entry, and map pin selection with `flutter_map`.
- League/practice sessions, per-game lanes, ball tags, and an optional primary ball.
- An editable ten-pin frame grid with deterministic scoring, tenth-frame validation, and recoverable drafts.
- Camera/photo import with local Apple Vision or bundled Android ML Kit recognition, explicit row selection, and manual correction.
- History, scoring trends, ball usage, alley visits, strike rates, and spare conversion statistics.
- Branded session recap images and native image sharing.
- Local SQLite storage, versioned JSON backup/restore with a recovery copy, and game/delivery CSV export.

Recognition is a prototype for clear horizontal score rows. Real scoreboard layout coverage and camera behavior still need representative photo and physical-device testing. No cloud AI fallback is implemented. See [development status](docs/DEVELOPMENT.md) for limits and verification details, and the [project roadmap](docs/ROADMAP.md) for the wider release plan.

## Run

From the project folder, with Flutter and the target platform toolchain installed:

```sh
flutter pub get
flutter run -d macos
```

Use `flutter devices` to find an iPad simulator/device or Android target, then `flutter run -d <device-id>`.

## Check

```sh
flutter analyze
flutter test
flutter test integration_test/on_device_recognition_test.dart -d macos
```

The native integration test generates its own synthetic image, exercises on-device recognition, and renders a branded recap PNG. It does not access the camera or user photos.

## Maps and suggestions

The development map uses OpenStreetMap's public raster tiles with attribution, an identifying User-Agent, HTTP caching, and no offscreen prefetch buffer. Select production map/search hosting before release. A different OSM-compatible tile service can be supplied using `--dart-define=TALLYBOWL_TILE_URL=...`; adjust attribution for that provider's requirements. Alley suggestions use the documented Photon API and require neither a key nor screen scraping. Searches are submitted explicitly; the app caches queries and handles service limits. Configure another Photon endpoint with `--dart-define=TALLYBOWL_PHOTON_URL=https://your-host/api/`.


The ball starter catalog is bundled and works offline. It contains 11 brands and 22 selected model names, plus previously entered models; it accepts any custom entry. A suitable documented, key-free public ball API was not found. See [data sources and service policies](docs/DATA_SOURCES.md) and the [pre-test review](docs/REVIEW.md).

## Try this build

On this Mac, run `flutter run -d macos`. Local packaged builds and installation notes are listed in [development status](docs/DEVELOPMENT.md). Physical iPad installation requires Apple development signing; a simulator build cannot be installed on an iPad.
