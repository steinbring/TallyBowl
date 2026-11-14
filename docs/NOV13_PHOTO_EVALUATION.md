# November 10 and 13 photo recovery

The nine supplied originals cover six complete games, two additional views of
those games, and one photo taken after six frames. Gold deliveries and all
visible cumulative scores were transcribed independently and checked with the
production ten-pin scorer before either native engine ran. Correct recognition
requires the saved bowler, every delivery in all ten frames, and the scratch
total; a readable total alone does not count.

## Causes and correction

The shared fallback cut its delivery crop off above tall spare strokes and
split digits. Its layout fit also assumed cumulative numerals were noticeably
larger than headings and that deliveries sat closer to their score baseline.
Some practice headings arrived as one long consecutive number instead of
separate frame numbers, and right-aligned scratch totals could overlap the total
heading while falling outside its narrow center tolerance. Android also emitted
a score/name/score token that falsely vetoed an independently recognized clean
alias. The tabletop console presented an additional format: scratch and
handicap totals stacked vertically under one TOTAL heading.

A final image-only retry addresses these cases after every established path has
failed automatic selection. It extends the measured delivery band, permits
compact cumulative typography within the same named-row geometry, and locates
merged heading positions from actual separated ink. Only explicitly recognized
consecutive runs of six or more headings ending at frame ten qualify; missing
or joined ink is not interpolated. A tiny console can instead use two distant
observed frame numbers, including ten, only beneath aligned PLAYER/TOTAL labels
and with six independently confirmed photographed rulings. Header boxes may
come from different native passes; delivery readings remain separate.

An offset total must overlap its observed heading and stay in the same row;
competing first-column numbers remain ambiguous. Stacked console totals require
three to eight separate repeated row pairs beneath PLAYER/TOTAL headings. Each
upper total must repeat its independently observed frame-ten checkpoint, the
lower entries must align with those checkpoints, and the pair gaps must agree.
This format is established without a calculated game score choosing geometry.
Two rows, a missing heading, or competing values cannot establish the exception.

The score-attached alias exception only removes a false conflicting-name veto
when the token contains a saved alias plus leading/trailing digits. It never
establishes ownership: another native pass must still read the clean alias.
Other names and digit-for-letter lookalikes remain conflicts.

The native helpers, bundled ML Kit version, 78-template bank, .68 IoU/.06 lead
rule, scoring rules and four-native-call limit are unchanged. Missing gutters,
conflicting legal deliveries, conflicting totals, ambiguous players and partial
games still require review. No missing delivery is derived from a score.

## Results

| Supplied view | Scratch total | Apple | Android |
| --- | --- | --- | --- |
| League game 1 | 102 | Exact ten frames | Exact ten frames |
| League game 2, near view | 108 | Exact ten frames | Exact ten frames |
| League game 2, farther view | 108 | Exact ten frames | Exact ten frames |
| League game 3, tabletop console | 77 | Exact ten frames | Exact ten frames |
| League game 3, overhead monitor | 77 | Exact ten frames | Exact ten frames |
| Practice game 1 | 97 | Exact ten frames | Exact ten frames |
| Practice game 2 | 90 | Exact ten frames | Exact ten frames |
| Practice game 3 | 89 | Exact ten frames | Exact ten frames |
| League game 2, after six frames | 75 so far | Review | Review |

The baseline recovered **0/8** finished views on Apple and **2/8** on Android.
The correction recovers **8/8 on each engine**, covering **6/6 unique complete
games**. The incomplete view cannot become a complete-game import.

The full paired run covers **113 rows from 64 original photos per engine**
(226 native row evaluations). All **35 earlier exact imports on each engine**
remain exact. Apple additionally recovers one previously failing older case;
Android additionally recovers three. Across the full corpus, Apple recovers
44/78 complete rows and Android 46/78. Older unfamiliar layouts still need
review; this is not a claim that every supplied historical photo works.

Both engines leave **35/35 negative rows unselected**, produce **zero incorrect
automatic candidates**, encounter no native/evaluation errors, and stay within
four native requests per row. The strict paired promotion gate passes with no
regressions; the intentionally changed Dart pipeline hash is explicitly allowed,
while native, original-photo and label pairing remain enforced.

All **318 Flutter tests and 16 lab safety/training tests pass**, and static
analysis is clean. New anonymous synthetic cases cover tall spare crops,
missing gutter ink, mismatched totals, compact and merged headings, sparse
console anchors/rulings, stacked-total ambiguity, and conflicting bowler names.
No additional glyph prototypes or acceptance-threshold changes were needed.

[Sanitized metrics and evidence hashes](evaluations/recognition-2026-11-14.json)
record the two pipeline/native fingerprints, all nine new case outcomes, strict
gate results, frozen-baseline provenance and verification-log digests. The
Mac and emulator timings are not physical-phone latency measurements.

## Reproduction and scope

Private originals, frozen labels, detailed OCR and request caches remain under
ignored `build/recognition-lab/league-practice-nov13/`; no private image, identity
or EXIF is added to Git or app assets. `new.json` contains nine rows. The combined
`corpus.json` contains 113 rows from 64 originals: all 104 prior cases, including
the previously inspected holdout, plus these nine. Inspected photos are protected
regression data, not an unseen accuracy test.

Fresh macOS Vision baseline requests use the freshly compiled production shared
Apple helper. The Android baseline combines the previously frozen 88-row,
10-row and six-row reports with a new nine-row run, all at identical Dart,
native/runtime and glyph-bank fingerprints. The composition is recorded in the
private report. Its original manifest hashes and every original hash, profile,
frame, cumulative score and status were verified against the combined labels.
Ten previously inspected online cases are explicitly retagged from `test` to
`regression` when projecting frozen outcomes onto the combined manifest; no
recognition result or gold score is altered. The unprojected composition,
projection script and audit are retained privately and hashed in the evidence. Exact request caching requires the same original bytes, native
fingerprint, geometry, aspect and context; changed requests cannot reuse a
response by case/call number alone.

Measurements execute production PhotoService, reader, parser and scorer using
macOS Vision with the shared iPad/Mac helper, and bundled ML Kit on a disposable
Android emulator. They do not replace physical iPadOS or Samsung camera/gallery
acceptance. No new TestFlight release or device installation is part of this
source correction. The installed/distributed release remains build 21.
