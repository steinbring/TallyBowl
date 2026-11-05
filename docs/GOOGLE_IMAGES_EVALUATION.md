# Fresh Google Images benchmark — November 4, 2026

Neither Apple Vision nor Android ML Kit produced an exact automatic ten-frame
import for the 12 eligible complete games in this new sample. The frozen
experimental glyph bank did not improve that result. Some totals and partial
frames were read, but these are not counted as successful game imports.

| Full production pipeline | Existing 78 templates | Experimental 222 templates |
| --- | --- | --- |
| Apple Vision | 0/12 exact complete games | 0/12 |
| Android ML Kit | 0/12 exact complete games | 0/12 |
| Incorrect automatic candidates, either engine | 0 | 0 |
| Negative cases kept out of automatic import, each engine | 14/14 | 14/14 |

These results expose a substantial generalization gap. Rejecting incorrect or
unidentified results is useful protection, but it is not successful recognition.
The candidate remains experimental and is not a production accuracy improvement.

## Selection and ground truth

The images were selected directly from **Google Images**, using the query
`bowling scoreboard screen`, on November 4. This is a deliberately varied small
sample, not a statistically random estimate of accuracy. It includes five
photographed screens and three vendor display examples, with CRT lettering,
perspective, dark-on-light marks, mixed foreground colors, rounded cells, stacked
names and multiple totals. Original image dimensions range from 700×525 to
5120×3840. All eight have different SHA-256 hashes from the earlier photo corpus;
visual inspection also found no repeated earlier game screenshot.

Both template banks were frozen before inspecting the new engine results. The
visible deliveries and cumulative scores were transcribed first, and a hash of
the 26-case manifest was locked before recognition. The production scorer checks
every complete game's ten frames and all ten cumulative scores. No missing
delivery was reconstructed from a total. After this evaluation these images are
available for regression work; they must not be described as unseen data after
their failures inform a recognition change.

| ID | Source found through Google Images | Complete eligible games | Other rows |
| --- | --- | --- | --- |
| g01 | [CRT photo in Rachele DiTullio's post](https://racheleditullio.com/blog/2016/02/bowling-2/), credited there to sunnythomas | 190 | Four unfinished games |
| g02 | [Computer Score replay display](https://computerscore.com.au/wp-content/uploads/Replay-Part-3.jpg) | None | Three unfinished games with handicaps |
| g03 | [Coach Lippy practice photo](https://coachlippy.com/what-bowling-taught-me-about-execution/) | 83, 152 | None |
| g04 | [Hollywood Bowl photo by EdwardNesbitt](https://commons.wikimedia.org/wiki/File:Hollywood_Bowl_Score_Screen.jpg), CC BY-SA 3.0 | 117, 73, 108 | None |
| g05 | [Steltronic StelPad display](https://steltronicscoring.com/steltronic-products/) | 130, 113, 133 | None |
| g06 | [ScoreMaster display](https://www.scoremaster.eu/assets/images/sslane1007-1.jpg) | None | Six unfinished games |
| g07 | [Perfect-game photo by RCraig09](https://commons.wikimedia.org/wiki/File:300_Perfect_game_-_tenpin_bowling.jpg), CC BY-SA 4.0 | Excluded from identity-bound import denominator | Visible 300, but source redacts the bowler's name |
| g08 | [Eastbury scoring-record photo](https://snieronbowling.com/2025/06/09/monday-feature-trio-team-posts-second-best-national-score-at-eastbury/) | 300, 299, 269 | None |

There are **12 complete eligible games, 13 incomplete games and one unidentified
game**. A source with a redacted name cannot establish that the game belongs to
the selected bowler, even when its marks are clear. The lab now has an explicit
`unidentified` negative label for this situation.

## What failed

- **Game totals versus other totals.** In g08, Apple recovered all ten frame
  cells of the 300 game, including `XXX` in the tenth, but paired them with 216
  from the other number in the total panel. The mismatch correctly prevents
  import. The upper numbers 216/223/288 sum to 727, matching the previous game
  described in the source article; the current games are 300/299/269. Improving
  digit recognition alone will not resolve the total panel's structure.
- **Dark and mixed-color delivery ink.** g04 has dark marks on a light strip;
  g05 alternates dark first-ball marks with light marks inside dark second-ball
  boxes. The shared fallback's foreground rules favor bright neutral or green
  ink. A larger template bank does not change that segmentation assumption.
  Native readings also leave gaps or assign marks to the wrong frame. For
  example, Android's best g04 row matches nine of ten frame cells and the total,
  but still cannot import the exact game. These observations motivate a bounded
  per-cell polarity/foreground experiment, not a relaxed confidence threshold.
- **Player and frame geometry.** g01 uses multiline player labels and thin CRT
  boxes; g03 and g08 use single-letter labels. Header-to-row and name evidence
  remain weak in several readings. Lower player rows and layouts with unusual
  cell geometry need explicit evaluation alongside glyph classification.

These are diagnoses from the current source and stored observations, not claims
that an unimplemented fix has already solved the images. The next experiment
should target foreground polarity, row/frame boundaries and the semantic role of
each displayed total, with the full existing corpus required to keep passing.

## Reproducibility and regression protection

The real production `PhotoService` performs its retries, pixel fallback, parser
and automatic-row selection against the original image bytes. Apple observations
come from the shared iPad/macOS Swift helper running on this Mac; Android uses the
bundled production ML Kit helper on a disposable Android 17 emulator. This does
not substitute for physical Samsung or installed iPadOS capture testing.

The four conditions complete **104 row evaluations**, all within four native
calls, with no native errors. Exact-request caching reuses native output only for
identical photo bytes, native/runtime fingerprint and geometry/aspect/context.
The [sanitized record](evaluations/google-images-2026-11-04.json) retains sources,
dimensions, hashes, per-image counts and pipeline fingerprints.

Original downloads, profiles, labels and OCR observations remain under ignored
`build/recognition-lab/google-images-2026-11-04/`. They are not in Git or app assets.
`build/recognition-lab/corpus-expanded.json` now combines the earlier 51 cases
with these 26 as **77 regression cases across 42 originals** for future changes.
The locked fresh-test manifest is retained separately.

No production recognition code, thresholds or template assets changed. Both
engines and both banks have exactly the same pipeline/native/runtime/template
fingerprints as their earlier 51-case evaluation. Those older cases were not
rerun in this round; the earlier results remain the paired reference. The added
negative-label guard is covered by the lab safety tests. All 16 lab tests pass.
