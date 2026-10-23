# TallyBowl!

**How you bowled, tonight.**

A Flutter bowling journal for macOS, iPadOS, and Android. Its website will be [tallybowl.jws.app](https://tallybowl.jws.app).

This first development build includes:

- A personal profile with scoreboard names and aliases.
- Ball inventory and saved alleys, including OpenStreetMap pin selection with `flutter_map`.
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

## Development maps

The development map uses OpenStreetMap's public raster tiles with attribution, an identifying User-Agent, HTTP caching, and no offscreen prefetch buffer. Select production map/search hosting before release. A different OSM-compatible tile service can be supplied using `--dart-define=TALLYBOWL_TILE_URL=...`; adjust attribution for that provider's requirements. The current picker supports map pins and manual alley details, without an online place directory.
