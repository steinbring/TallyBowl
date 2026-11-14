# Local recognition training lab

This is development tooling, outside `lib/` and app assets. It runs the real
`PhotoService`, frame reader, parser and scorer with either the production shared
Apple Vision helper or bundled Android ML Kit. It is not a fine-tuning API for
those SDKs. It can train a candidate for our shared glyph fallback and evaluate
future layout/segmentation changes without changing the installed app.

All photos, human labels, native OCR text, experimental templates and detailed
logs belong under ignored `build/recognition-lab/`. No cloud service is used.
Do not add downloaded scoreboards, private names or EXIF to app assets or Git.
The latest combined corpus is
`build/recognition-lab/league-practice-nov13/corpus.json` (113 cases, 64 originals).
It includes all 104 prior cases (including the previously inspected holdout),
eight finished-game views from the new photos, and one partial game. The nine
new rows are frozen separately in `league-practice-nov13/new.json`. See
[the November 13 recovery](../../docs/NOV13_PHOTO_EVALUATION.md).

The preceding combined corpus is `build/recognition-lab/online-nov09/corpus.json`
(98 cases, 53 originals). It adds four fresh online sources to the November 8
corpus, including six Baker/team-game negative rows. The independently labeled
first evaluation is frozen separately as `online-nov09/new.json`; after inspecting
results, those cases are regression data, not a future unseen test. See
[the November 9 check](../../docs/NOV09_RECOGNITION_CHECK.md) and
[the November 8 results](../../docs/NOV08_PHOTO_EVALUATION.md).
The prior manifest remains at `build/recognition-lab/practice-nov08/corpus.json`
(88 cases, 49 originals), including both rows in the four November 8 photos,
the three November 7 practice photos and the eight Google Images sources in
[the benchmark record](../../docs/GOOGLE_IMAGES_EVALUATION.md).
All inspected photos are protected regression data.
The prior 80-case manifest remains at `build/recognition-lab/practice-nov07/corpus.json`.
The earlier manifests remain at `build/recognition-lab/corpus-expanded.json`
(77 cases/42 photos) and `build/recognition-lab/corpus.json` (51 cases/34 photos)
to reproduce their historical reports. The previously inspected six-row/two-photo
holdout is also rerun as a regression check; it is not a new unseen evaluation.

## Dataset rules

A private manifest has `schema: 1`, `heldOutFamilies: []` and `cases` like:

```json
{
  "id": "r001",
  "path": "build/recognition-lab/originals/example.jpg",
  "sha256": "SHA256_OF_ORIGINAL_BYTES",
  "family": "vendor-layout-1",
  "group": "capture-session-1",
  "split": "regression",
  "status": "complete",
  "profile": {"name": "Bowler", "aliases": []},
  "frames": ["9-", "9-", "9-", "9-", "9-", "9-", "9-", "9-", "9-", "9-"],
  "cumulative": [9, 18, 27, 36, 45, 54, 63, 72, 81, 90]
}
```

Use `train`, `validation`, `test` or `regression`. Split whole capture sessions
and related views **before** cropping or augmentation. Identical photo hashes
and capture groups cannot cross splits. Families listed in `heldOutFamilies`
must occur only in `test`. New lockbox families should remain uninspected until
the candidate is frozen; after examining failures, move them to regression and
collect new lockbox data. Current corpus validation does not establish unseen
layout performance.

Transcribe visible deliveries and every available checkpoint independently of
the engine. For `complete` rows the production ten-pin scorer must agree with
all ten checkpoints. Use `incomplete`, `conflict` or `unsupported` for negative
cases, and `unidentified` when a source redacts the bowler's identity even though
all frames are visible. These must never become automatic imports. Include multiple players,
split rings, misses, strikes/spares, tenth-frame fills, handicaps, angled views,
colored backgrounds, tiny fonts and unrelated adjacent screens. Do not infer
missing deliveries from a matching total.

```sh
python3 tool/recognition_lab/lab.py validate build/recognition-lab/league-practice-nov13/corpus.json
python3 -m unittest discover -s tool/recognition_lab -p test_lab.py
```

## Train an isolated prototype candidate

```sh
python3 -m venv build/recognition-lab/venv
build/recognition-lab/venv/bin/pip install -r tool/recognition_lab/requirements.txt
build/recognition-lab/venv/bin/python -m unittest discover -s tool/recognition_lab -p test_training.py
build/recognition-lab/venv/bin/python tool/recognition_lab/train_templates.py \
  build/recognition-lab/font-catalog.json \
  --output build/recognition-lab/candidate-new.json \
  --report build/recognition-lab/glyph-metrics-new.json
```

The catalog has a `sources` array. Every source has `path`, `sha256`, `family`,
`group` and `split` (`train`/`validation`/`test`). A `kind: "font"` source also
needs `license` and `source` provenance, and may specify `weights` and
`characters`. A `kind: "mask"` source needs a human-confirmed single-character
`label` from `0123456789X/` and a tight foreground mask (white ink, black
background). For masks, use the original photo's capture group and layout family;
for fonts use the font family. No family/group/source hash crosses splits.
Masks need independent labels, never predictions or score-derived labels.

