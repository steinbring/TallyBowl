# November 9 recognition verification

The release candidate uses recognition source **bc110a5** from the November 8
[gutter-mark correction](NOV08_PHOTO_EVALUATION.md). The source and template bank
were frozen before selecting and evaluating these four fresh online images.
No production recognition change or template tuning was made against this set.

## Fresh online evaluation

Visible deliveries and cumulative checkpoints were transcribed independently,
then validated with the ten-pin scorer before either native engine ran. A
successful complete game requires the correct bowler, every delivery in all ten
frames, and its scratch total. Reading only a total does not count.

| Source / layout | Complete games | Apple exact | Android exact | Result |
| --- | --- | --- | --- | --- |
| [Alain106, single row with name above and no numbered headers](https://commons.wikimedia.org/wiki/File:Score_d%27une_partie_de_Bowling.jpg) | 1 | 0 | 0 | Review |
| [由紀奈, Galaxy Bowling screen with two bands of five frames and stylized marks](https://commons.wikimedia.org/wiki/File:%E3%82%B9%E3%82%B3%E3%82%A2%E3%83%9C%E3%83%BC%E3%83%89.png) | 1 | 0 | 0 | Review |
| [Akame blog, small angled Round1 monitor with triangular marks and Japanese names](https://akameblog.hatenablog.com/entry/2014/06/11/022129) | 2 | 0 | 0 | Review |
| [Brunswick Sync team-game example](https://brunswickbowling.com/bowling-centers/equipment-parts-supplies/center-operations/sync/scoring) | 0; 6 unsupported individual rows | — | — | All six remain unselected on both engines |

Both engines recover **0/4 complete games** in this fresh set and produce **zero
incorrect automatic candidates** across its ten rows. Review is a safe outcome,
but it is not successful recognition. The team-game example assigns different
players to each five-frame half; these are not complete individual ten-frame
games. The other four games remain positive cases despite their reader failures.

The observed layouts expose limitations in numbered horizontal-grid detection,
separate name bands, unfamiliar symbols and small non-Latin text. This evaluation
does not isolate the contribution of each stage. Supporting them needs a separate
layout/symbol/identity change with paired preservation checks; lowering confidence
thresholds or deriving missing deliveries from totals would be inappropriate.

The four originals are distinct from the prior 51 photos by hash and visual
inspection. A search result identical to a retained four-row holdout was excluded
from the fresh count; an inaccessible image returning HTTP 403 was not tested.
The first frozen manifest remains private as `online-nov09/new.json`. After
inspection these ten rows were added to `online-nov09/corpus.json` as protected
regression data, alongside the prior 88 rows. Future unseen testing needs new
sources.

## Preserving the earlier photos

The prior 88-row / 49-photo corpus and previously inspected six-row / two-photo
holdout were rerun on each engine. **All 35 earlier exact complete-game imports
remain exact on both engines**, including the three clearer November 8 games
with totals 88, 115 and 117. The distant duplicate remains in review.

| Check | Apple | Android |
| --- | --- | --- |
| Prior corpus, exact complete games | 35/64 retained | 35/64 retained |
| Previously inspected holdout, exact complete games | 0/2; still review | 0/2; still review |
| Fresh complete games | 0/4 | 0/4 |
| Negative rows left unselected, all sets | 34/34 | 34/34 |
| Incorrect automatic candidates | 0 | 0 |

Across **104 rows from 55 originals per engine (208 native row checks)**,
there are no native failures and no row exceeds four native calls. The paired
preservation check passes without changing gold labels or production recognition.
The fresh sample is small and selected, so these counts are not a population
accuracy estimate.

All **286 Flutter tests and 16 lab safety/training tests pass**, and static
analysis is clean. These include the November 8 gutter-order, double-miss,
gutter-spare, conflicting-ink/total, identity and four-call service regressions.
[Sanitized counts and evidence hashes](evaluations/recognition-2026-11-09.json)
record the evaluated pipeline and native/template fingerprints.

## Scope and provenance

Native measurements execute the production `PhotoService`, reader and scorer
using macOS Vision with the shared iPad/macOS helper and bundled Android ML Kit
on a disposable Android 17 emulator. Exact native requests may reuse responses
only when image bytes, request arguments, native/runtime and source fingerprints
match. No diagnostic target is shipped in the app. These checks do not establish
physical iPadOS camera/gallery acceptance or predict every live-alley condition.

Originals, native OCR, labels and detailed work files remain under ignored
`build/recognition-lab/online-nov09/`. No downloaded image or private identity is
added to app assets or Git. The Alain106 image is CC BY-SA 4.0 and the 由紀奈 image
is CC0 1.0; the Brunswick and Akame blog examples are retained privately for this
evaluation without redistribution. Source pages, original-image URLs and byte
hashes are preserved in the local provenance record.
