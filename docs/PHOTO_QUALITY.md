# Photo quality and retake prompt

When a photo cannot be imported automatically, the review page checks for
problems another photo could fix and says what it found. The prompt offers
**Take another photo** or **Choose another**. **Use this photo anyway** and the
close button dismiss it, keeping the photo, row choice and manual entry. A photo
that imports automatically is never assessed, and the check never changes a
recognized row or score.

The checks are shared Dart code, so Apple Vision and ML Kit behave alike; only
the native text boxes, which both engines return, locate the scoreboard area.

| Issue | Measurement | Threshold |
| --- | --- | --- |
| No scoreboard text | No text box was recognized | Any; whole-scene blur and contrast are then not used |
| Scores too small | Median text height in the 4096-pixel space both engines read | Under 36 px |
| Blurry | 99th-percentile luminance step, measured at a standard 24 px text height, relative to the 5th–95th percentile contrast | Under .24, when text is at least 36 px |
| Dim scores | 5th–95th percentile luminance spread in the scoreboard area | Under 80 |
| Name missing | No row matches the saved name or any scoreboard alias | When any text was found |

## Calibration

Measured on the private 64-photo corpus with the production recognizer output
from both engines:

- Every photo that imports has text of at least 24 px, sharpness of at least .36
  and contrast of at least 100. Failing online thumbnails measure 16–30 px.
- Six of the owner's league and practice photos that import were blurred with a
  Gaussian radius of 4, 8, 12 and 18 % of their text height and read again with
  local Apple Vision. All imported at 4 % (sharpness .25–.35); none imported at
  8 % (.14–.23) or beyond, where text often disappears entirely.
- The same six were darkened to 35, 20 and 12 % brightness. Half still imported
  at 35 % (contrast 50–65); half failed there (48–77) and all failed below
  (contrast 16–44).

Two candidate checks were rejected after looking at the flagged photos.
Counting clipped white pixels flagged white-strip and graphic scoreboard
designs that had no glare. A low median brightness flagged sharp photos of
dark-themed monitors. Neither is used.

On the corpus, the prompt appears for 23 of the 34 (Apple) and 23 of the 31
(Android) complete rows that are not imported, almost always because the
scores are too small or the name was not found. It stays silent for the owner's
failing league photos whose text is large, sharp and high-contrast, where a
retake would not help.
