# November 7 practice-photo recovery

Final verification: November 8, 2026. This source change is included in
**0.1.18 (19)** for iPad and native Mac: Testing in Owner testing and assigned to
External testing, Waiting for Review. See [the release record](TESTFLIGHT.md).

The three supplied original JPEGs show complete games of **93, 148 and 105**.
Before the fix, Apple Vision plus the shared reader recovered only 148; Android
ML Kit plus the shared reader recovered only 105. Both reproduced the reported
one-out-of-three result, although their successful images differed.

## Causes and correction

The monitor combines condensed italic delivery lettering, split rings and a
patterned background. The upright glyph fallback rejected the broad-footed,
slanted numeral `1`, sometimes preferring `2` below the acceptance threshold.
Another crop called a photographed `9` a `6`; recovery incorrectly treated that
secondary observation as primary evidence across all text passes. In the 105
photo, oversized Vision boxes around headers 9 and 10 also inflated the estimated
header height and prevented a valid cumulative-band fit.

The existing text, raster and recovery paths still run first and return their
validated results. Only an unresolved image reaches the additional fallback:

- Apply two bounded horizontal shear corrections to an unresolved component
  before comparing it with the existing templates. Keep an already confident
  upright shape. Similarity and winning-margin thresholds are unchanged.
- Keep primary observations local to their own OCR pass. Secondary observations
  can corroborate the pixel winner, but cannot become primary evidence merely
  because they came from a crop. Legal primary frames and partial readings remain
  constraints; malformed OCR sequences containing illustration fragments do not
  dictate a fully classified pixel sequence. An explicit conflicting player name
  at the same row position in another full-image pass vetoes the new fallback.
  Single-letter boxes belonging to a native word are not a different identity.
- Require two distinct, similarly sized observed headers before using the smaller
  height beside inflated OCR boxes. A lone small header cannot shrink the band.
  Recovery still requires six observed cumulative checkpoints including frame ten,
  the saved bowler's observed identity, ten legal complete frames and independent
  scratch-total evidence.

The correction is shared Dart code. Both native helpers and the shipped
78-template glyph bank remain unchanged. It adds no native OCR calls; the limit
remains four. Totals and checkpoints validate observed rolls, never reconstruct
missing marks.

## New original-photo results

| Game | Expected frames | Before Apple / Android | After Apple / Android |
| --- | --- | --- | --- |
| 93 | `72 43 81 54 X 71 44 7- -9 36` | Review / Review | Exact / Exact |
| 148 | `7- 5/ X 9- 9/ 9- X 1/ 72 4/9` | Exact / Review | Exact / Exact |
| 105 | `5/ 15 -7 81 43 8/ X 72 8- 9-` | Review / Exact | Exact / Exact |

Exact means all ten frames, the tenth-frame fills and the scratch total agree
with independently transcribed gold labels and every observed checkpoint. These
photos are development regression cases, not unseen accuracy measurements.

## Preservation results

| Engine | Exact games before / after, out of 56 | Earlier exact imports retained | Incorrect automatic candidates |
| --- | --- | --- | --- |
| Apple Vision plus shared reader | 27 / 29 | 26 / 26 | 0 |
| Android ML Kit plus shared reader | 26 / 28 | 25 / 25 | 0 |

Both engines now recover all three new games, retain every earlier exact result
and leave all 24 negative cases unselected. The paired promotion gate passes.
The previously inspected two-photo holdout also remains safe: its two small
complete games still need review and all four clipped rows remain unselected.
Across **86 rows from 47 originals per engine**, there are zero incorrect
automatic candidates, zero native failures and at most four native calls per row.
These checks do not establish recognition of every unfamiliar scoreboard.

[Sanitized counts and measurement hashes](evaluations/practice-2026-11-07.json)
identify the final evaluated pipeline, templates, native fingerprints and reports.

## Evidence and scope

The ignored local manifests and native responses are retained under
`build/recognition-lab/practice-nov07/`. The combined regression manifest has
80 row cases from 45 original photos: 56 complete games and 24 negative cases.
Its baseline composes the previous frozen 77-case results with the three fresh
native evaluations only after checking identical Dart pipeline, native/runtime
and template fingerprints. Candidate runs execute the current production
`PhotoService`, parser and scorer on every original, using exact-request cached
native responses or new native reads as needed.

Apple measurements use macOS Vision with the shared iPad/macOS helper. Android
measurements use the production ML Kit helper on an isolated Android 17 emulator.
Original photos, private identities, OCR logs and experimental diagnostics are
excluded from Git and app assets. New committed raster tests are synthetic and
anonymous. Physical camera latency and installation acceptance remain separate
from this local evaluation. The subsequent Apple build-19 release passed signing,
archive/content and bundled-asset checks; those checks do not replace physical
device acceptance.

The complete **272-test Flutter suite passes**, including the unchanged
identity-conflict regression that caught a problem during development and 13 new
anonymous raster/workflow tests. The new tests cover both slant directions,
missing rolls despite matching checkpoints, incorrect totals, conflicting native
values, inflated and duplicate headers, native name fragments and the four-call
import path. Static analysis is clean. All **16 lab safety/training tests pass**.