Training appends deduplicated prototypes from **training sources only**, with
small stroke variations, capped at 512 templates. Held-out glyph evaluation
includes scale, blur, JPEG compression and slant. It uses the current .68 IoU /
.06 lead rule, without native corroboration. This glyph-only simulation omits
segmentation, native OCR and scoring and cannot establish whole-photo accuracy.
The glyph gate requires zero accepted wrong glyphs and no lost baseline-correct
glyphs in validation/test. Output paths are restricted to the ignored lab folder,
existing outputs are never overwritten, and production templates are not written.

## Evaluate both native engines

Compile a fresh Apple helper from the current production source:

```sh
xcrun swiftc -O apple/ScoreTextRecognition.swift \
  tool/recognition_lab/vision_probe.swift -o build/recognition-lab/vision-probe
```

For Android, start a disposable emulator (not a phone), build the current debug
app and instrumentation APK, install both to an explicitly selected emulator,
then start the worker in a separate terminal. Do not run multiple Flutter/Gradle
builds concurrently in the same checkout; native asset generation shares files.

```sh
flutter build apk --debug
(cd android && ./gradlew app:assembleDebugAndroidTest)
adb -s emulator-5554 shell getprop ro.kernel.qemu  # must be 1
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s emulator-5554 shell am instrument -w -r \
  -e class app.jws.tallybowl.RecognitionLabTest -e recognitionLab true \
  app.jws.tallybowl.test/androidx.test.runner.AndroidJUnitRunner
```

The instrumentation worker is skipped in normal native tests, requires emulator
hardware and stops after 30 minutes. The Python adapter also requires an
`emulator-*` serial and `ro.kernel.qemu=1`. Worker files live in app-private cache;
photos are addressed and verified by SHA-256. Shut down the disposable emulator
when finished. Neither the worker nor CLI is in a production app package.

Run these **sequentially**, once for `apple` and once for `android`:

```sh
flutter test --no-pub tool/recognition_lab/evaluate_test.dart \
  --dart-define=LAB_MANIFEST=build/recognition-lab/league-practice-nov13/corpus.json \
  --dart-define=LAB_ENGINE=apple \
  --dart-define=LAB_OUTPUT=build/recognition-lab/next-trial/apple-baseline.json

flutter test --no-pub tool/recognition_lab/evaluate_test.dart \
  --dart-define=LAB_MANIFEST=build/recognition-lab/league-practice-nov13/corpus.json \
  --dart-define=LAB_ENGINE=apple \
  --dart-define=LAB_OUTPUT=build/recognition-lab/next-trial/apple-candidate.json \
  --dart-define=LAB_TEMPLATES=build/recognition-lab/candidate-new.json
```

Use a fresh Flutter test process for each bank (production caches templates).
`LAB_TEMPLATES` intercepts the test asset messenger only; there is no production
override. Optional `LAB_SERIAL` selects another emulator and `LAB_CACHE` selects
another private cache directory. The cache key includes original bytes, engine,
native source/binary or dependency/runtime fingerprint and **exact request
geometry/aspect/context**. A changed crop gets fresh OCR. Old caches keyed only
by call number or `regional` must not be used. If changing the native helper or
OS, rebuild/reinstall it and record fresh paired baselines. Android runs require
the installed app to match the evaluated source; the adapter cannot prove that
the developer installed the correct APK. Apple measurements on macOS share the
iPad helper but do not substitute for installed iPadOS/device capture checks.

## Promotion gate

```sh
python3 tool/recognition_lab/lab.py gate \
  build/recognition-lab/next-trial/apple-baseline.json build/recognition-lab/next-trial/apple-candidate.json \
  build/recognition-lab/next-trial/android-baseline.json build/recognition-lab/next-trial/android-candidate.json
```

Both reports must be complete, cover the same labeled originals and production
pipeline, and have no native failures. For an intentional Dart layout/segmentation
change, use `gate --allow-pipeline-change`; this allows different recorded Dart
source hashes, while retaining every other safety requirement. Native helper/SDK
changes require a new paired baseline. Every previously exact row must remain
exact, including all ten frames and scratch total. Every automatic candidate is
inspected, even if multiple conflicting candidates prevent final selection.
Incorrect automatic imports and more than four native calls fail the gate.
An aggregate gain cannot compensate for a single regression. Both engines must
be safe and at least one must improve. A native timeout swallowed by the app's
normal retry is still an evaluation error. Reports contain opaque IDs and
metrics; OCR text and names stay in private `.work`/cache files.

Passing this photo gate is necessary, not sufficient: also require the glyph
gate, fresh held-out layout families, the committed Flutter suite, native checks,
latency on real devices and installed Android/iPad/macOS smoke tests. Only then
consider a separately reviewed production template/layout change. The November
4 prototype failed this process and is not shipped; see
[the evaluation record](../../docs/RECOGNITION_TRAINING.md).
