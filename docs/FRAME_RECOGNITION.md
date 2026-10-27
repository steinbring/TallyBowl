# Frame recognition

All recognition runs on the device. Android uses bundled Latin ML Kit; iPad and Mac use Apple Vision. `PhotoService` first keeps the existing bounded OCR/aspect/regional pipeline (at most four native calls). A complete validated name match exits early.

Some QubicaAMF monitor photos produce readable totals but omit isolated strikes, circled split digits, and short misses. Treating those text rows as frame records left empty inputs. The shared `FrameGlyphReader` fallback now reads the photographed delivery ink directly when OCR remains incomplete. It requires a matching profile alias and at least six consistent numbered frame headers before decoding a second bounded raster (longest side at most 4096). Classification runs in a worker isolate to keep the editor responsive. Flutter's codec applies EXIF orientation, including the upside-down EXIF orientation in the 109-pin regression photo.

Complete native OCR frame readings inside these bounds are retained before glyph matching. The header centers locate columns; the name/header vertical separation locates the delivery band. This avoids using the right edges of centered cumulative numbers as frame boundaries or clipping the tops of delivery symbols. Light, low-chroma ink is isolated from the saturated monitor background. Four-connected components separate characters; an enclosing split ring is removed only when it contains a separate ink component. Miss marks require a compact horizontal component in the delivery band. Digits, X, and / are compared with 24×32 binary templates rendered from OFL Roboto at six weights. Unknown shapes remain empty. Foul glyphs and unfamiliar fonts continue through native OCR/manual review.

Acceptance requires intersection-over-union of at least .68 and a .06 lead over other characters. An independently observed native OCR character anchored inside a component is retained, including when color thresholding fragments the photographed ink. Conflicting native observations make that frame uncertain; templates fill omissions rather than overwrite known marks. No search chooses marks to fit a total. A full legal ten-pin sequence must match the independently observed final total, plus every cumulative checkpoint available from the native grid. Multiple matching rows still require selection. The photo and all ten filled inputs remain available for visual review before saving.

`assets/recognition/glyphs.json` is a small bundled template set, not a downloadable service or remote model. Its source URL, source-font SHA-256, and OFL license are recorded alongside it. Regenerate using `tool/generate_score_glyphs.py` with the Google Fonts Roboto variable font and Pillow. The full source font is not bundled. Settings → Licenses includes the template license.

## Regression evidence and limits

`test/fixtures/practice_89.png` and `practice_109.png` contain only permissioned score-table crops with an artificial bowler label. The original photos, original name, venue/background, EXIF, and native diagnostic logs are not committed or distributed. The corresponding Apple/Android JSON records preserve native OCR geometry after the crop transform. Tests verify every delivery, mismatched totals, incorrect names, native-mark conflicts, and the actual import/resume → editor → saved-game flow. Private end-to-end checks also run the complete production pipeline against both original JPEGs on Mac and an isolated Android emulator.

Expected deliveries:

- 89: `X 8- 53 36 6- 8- 11 71 X 33`
- 109: `81 9/ 9- 63 71 7- X 7- X 7-`

These cases expand coverage; they do not establish accuracy for all fonts, glare, occlusion, paper scorecards, multiple bowlers, or perspective. Keep manual review available and add independently labeled examples before widening confidence thresholds.
