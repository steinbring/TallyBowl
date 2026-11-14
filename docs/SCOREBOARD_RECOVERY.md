# Scoreboard recovery — November 5, 2026

The later [November 7 practice-photo evaluation](NOV07_PHOTO_EVALUATION.md)
records the subsequent italic/header correction and preservation checks. The
measurements below retain their November 5 scope.

The shared reader now has an additional recovery path for unfamiliar scoreboards.
The existing native-text and glyph paths run first and return their already
validated imports before recovery runs. Apple Vision and Android ML Kit remain
independent sources of observed text; their native helpers and the production
78-template glyph bank are unchanged.

## Behavior

Recovery fits a cumulative-score band from at least six actual numeric
observations, including frame ten. It uses their positions to anchor the delivery
band and correct header alignment. It does not reconstruct deliveries from score
arithmetic. Large header boxes and very small player names cannot by themselves
bind a neighboring player's row. Two plausible score bands remain ambiguous.

The additional reader supports:

- Right-aligned headers and left-aligned deliveries, with padding that retains
  a complete strike rather than discarding an edge-connected fragment.
- Dark, light and mixed delivery ink, while retaining the established neutral
  color mask for bright blue screens. Dense delivery-box backgrounds are removed
  separately. Distinct legal readings from different masks require review.
- Exact saved aliases split into adjacent observed name words. Missing letters
  are never guessed. Short aliases remain tied to score-band geometry.
- Android headers merged into one word, using the native character boxes. An
  observed adjacent `1` and `0` can form header `10`; letters are not converted
  into header numerals, and estimated character positions are not used.
- Current-game totals aligned with the cumulative baseline, or explicitly labeled
  total columns. The first scratch column is distinct from later handicap
  columns. Conflicting observations in that column remain ambiguous. A previous
  game total is not selected merely because it matches calculated rolls.

A recovered game still needs ten legal, complete frames, all observed checkpoints
in agreement, independently observed scratch-total evidence and the saved bowler's
observed identity. Existing cross-pass identity and conflict checks remain active.
Glyph similarity and winning-margin thresholds are unchanged. A bounded optional
cell retry uses only an unused fourth native call. Retry failures preserve the
observations already collected; conflicting candidates remain available to the
parser rather than being overwritten.

## Original-photo regression results

The frozen corpus contains 77 bowler-row cases from 42 original photos: 53
complete supported games and 24 incomplete, unsupported, conflicting or
unidentified rows. All of these images had already informed prior development;
they are regression cases rather than unseen test images.

| Engine | Previous exact complete games | Updated exact complete games | Previous successes lost | Incorrect automatic candidates |
| --- | ---: | ---: | ---: | ---: |
| Apple Vision plus shared reader | 24/53 | 26/53 | 0 | 0 |
| Android ML Kit plus shared reader | 24/53 | 25/53 | 0 | 0 |

Apple gains the Vector board's 300 and 269 games; Android gains its 269 game.
The 269 game includes a spare, repeated strikes and a three-delivery tenth frame.
The independently observed current-game totals are separated from the older
216/288 totals above them. Gains require the exact ten-frame sequence and total,
not just a matching final number. All 24 negative cases remain unselected, every
native call succeeds in the final reports, and every case stays within four calls.
The paired promotion gate passes with a declared shared-pipeline change.

Other difficult online boards still require review. The dark/mixed-ink behavior
also has synthetic raster coverage, but it did not add a complete photographed
dark-ink game to this particular regression corpus. These results do not establish
universal recognition or justify treating unknown deliveries as observed.

## Frozen holdout

After implementation, two additional public originals and their gold labels were
frozen before either engine evaluated them. No production change was made after
seeing these results:

- [Maldon and Dengie Ramblers bowling photo](https://www.maldonanddengieramblers.org/bowling.html):
  the source camera framing clips the rightmost deliveries and scratch-total
  column. All four rows correctly remain unselected on both engines.
- [Superbowl Singapore visitor photo](https://www.tripadvisor.be/Attraction_Review-g294265-d24963705-Reviews-Superbowl-Singapore.html):
  two complete games, 103 and 55, occupy a small part of a tall lane photograph.
  Both engines require review on both games: **0/2 exact**, zero incorrect
  automatic candidates. These are an honest remaining generalization limit.

The new originals, native observations and identities remain in the ignored local
lab. [Sanitized counts, source URLs and measurement hashes](evaluations/scoreboard-recovery-2026-11-05.json)
are tracked for reproducibility. No downloaded photo or native observation is
bundled in the app. Holdout families are not claimed to be wholly novel vendors;
their captures were unused during implementation.

## Validation and release limits

All **259 Flutter tests** pass, including 17 new layout, polarity/raster and panel
segmentation tests. They cover conflicting totals, missing rolls despite matching
checkpoints, footer identities, a later player's band, sparse evidence, exact name
joins and real versus estimated native header boxes. All 16 lab safety/training
tests pass. `flutter analyze --no-pub` and `git diff --check` are clean.

The original-photo evaluator executes production Dart retries, segmentation,
parser and scoring over original bytes. Apple observations come from macOS Vision
using the shared iPad/macOS helper; Android observations come from the production
ML Kit helper on an isolated Android 17 emulator. Exact-request caches include
original bytes, native/runtime fingerprint, aspect, crop regions and context.
Cached elapsed times are not a camera-to-import latency benchmark. An initial
Apple cell request failed during exploration and succeeded on retry; final paired
and holdout reports contain no native errors.

Installed iPadOS and physical Samsung capture, latency and import checks remain
necessary for device acceptance. The Samsung was not visible to ADB during these
checks. The recognition implementation itself did not change the version or
publish a build. In the subsequent owner release, **0.1.17 (18)** was built and
uploaded for iPad and native Mac; both were verified as **Testing in Owner
testing** on November 5, 2026. See [the release record](TESTFLIGHT.md). This
distribution does not add physical-device acceptance evidence.
