# Additional scoreboard photo evaluation

Evaluated October 27, 2026 using the twelve additional owner-supplied original JPEGs. Expected deliveries were transcribed from the photographs before comparison and checked against the displayed cumulative scores with the ten-pin scorer. Exact recovery means every delivery, delivery order, tenth-frame fill and scratch total match, with a unique automatic owner-row selection. Matching the final total alone is insufficient.

Ten photographs show complete owner games; two show an unfinished game. The ten complete images represent eight games: the 115- and 152-pin games each have two views. These photos were used during development, so this is regression evidence, not an independent estimate of general accuracy.

| Original image | Scratch score / state | Apple Vision | Android ML Kit |
| --- | --- | --- | --- |
| 20261005_180008.jpg | 115 | Exact | Exact |
| 20261011_182935.jpg | 99 | Exact | Exact |
| 20261020_191858.jpg | Four visible frames; 48 resolved | Review; no completed game | Review; no completed game |
| 20261006_212019.jpg | 112 | Exact | Review |
| 20261005_180009.jpg | 115, second view | Exact | Exact |
| 20261011_181327.jpg | 87 | Exact | Exact |
| 20261011_184225.jpg | 76 | Exact | Review |
| 20261020_190226.jpg | 103 | Exact | Exact |
| 20261020_192009.jpg | Five visible frames; 68 resolved | Review; no completed game | Review; no completed game |
| 20261020_194604.jpg | 152 | Exact | Exact |
| 20261020_194606.jpg | 152, second view | Exact | Exact |
| 20261020_203145.jpg | 114 | Review | Exact |

The build-11 baseline recovered **4/10 complete images on each engine**. The update recovers **9/10 on Apple and 8/10 on Android**. No incorrect automatic result was observed in these original-image runs. Both incomplete examples remain in review; future deliveries are never fabricated. The Apple 114-pin image still lacks sufficient independent evidence for its eighth-frame digit. Android's 112- and 76-pin images lose important native text/header context; they remain review cases.

## Changes and safeguards

- Calibrate tilted vertical rulings using a bounded family of line slopes, rather than requiring perfectly vertical image columns.
- Retry full-image OCR when the earlier pass misses the name or grid. Use pixel-calibrated delivery crops when text geometry is insufficient. Keep the four-call native OCR limit and early successful exit.
- Reuse observed geometry across passes from the same photo, preserving each pass's delivery observations. Secondary OCR can corroborate the pixel winner at the same position; it cannot replace a different pixel winner or a conflicting primary character.
- Keep delivery order from complete photographed components when available. A cropped regression exposed `-1` being read as `1-`; both have the same score, so totals cannot detect that error. Complete native readings still preserve marks obscured by monitor graphics when component classification cannot complete a cell.
- Preserve scratch/handicap separation, legal ten-pin validation, checkpoint conflict checks, name matching, ambiguous-row review and manual editing. No score-solving search or cloud recognition was added.

## Reproducibility and limits

`test/fixtures/corpus12/` contains cropped score tables with artificial Bowler/Guest labels, independently transcribed expected frames and transformed native observations from both engines. Android line/word/symbol hierarchy is retained. Original photos, original names, venue/background, EXIF and diagnostic logs stay outside Git and app bundles. The fixtures cover exact autofill, incomplete-game refusal, the remaining engine-specific review cases and delivery-order errors.

**179 Dart/widget tests pass; static analysis is clean.** Earlier 80/104 league, 89/109 practice, 90-pin monitor, editor import/resume, scoring, sharing, persistence and accessibility regressions remain covered. Actual original-image checks use the production shared Swift Vision helper on this Mac and the bundled native ML Kit bridge on an isolated Android emulator. These checks do not establish physical iPad/Samsung camera, recipient-app sharing or TestFlight installation acceptance. Vision results can vary by OS/device; glare, unusual fonts, extreme perspective and occlusion still require review.

Private per-photo results, native observations, timings and diagnostics are under ignored `build/corpus12/`. TestFlight distribution status is recorded in [TESTFLIGHT.md](TESTFLIGHT.md).
