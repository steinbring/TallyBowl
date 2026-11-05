# Recognition training and regression protection — November 4, 2026

The practical route is to train the part we control: the shared frame glyph
reader, followed by layout/segmentation improvements measured against complete
scoreboards. Keep Apple Vision and Android ML Kit as independent observations
and retain the existing identity, legal-frame, scratch-total and checkpoint
checks. Their public APIs expose recognition configuration rather than an
app-specific OCR-weight training interface. Apple's custom word list supplements
language correction; it is ignored with `usesLanguageCorrection=false`, which
TallyBowl deliberately uses for delivery marks. This makes a word-list change an
unsuitable substitute for scoreboard training. See the official
[Apple request](https://developer.apple.com/documentation/vision/vnrecognizetextrequest),
[custom-word behavior](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/customwords)
and [ML Kit options](https://developers.google.com/android/reference/com/google/mlkit/vision/text/latin/TextRecognizerOptions.Builder).

## Implemented

The [local training lab](../tool/recognition_lab/README.md) provides:

- A hashed original-photo manifest with capture groups, layout families,
  train/validation/test/regression splits, and explicit complete, incomplete,
  conflicting and unsupported gold labels. Duplicate photos and capture groups
  cannot cross splits; declared held-out layout families stay out of training.
- Supervised prototype expansion using licensed fonts or independently labeled
  foreground masks, with bounded template count and separate synthetic scale,
  blur, compression and slant evaluations. Training uses only the training split.
- A fresh Apple CLI compiled with the production shared iPad/macOS helper, and
  an opt-in Android instrumentation worker using the production bundled ML Kit
  helper on an emulator. The Flutter evaluator executes the actual retries,
  pixel fallback, parser and scorer on original bytes.
- Exact-request caching, including photo bytes, native/runtime fingerprint,
  regions, aspect and context. A geometry change cannot reuse a stale regional
  reading. Native failures remain failures even when production retry handling
  would normally fall back to review.
- A paired gate for **both** engines: preserve each previous exact import,
  inspect every automatic candidate, accept zero wrong automatic results, and
  retain the four-call bound. Missing/partial reports cannot pass. At least one
  engine needs a gain and neither may regress; a total-only match is insufficient.

Experiments stay under ignored `build/recognition-lab/`, with no production
override or automatic template replacement. The new Android worker exists only
in the instrumentation test APK. No original photos, private names, native OCR
logs, font files or candidates are added to the app or Git.

## First experiment

The existing bank has 78 templates. The candidate expands it to 222 using
Roboto Mono and Barlow Condensed, with small stroke variations. Roboto Slab
provides 216 validation glyph samples; the incumbent already includes its numeral
1, so this validation family is not wholly unseen to the incumbent. Oswald,
excluded from candidate training, provides another 216 test samples. This is a
prototype-training pilot, not a neural OCR fine-tune.

| Glyph set | Existing correct / wrong / rejected | Candidate correct / wrong / rejected | Existing correct glyphs lost |
| --- | --- | --- | --- |
| Validation, 216 | 209 / 0 / 7 | 208 / 0 / 8 | 1 |
| Held-out Oswald, 216 | 154 / 2 / 60 | 157 / 3 / 56 | 11 |

The small test accuracy gain hides regressions and more confident mistakes,
including 7 read as `/`. **The glyph gate rejects this candidate.** These are
isolated foreground-glyph classifications with the existing .68 IoU / .06 lead
rule, without native corroboration. They are not counts of incorrect game imports.
This experiment demonstrates why blindly appending fonts is insufficient even
when known scoreboard photos continue to pass.

The corpus contains 34 original photos and 51 bowler-row cases per engine: 41
complete supported rows and 10 negative rows. Every original was already examined
in previous work, so all 51 are explicitly regression cases, not an unseen-layout
test set. Fresh baseline results reproduce the previously documented exact imports:

| Corpus | Complete rows | Apple exact | Android exact |
| --- | --- | --- | --- |
| Earlier personal photos | 18 | 17 | 18 |
| Earlier practice photos | 3 | 3 | 3 |
| October 31 practice photos | 3 | 3 | 3 |
| First online set | 9 | 1 | 0 |
| Second online set | 8 | 0 | 0 |
| Total | 41 | 24 | 24 |

All 10 negative rows remain unselected, and neither baseline produces an
incorrect automatic import. A passing safety assertion does not mean that every
row imports automatically. Apple readings run on macOS using the shared helper;
Android readings run on the isolated Android 17 emulator. These checks do not
establish installed iPadOS or physical Samsung capture performance.

The candidate also returns exactly 24/41 complete rows on each engine, with no
lost exact imports and no wrong automatic candidates. It therefore has **no
whole-photo gain** and fails the photo promotion gate as well as the glyph gate.
The paired experiment completes 204 row evaluations (51 × two engines × two
banks), all within four native calls. The empty-bank control makes a known
glyph-dependent October 31 photo require review, confirming that candidate asset
injection actually takes effect.

All 242 existing Flutter tests and 15 new lab safety tests pass. Static analysis
is clean; the Apple probe and Android instrumentation APK compile successfully.
No production recognizer, confidence threshold, app asset or journal format was
changed. [Sanitized measurement hashes and counts](evaluations/recognition-training-2026-11-04.json)
are retained alongside this record; private observations remain in the ignored lab
directory. One initial Apple native timeout was diagnosed and rerun; the final
paired reports contain no native errors. Cached native timings are not a fresh
camera-to-import latency benchmark.

## Next training targets

Prioritize layout and segmentation over a larger undifferentiated font bank.
The difficult online boards include shared headers far above lower player rows,
multiline player names, compressed/tiny delivery marks, compact bands with few
rulings and unsupported ordinary-frame formats. The current conservative frame
reader cannot always establish a safe row or frame boundary there. Improving
glyph accuracy alone cannot recover a row that was never located.

For a broader dataset, retain original camera images and human-confirmed name,
header, frame-band and scratch-total regions, then label delivery foreground
crops. Keep neighboring views and all crops/augmentations in their original
capture group. Capture multiple vendors/layouts, lower rows, split rings, colored
themes, perspective and low light, plus deliberately incomplete/conflicting
screens. Freeze a candidate before opening new held-out layout families; once
their failures inform a change, promote them to regression and collect fresh
holdouts. All current photos remain protected regression cases.

Use the lab first for measured layout/ink changes and labeled prototype training.
If those plateau, the same labeled crops and splits can support a compact shared
glyph classifier. Any such model still needs full-photo gates and real-device
latency/capture checks before replacing templates. Do not relax safety thresholds
or synthesize missing rolls to increase the success count. Very small online
images have a real information limit: ML Kit recommends roughly 16×16 pixels per
character and sufficient focus; upscaling cannot recreate lost strokes.
[Official input guidance](https://developers.google.com/ml-kit/vision/text-recognition/v2/android#input-image-guidelines).

## Measured layout recovery

The [November 5 recovery change](SCOREBOARD_RECOVERY.md) preserves all earlier
exact imports and adds two Apple / one Android complete-game imports in the
77-case corpus, with zero wrong automatic candidates. It keeps the 78-template
bank and records an untouched follow-up holdout, including its remaining failures.
