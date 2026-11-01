# October 31 practice scoreboards

The three original 4000×3000 JPEGs were independently transcribed before checking recognition. The totals and every cumulative checkpoint agree with these ten-pin deliveries:

| Original | Deliveries, frames 1–10 | Scratch total |
| --- | --- | --- |
| `20261031_173524.jpg` | `X 7/ 7/ 72 71 35 18 9- 6/ 41` | 116 |
| `20261031_175529.jpg` | `72 9- 6/ 36 -6 5/ X 72 8- X9/` | 122 |
| `20261031_181108.jpg` | `11 9- 9- 7- 6- 8/ -- 63 9/ 36` | 74 |

## Cause and implementation

Both native pipelines previously failed to produce an exact automatic frame import for all three originals. The shared fallback also failed: the light lettering carries a blue/purple cast, while broader foreground masks connect it to the cartoon. The old enclosing-component rule could discard an actual 8/9 or 2 when a bright background island appeared inside its outline. Native OCR also confused the wide-footed 1 with I/T; the bundled templates lacked that shape.

The fix adds a measured color-normalized reading, removes illustration connected to crop edges and checks for a readable digit before discarding an enclosing split ring in this reading. The original neutral-mask reading remains an independent candidate. Six additional numeral-1 templates use Roboto Slab, with license and provenance bundled; all original templates and confidence thresholds remain unchanged.

A repeated footer name could previously prevent the regional retry from reaching the actual player row. Retry selection now considers the next header-supported layout when the first lacks physical rulings. Sparse header positions can also compress frame spacing; six agreeing rulings can correct a small linear drift. Dense header layouts retain their existing pitch, which preserved two earlier native matches caught during regression testing.

Improved glyph coverage also exposed a validation gap: a total-only OCR pass could reuse another pass's table as a primary reading. A named primary now needs either its own header fit or three agreeing cumulative checkpoints including the tenth. If a pass omits the name, six agreeing checkpoints including the tenth must be corroborated by six in another pass that actually observes the name at the same position. An explicit different name blocks that recovery. This preserves the earlier 76-pin Apple photo, where one pass misses the large name. Cross-pass total borrowing still requires its existing six-checkpoint corroboration. No roll sequence is inferred from a total, and native recognition remains bounded to four calls per photo.

## Verification method

Fresh Apple observations come from the production shared Swift Vision helper on this Mac. Fresh Android observations come from the production bundled ML Kit bridge on an isolated Android 17 emulator. The production Dart `PhotoService` executes its actual retries, pixel fallback and automatic-row selection against the original JPEG bytes. Results compare every frame, not merely the displayed total. Earlier complete games that previously imported exactly must remain exact; unfinished, conflicting and unsupported games must not become incorrect automatic imports.

Permissioned committed fixtures contain only the score-table crops, artificial Bowler labels and transformed native observations. Original JPEGs, names, EXIF, diagnostic targets and native logs remain private under ignored `build/practice-oct31/`. The online images remain private and are not added to the app package.

## Final results — November 1, 2026

All three new originals recover every frame and the scratch total on **both Apple Vision and Android ML Kit**, using four native calls each. A separate diagnostic runs the complete Flutter/native/pixel pipeline inside the Android emulator, recovering the same exact results in approximately 5.0, 4.9 and 2.1 seconds respectively.

The broader rerun covers **51 row cases per engine across 34 retained original images**: the 30 earlier images, the earliest 90-pin photo and these three new photos. All **102 native assertions pass**, preserving every previously exact import. No incorrect automatic import was observed. Cases that remain unfinished, unsupported or uncertain are expected to require review; a passing assertion does not mean every image imports automatically.

| Corpus | Apple exact automatic results | Android exact automatic results |
| --- | --- | --- |
| Earlier 20 personal originals (18 complete) | 17/18 complete | 18/18 complete |
| Earlier 89/109 practice photos and earliest 90-pin original | 3/3 | 3/3 |
| Three new October 31 originals | 3/3 | 3/3 |
| First four online images (9 complete standard ten-pin rows) | 1/9 | 0/9 |
| Second four online images (8 complete supported rows) | 0/8 | 0/8 |

Android additionally recovers the earlier 103- and 112-pin personal photos. Apple's earlier 114-pin photo still requires review. Tiny online photos and unfamiliar layouts remain a significant gap; these results do not establish perfect live recognition or general accuracy.

All **239 unit/widget tests pass**, and static analysis is clean. This includes all new engine fixtures, wrong-total and wrong-name checks, conflicting cross-pass identities, preserved checkpoint/handicap safeguards and the actual import/resume → editor → saved-game flow. Normal Android debug and Mac release builds pass; their packages include the new template license and exclude photo fixtures and private diagnostic targets. The normal app is restored on the isolated emulator after verification.

This fix is local development work. It has not updated the Samsung installation or TestFlight build 15. Physical Samsung/iPad camera capture and installed Apple beta recognition remain separate checks.
