# Native miss-stroke recovery

Apple Vision and Android ML Kit can omit a visible miss mark. The bridges supplement OCR only inside requested frame crops; cumulative scores never create a delivery. `PhotoService` prefers complete OCR, preserves known marks, excludes strokes overlapping an observed symbol and requires legal frames. A row must also match its observed score checkpoints before automatic selection.

The Swift and Kotlin pixel implementations deliberately remain native to avoid transferring decoded rasters over the Flutter channel. Keep their parameters and behavior aligned using this specification and the **same** `integration_test/dash_stroke_test.dart` raster cases on both bridges:

| Step | Shared rule |
| --- | --- |
| Working raster | Downsample the crop only if its longest side exceeds 512 pixels; preserve aspect ratio |
| Foreground | Alpha at least 165 and channel spread at most 80. Two separate masks: light strokes have every RGB channel at least 165; dark strokes have every channel at most 90 |
| Horizontal filter | Keep runs of at least `floor(max(5, width × .06))` pixels; diagonal artwork should not join a dash |
| Components | Eight-connected flood fill, fresh visited mask for each polarity |
| Candidate | Width at least `max(5, width × .06)`; height 2 through 20% of the crop; aspect 1.6 through 8; center in the middle 25–75% vertically; occupied area at least 45% |
| Merge | Sort by top, merge fragments with at least 80% horizontal overlap and a vertical gap at most 8% of the original crop height |
| Output | At most three candidates, largest area first; map back to original crop coordinates and normalize through the bridge |

The fixture cases cover isolated marks, blank backgrounds, grid lines, out-of-band marks and the candidate limit, in both polarities. They call the production `recognizeText` channel with a frame region and assert only actual `stroke=true` observations, including their geometry. OCR text alone cannot make these tests pass. Use an **isolated Android emulator**, because Flutter integration tests install a test entry point under the app's bundle ID. Do not replace a populated owner's app with a test harness.

```sh
flutter test integration_test/dash_stroke_test.dart -d macos
flutter test integration_test/dash_stroke_test.dart -d <isolated-android-emulator-id>
```

Run both whenever changing either implementation. Then build distribution artifacts with the normal `lib/main.dart` entry point. These controlled rasters verify the heuristic and cross-platform protocol; they do not establish accuracy on arbitrary paper, glare, perspective, colored printing or unfamiliar scoreboards. Add permissioned real-photo fixtures as they become available.

## Recognition cost

`PhotoService.recognize` has at most four sequential native calls: initial OCR, optional aspect correction, at most 20 frame crops, and optional word-context correction. Each call currently decodes the bounded source anew. It exits early for a validated row and retains the original/manual review on optional-pass failures. The fixture-driven orchestration test asserts the four-call bound. Decode reuse is deferred until measurements on older target devices justify a cache/session protocol; no latency or broad accuracy claim is made.
