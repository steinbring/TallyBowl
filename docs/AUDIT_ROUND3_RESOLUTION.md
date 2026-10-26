# Round-three audit verification and disposition

Verified October 25, 2026 against the actual source after TestFlight account setup. The supplied report is review input; its recommendations were checked rather than applied automatically. This document records dispositions, not a claim of broad recognition accuracy or completed physical acceptance.

| Finding | Independent verification | Disposition |
| --- | --- | --- |
| SEC-01: Apple account-state JSON | App/team/group identifiers are not credentials, and the file contained no private email, phone or key. It was intentionally recorded during setup, but placing evolving account state beside committed release templates creates avoidable future hygiene risk | Moved the local record to ignored `build/testflight/setup/app-record.json`, removed the tracked copy and explicitly ignored its old path. Public identifiers needed to reproduce the release remain in the runbook. No credential exposure or history rewrite is warranted |
| COM-01: light scorecard miss recovery | Production Apple bridge returned no stroke for a black dash on white paper; the monitor case passed. The before-change integration run had **8 passing / 2 failing** raster cases (paper dash and candidate-limit cases) | Both native detectors now run separate light/dark neutral-pixel masks, excluding transparent pixels. Geometry, component limits and score-validation safeguards remain. The identical ten-case raster suite passes through both real native bridges |
| COM-02: F/X in names | Grid-specific regressions reproduced **FOX** and **FX** failures. **FELIX** and **XAVIER** already passed because the old unanchored regex could match other consecutive letters. The report's blanket “never” claim is too broad; the simple row fallback can also mask some grid failures | Shared name-candidate helper now accepts F/X inside multi-letter names and excludes standalone marks and metadata labels. Both the grid and simple-row parser use it. Tests assert the actual grid/checkpoints, not merely a fallback row |
| MNT-01: duplicated native morphology | Swift and Kotlin intentionally operate on their platform rasters, but their tuning had no shared executable contract | Added [the parameter specification](RECOGNITION_STROKES.md) and one shared Flutter integration fixture suite that invokes each production bridge. Run both targets when tuning either implementation; no CI execution is claimed |
| MNT-02: repeated source decoding | Confirmed up to four sequential channel calls, each with the bounded original bytes, early exits and optional-pass fallback. This is a bounded performance tradeoff, as the supplied report also states | Accepted for this beta; added a regression assertion on the four-call bound and documented the cost. Decode caching/session changes are deferred pending older-device measurements; no correctness or security fix requires that protocol change |

## Verification evidence

- Before-change grid tests: only FOX and FX failed once the test was narrowed to grid output. Metadata labels and FELIX/XAVIER passed.
- After-change `flutter test`: **117 passed**, including existing monitor/checkpoint/auto-fill and conflict safeguards.
- `flutter analyze`: **no issues**.
- `flutter test integration_test/dash_stroke_test.dart -d macos`: **10 passed** through Apple Vision.
- The same command with isolated Android `emulator-5554`: **10 passed** through bundled ML Kit. No populated owner installation was replaced with the harness.
- The original private monitor photo was rerun through the updated Apple Vision helper plus Dart orchestration and the updated bundled ML Kit pipeline on the isolated emulator: both retained the exact ten frames, all checkpoints, total **90**, and automatic selection. The photo and host-only diagnostic harnesses remain ignored local output.
- Native cases cover both polarities: isolated dash, blank crop, grid lines, out-of-band marks and largest-three candidate limit, with returned stroke geometry asserted.

Logs are ignored under `build/audit3-*`. Controlled raster tests do not replace permissioned real paper/monitor photos, physical camera/recipient sharing, VoiceOver, backup/upgrade and interruption acceptance. Those remain tracked in [device testing](DEVICE_TESTING.md).

## Separate Apple delivery issue

Apple's processing email for Mac **0.1.7 (8)** reported **ITMS-90284** for five Swift Package resource bundles retaining a different certificate from the app's provisioning profile. Xcode's successful upload and a valid deep signature did not establish certificate consistency across nested resources. The iPad build processed and the owner was invited. Mac **0.1.8 (9)** fixes it using app-target signing overrides. The new preflight reproduces all five old mismatches and passes both new exports. Apple processed the corrected Mac build successfully; both build-9 platform builds cleared compliance and are assigned to the private owner group. Final rebuilt version, checks and availability are recorded in [the release runbook](TESTFLIGHT.md).
