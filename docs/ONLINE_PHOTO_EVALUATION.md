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
