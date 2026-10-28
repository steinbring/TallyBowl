# Five-photo evaluation — October 28, 2026

Tested the five supplied original 4000×3000 JPEGs against the unchanged **0.1.11 (12)** recognition source, revision **3a73227**. Expected deliveries were transcribed from the photographs before running recognition, then checked against all ten displayed cumulative scores using `TenPinScorer`.

## Results

| Original image | Photographed scratch score | Apple Vision | Android ML Kit |
| --- | --- | --- | --- |
| 20260920_150625.jpg | 98 | Manual review | Manual review |
| 20260926_192151.jpg | 109 | Manual review | Manual review |
| 20260929_193212.jpg | 107 (220 with handicap) | Manual review | Manual review |
| 20261005_180009.jpg | 115 | Exact automatic fill | Exact automatic fill |
| 20261003_173317.jpg | 107 | Manual review | Manual review |

**Both pipelines automatically recovered 1/5 complete games.** The successful 115-pin image was already in the earlier twelve-photo evaluation. All four newly introduced photos required manual review on both engines. No incorrect automatic selection was observed. These results expose additional recognition gaps and should not be combined with the tuned development corpus as an independent accuracy estimate.

The scoring engine matched **every cumulative checkpoint and final total in all five manually transcribed games**, including tenth-frame `X6/`, `XX7`, `X81`, and `8/X` fills. This confirms those scoring calculations; it does not mean that recognition populated them.

## Independently transcribed scorecards

| Image | Frames 1–10 | Cumulative scores 1–10 |
| --- | --- | --- |
| 20260920_150625.jpg | `1- 9- 45 45 6- 71 35 -8 1/ X6/` | `1 10 19 28 34 42 50 58 78 98` |
| 20260926_192151.jpg | `8- 8- 72 9- 9- 9- 1- 18 9/ XX7` | `8 16 25 34 43 52 53 62 82 109` |
| 20260929_193212.jpg | `9- 62 7/ 7- 7- X 4/ -1 9- X81` | `9 17 34 41 48 68 78 79 88 107` |
| 20261005_180009.jpg | `9- X 1/ 72 9- 9- 9/ 7- 72 -9` | `9 29 46 55 64 73 90 97 106 115` |
| 20261003_173317.jpg | `81 X 17 81 4- 7/ 63 5- 72 8/X` | `9 27 35 44 48 64 73 78 87 107` |

## Observed failures

- **98:** Apple returned the bowler/cumulative text without usable frame inputs. Android recovered eight nonempty frame strings but missed frame 3 and the tenth-frame fills, and misread the displayed total as 90. Automatic acceptance remained disabled.
- **109:** Both pipelines returned bowler/context text without usable frame inputs. The patterned screen and incomplete header/delivery observations did not yield a validated grid.
- **League 107:** Apple returned a partial delivery row with the correct scratch total, but strikes, spares and several complete frame readings were missing. Android returned no usable owner frame inputs. The 220 handicap-adjusted total was not accepted as an automatic scratch game.
- **115:** Both pipelines selected the owner row and recovered all ten exact frame strings, delivery order, cumulative scores and scratch total.
- **Red-screen 107:** Both pipelines returned bowler/context text without usable frame inputs. Apple recognized much of the cumulative band but only sparse numbered headers and malformed merged delivery tokens. The current six-header fallback requirement prevented pixel recovery from that sparse geometry.

The next recognition work should improve locating small score tables and recovering grid geometry when native OCR omits numbered headers. It should also cover the patterned monitor and red-screen font, isolated strikes/spares and tenth-frame fills. Final totals alone cannot establish the delivery sequence; existing ambiguity and checkpoint safeguards remain necessary.

## Method and limits

Apple checks used the production Swift Vision helper on this Mac, called from the current `PhotoService` pipeline with its actual bounded retries and pixel fallback. Android checks ran the production `PhotoService`, bundled native ML Kit bridge and pixel fallback inside an isolated Android 17 emulator. The diagnostic recorded the actual `ScoreSheetParser.automaticRow` result, rather than counting any partially populated row as a success. The known owner profile included Joe/Jose aliases on both engines.

The five Apple harness checks passed their scoring and native-call-bound assertions; recognition outcomes are reported above, including the four review cases. No recognition thresholds, app code or scoring rules were changed for this evaluation. Physical iPad/Samsung capture and installed TestFlight behavior were not tested. Device/OS OCR results can vary.

Original images, native observations, expected scorecards and diagnostic outputs remain private under ignored `build/corpus5/`. The original photos and diagnostic entry points are excluded from Git and distribution artifacts. The normal verified build 12 was restored on the isolated emulator after testing. TestFlight remains build 12; this evaluation does not publish a new app version.
