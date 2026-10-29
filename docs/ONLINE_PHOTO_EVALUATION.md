# Unfamiliar online scoreboards

## First set: unchanged build 13

Evaluated the four supplied JPEGs after completing the 0.1.12 (13) owner/external TestFlight setup. Apple checks use the production Swift Vision bridge on this Mac; Android checks run the production Flutter, bundled ML Kit and pixel pipeline on an isolated Android 17 emulator. Each visible bowler is tested separately with the visible name as the profile/alias. Expected deliveries were transcribed before recognition and checked against the visible cumulative scores.

These files are only 550–682 pixels wide. There are nine completed standard ten-pin games, three unfinished games and three rows containing three deliveries in ordinary frames. The last group is outside the app's supported ten-pin rule set; its visible totals do not authorize discarding extra deliveries.

| Supplied file | Completed ten-pin games | Apple exact automatic fill | Android exact automatic fill |
| --- | --- | --- | --- |
| `images.jpg` | 204 and 267; third row unfinished | 0/2 | 0/2 |
| `images-2.jpg` | 293, 171, 182 and 280 | 1/4: the 293 game | 0/4 |
| `bowling-scores.jpg` | 109, 69 and 149; two rows unfinished | 0/3 | 0/3 |
| `images-1.jpg` | Three-delivery format, outside supported rules | Review for all three rows | Review for all three rows |

**Apple fills 1/9 supported complete games exactly; Android fills 0/9. No incorrect automatic game was observed.** Both engines recognize some names, numeric scores and partial delivery strings, but that is not a complete frame import. All unfinished and unsupported rows remain unselected.

The failures expose real generalization gaps: tiny compressed marks, missing native observations, multi-line names, lower player rows sharing one header, and compact score bands without vertical cell rulings. The 404/371 values above the first image's actual 204/267 totals also show why a large visible number cannot alone validate a game.

Bounded native upscaling was tested on both engines and did not improve exact recovery. A numeric-band positioning prototype improved some partial readings but changed cell crops enough to regress earlier tests. Neither experiment is shipped. They are retained only as private diagnostics. The existing production thresholds and score rules remain unchanged.

A useful next implementation needs independently verified player-band localization and better recognition of small delivery glyphs, with all prior frame-order, checkpoint and ambiguity safeguards. Higher-resolution source photos would retain information lost in these compressed examples. Three-delivery formats require a separate scoring mode; they must not be forced through ten-pin scoring. Neither enlarging the JPEG nor solving backward from a total supplies trustworthy missing marks.

The original JPEGs, native observations, transcriptions and experimental targets stay under ignored `build/online4/`. The online images are not committed or bundled. The earlier permissioned corpus remains covered by the committed regressions. This evaluation does not change the released build or establish general recognition accuracy.

## Second set: follow-up candidate

Evaluated the next four supplied originals only after the first set's evaluation was complete. The same production pipeline ran through actual Apple Vision and bundled Android ML Kit. Visible deliveries and cumulative scores were transcribed independently before recognition. There are eight internally consistent completed ten-pin games and two rows that cannot safely validate a complete game from the visible marks.

| Supplied file | Consistent completed games | Apple exact automatic fill | Android exact automatic fill |
| --- | --- | --- | --- |
| `656677969_26468012312886249_5683420264564622843_n.jpg` | KAT 99; CRONE 259 | 0/2 | 0/2 |
| `images-1.jpg` (portrait, 480 × 640) | Sea 179; Mi 238; Giu 158 | 0/3 | 0/3 |
| `images.jpg` (612 × 501) | Alana 300 scratch, 310 with handicap | 0/1 | 0/1 |
| `maxresdefault.jpg` | KRISTA 74; JOSH 220 | 0/2 | 0/2 |

**Both engines fill 0/8 consistent completed games automatically, before and after the follow-up fixes.** They read some names, totals and partial delivery sequences; those observations do not establish a complete import. Neither conflicting row was selected automatically. No incorrect automatic game was observed in either online set.

The other two rows in the 612 × 501 image need manual review even with perfect OCR. Wendy's visible ninth-frame spare followed by an 8 gives a ninth cumulative score of 170, while the screen shows 172; the tenth `8/` has no visible bonus delivery. Nancy's visible deliveries calculate to 102, while the screen shows 92, with conflicting cumulative values at the end. The app must not invent missing rolls or alter visible marks to fit these totals.

Two conservative improvements are retained: shared name matching canonicalizes visually identical Latin/Greek/Cyrillic capitals (Apple returned a Cyrillic A inside `KАT`), and an incomplete pixel crop can remove measured connected bright boundary rulings before retrying classification. Neither relaxes scoring, confidence, checkpoint or competing-row safeguards. These improvements have targeted regressions but did not recover an additional complete online game.

Private experiments included native upscaling, alternative OCR modes, character boxes, whole-player and per-cell context, compact-header positioning, wider glyph templates, and alternate handling of estimated character positions. None safely improved complete recovery across these images; several regressed prior personal photos. They are not shipped. The production pipeline retains its four-native-call limit and runs entirely on the device.

Final verification on October 29, 2026: **216 Flutter tests pass; static analysis is clean.** Actual native end-to-end checks cover 45 row cases per engine: 20 personal originals, 15 first-set online rows and 10 second-set rows. Of the 18 completed personal games, Apple still fills 17/18 and Android 16/18 exactly; both incomplete personal games remain unselected. The five most recent personal-photo checks still fill 5/5 on each engine. First-set online recovery remains Apple 1/9 and Android 0/9. No incorrect automatic result appeared in any of these checks. Passing the harness means its expectations and refusal safeguards passed, not that every image auto-filled.

Private originals and observations remain under ignored `build/online4b/`; none is committed or distributed. These development examples are not a representative accuracy estimate. Recognition across unfamiliar layouts and small compressed glyphs remains unreliable, so this beta does not meet a claim of perfect live recognition. Review the imported frames against the photograph before saving.
