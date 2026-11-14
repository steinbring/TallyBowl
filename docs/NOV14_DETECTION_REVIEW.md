# November 14 detection review

A review of score-photo detection across both on-device engines: Apple Vision
(iPad/Mac, `apple/ScoreTextRecognition.swift`) and bundled ML Kit Latin
(Android, `ScoreTextRecognizer.kt`), plus the shared Dart pipeline.

## Method

The private 113-row corpus (64 originals, 78 complete rows, 35 negative rows)
was replayed through the current Dart pipeline from the exact-request native
OCR cache. The replay first reproduced the recorded November 14 results exactly
(Apple 44, Android 46 exact, no differences) before any change was measured.
Requests that a change made new were answered by the freshly compiled shared
Vision helper on macOS 27.2.1 or by bundled ML Kit on a disposable emulator
with the recorded native fingerprint. Each change passed the strict lab
gate: no lost exact row, no incorrect automatic candidate, no evaluation
error and at most four native calls.

## Changes

| Finding | Engine | Change | Measured result |
| --- | --- | --- | --- |
| Vision labels a photographed 3 or X with Cyrillic/Greek code points (`З`, `Х`, `Χ`) in 92 Apple responses; ML Kit never does. Most Dart paths treated `З9`, `Х54` or a `З` header as non-numeric. | Apple | Whole score-character tokens with these lookalikes read as 3/X when parsed. Names and other words are unchanged. | Apple 44 → 44; 23 rows read more accurately but still need review. No regressions. |
| Accented saved names lost the accented letter (`José` ≠ `JOSE`). Multi-word aliases such as `JOE S` matched only in text rows and recovery; the grid ignored one-letter words, focus and primary layouts needed one word, and the italic retry vetoed a joined name's own first word. ML Kit can glue a name to the first strike (`BX`). | Both | Diacritic folding; one shared set of exact name anchors on every path; an alias glued to score marks is separated only at a measured character-box gap. | Android 46 → 47; Apple 44 → 44. No regressions. |
| A rejected photo re-decoded the image, copied the raster once per layout and re-ranked identical ink up to six times. A rejected-photo test took ~24 s alone and timed out on merged main. | Both | Decode once, one worker per pass, exact-key ranking memo. | Every parsed row byte-identical; total time −26 %. |

Combined result: Apple 44/78 and Android 47/78 complete rows exact, 35/35
negative rows unselected, zero incorrect automatic candidates.

## Checked and ruled out

- **Vision minimum text height.** `VNRecognizeTextRequest.minimumTextHeight`
  already defaults to 0 on the current OS, so small marks are not filtered.
- **Character boxes on Apple.** Vision's accurate mode returns the whole word's
  box for every character range (`319` gives three identical boxes), so the
  bridge cannot provide ML Kit-style symbol geometry. Apple keeps word boxes.
- **Different Vision cell-crop rendering.** On the October 20 league photo,
  no aspect, height or label variant read both deliveries in most cells, and
  one read a spare stroke as `1`. The native crop rendering is unchanged.
- **Splitting every wide ML Kit character gap.** It changed native requests
  in 27 photos and risked two exact rows; only the name-and-mark split is used.

## Remaining opportunities

- **Second-ball marks in Vision cell crops.** On the October 20 league photo,
  Vision read only the first delivery in most single-cell crops (`5` for `5-`,
  `8` for `8/`). The glyph fallback recovers every other frame, but frame 8's `3`
  ranks .71 against `8` at .66, under the .06 lead, so the row stays in review.
- **3-vs-8 tie-break (tried, not shipped).** Three near-tie rules were measured
  with the production classifier on 48,816 synthetic cells: 36 local typefaces,
  all 12 score characters, five glyph heights, blur, stroke weight, slant,
  hairline cuts and erased patches. Counting closed loops recovered 158
  rejected glyphs but newly accepted 37 wrong ones, mostly an 8 whose left waist
  was erased (25 read as 3); closing larger gaps made it worse by filling real
  counters. Requiring the runner-up's distinguishing pixels to be empty gained
  only 2 glyphs at a safe limit, and combining both still added one wrong glyph
  for 5 gains. An `8/` read as `3/` after an open frame keeps every checkpoint
  and the total, so score validation cannot catch it. The zero-wrong-glyph rule
  stands; this photo needs native OCR of the 3 or manual review.
- **ML Kit cell merges.** ML Kit can merge a checkpoint and total into one
  token (`2935134`), leaving no observed total; Vision separates them.
- **Non-Latin names.** Vision is limited to `en-US` and ML Kit uses only its
  Latin model, so Japanese or Cyrillic scoreboard names cannot be matched.
  Supporting them needs additional recognizers and a larger Android app.

Private replay tooling and reports are under ignored
`build/recognition-lab/claude/`; no photo, name or OCR text is committed.
