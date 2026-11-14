# November 8 gutter-mark recovery

Verified November 9, 2026. Included in **0.1.19 (20)** for iPad and native Mac,
Testing in Owner testing and assigned to External testing with status Waiting
for Review. See [the release record](TESTFLIGHT.md). Neither Android phone was
updated by this release.

The four supplied originals contain three games and a second, more distant view
of the final game. Both bowler rows were independently transcribed, including
leading/trailing misses, double misses, a gutter followed by a spare, split marks
and tenth-frame fills. All eight rows are regression data after inspection.

## Causes and correction

The pale blue delivery ink and thin colored illustration can have similar
luminance. The separately fitted cumulative-band fallback previously lacked the
row color calibration used by another reading path. Illustration fragments could
obscure a gutter mark or prevent a complete glyph reading. The monitor's milder
italic lean also fell between the existing upright and ±.2 corrections.

The final fallback now includes the existing three bounded color-calibrated masks
on that band and tries intermediate ±.1 shear corrections for unresolved glyphs.
Confident upright glyphs remain intact. The 78 templates, .68 IoU/.06 lead rule,
native helpers, four-call limit and ten-pin scoring are unchanged. Earlier
validated reading paths run first. No score determines which delivery to read.

Android's 115 game had a separate blocker: the frames were complete, but native
OCR reported both `115` and an overlapping `5` for the same scratch total. A
shorter proper text fragment is resolved only beneath an observed total label,
with substantial box overlap and an independent pixel reading of the entire
longer number. Native character values and the calculated game score do not
participate in that raster classification. Competing full numbers, missing ink
and ambiguous readings still require review.

## New original-photo results

| Game/view | Expected frames | Apple / Android after correction |
| --- | --- | --- |
| 88 | `7/ X -6 1- -6 9- 9/ 16 9- 3-` | Exact / Exact |
| 115 | `-/ X 9- 18 9/ 9- 63 -7 61 7-` | Exact / Exact |
| 117, closer view | `71 12 8- 7/ 9- -1 X X 44 X9-` | Exact / Exact |
| 117, distant view | Same visible game | Review / Review |

All three clearer game photos now recover every frame and scratch total on both
engines. Across both rows in all four photos, Apple improves from **1/8 to 6/8**
exact rows and Android from **5/8 to 7/8**. The distant duplicate remains an
important limitation: it is not an automatic success for the owner's row.

## Preservation and validation

The combined manifest covers **88 rows from 49 originals**: 64 complete games
and 24 negative cases. The previously inspected holdout adds six rows from two
originals, including two small complete games still requiring review and four
clipped rows remaining unselected.

| Engine | Exact complete games before / after, out of 64 | Earlier exact imports retained | Incorrect automatic candidates |
| --- | --- | --- | --- |
| Apple Vision plus shared reader | 30 / 35 | 29 / 29 | 0 |
| Android ML Kit plus shared reader | 33 / 35 | 28 / 28 | 0 |

Across **94 rows from 51 originals per engine**, there are zero incorrect
automatic candidates, zero native failures and at most four native calls per row.
The paired promotion gate passes. All 24 negative corpus cases and the four
clipped holdout rows remain unselected. No earlier exact original-photo import
is lost.

All **286 Flutter tests and 16 lab safety/training tests pass**; static analysis
is clean. Fourteen added/extended anonymous tests cover gutter order, double
misses, gutter spares, absent marks despite matching checkpoints, conflicting
primary deliveries/totals, numeric-fragment pixel verification, full-number
ambiguity, intermediate slants and the four-call production service path. An
older complete Android 112-game fixture also now reads exactly; its unchanged
gold frames and total are required rather than its former manual-review result.
Incomplete and identity-conflict expectations are retained.

[Sanitized counts and measurement hashes](evaluations/practice-2026-11-08.json)
identify the evaluated pipeline, templates, native fingerprints and reports.

## Evidence and scope

Private originals, labels, native observations and diagnostics remain under
ignored `build/recognition-lab/practice-nov08/`. The paired baseline composes the
previous frozen 80-case reports with eight fresh native evaluations only after
checking identical pipeline, native/runtime and template fingerprints. Final
candidate runs execute the production `PhotoService`, parser and scorer on every
original with exact-request native-response caching. The existing holdout is a
regression check, not a new unseen evaluation.

Apple measurements use macOS Vision with the shared iPad/macOS helper; Android
uses the production ML Kit helper on a disposable read-only Android 17 emulator.
Neither physical phone was modified. These are original-file measurements, not
new installed-camera/gallery or iPadOS acceptance checks. No private photos,
identities or experimental templates are added to source control or app assets.
Recognition on unfamiliar layouts and low-quality photos can still require
manual correction. Journal and backup formats are unchanged.
