# TallyBowl — Round-2 Audit (post-fix review)

- **Date:** 2026-10-24
- **Input:** Round-1 report (`AUDIT_REPORT.md`) + the other AI's documented resolutions (`docs/AUDIT_RESOLUTION.md`).
- **Method:** Re-verified the changed files at `HEAD` (`20f23cd`) and audited the new code for regressions. No code was modified.

## 1. Verdict on prior findings

Most round-1 items were legitimately addressed, and several fixes are genuinely good (dark theme, `ui/layout.dart` shared breakpoints, removal of the `ValueKey` dropdown workaround, scaffold-messenger captured before pop, `package_info_plus`-driven User-Agent, LRU cache comment + promotion, extracted `FrameGrid`/`ScoringSummary`, native verify script). The claims that `flutter analyze` / 65 tests / emulator+simulator checks pass are plausible and match the committed docs.

Two important caveats below.

## 2. New / remaining issues (verified against current code)

### N-01 — Android release variant is now UNSIGNED (regression) — P1
- **File:** `android/app/build.gradle.kts`
- **Verified:** `release { signingConfig = null }` (line 35).
- **Issue:** Round 1 found release was debug-signed. The fix changed it to `null`, which produces an **unsigned** release APK. `flutter build apk --release` will emit an APK that cannot be installed (and may warn/error), and `flutter build appbundle --release` is unusable until a real keystore exists.
- **Recommendation:** Restore an explicit signing configuration. If production keys are intentionally deferred, keep debug signing for local release testing OR document that `--release` is unsupported until a keystore is supplied — do not leave `null` silently.

### N-02 — Resolution doc's SEC-01 claim contradicts audit evidence — P2 (accuracy)
- **Files:** `docs/AUDIT_RESOLUTION.md` (SEC-01 row).
- **Verified:** The resolution states the debug-signing configuration "was absent in the starting checkout" and cites commit `58d5a50`. The round-1 verification grep found `signingConfig = signingConfigs.getByName("debug")` at `android/app/build.gradle.kts:36`.
- **Issue:** Either the code changed between the round-1 evidence and the resolution, or the disposition is inaccurate. Regardless, the *current* state (`null`) is the new problem in N-01.
- **Recommendation:** Correct the disposition wording so the record reflects that a debug-signing config existed at audit time and was subsequently removed/replaced.

### N-03 — Local Mac packaging disables library validation — P2 (security)
- **File:** `tool/package_macos_local.sh`
- **Verified:** The script injects `com.apple.security.cs.disable-library-validation = true` into an ad-hoc local copy, while guarding against re-signing team/distribution apps (`TeamIdentifier=not set` / `Signature=adhoc` checks).
- **Issue:** This deliberately relaxes hardened-runtime library validation for owner-test builds. It is guarded and documented, but the produced `.app` will run frameworks that hardened runtime would otherwise reject — a supply-chain/security consideration if the artifact ever leaks beyond the owner.
- **Recommendation:** Keep the guard, and add an explicit warning in the archive's filename/manifest that the build is not hardened and must not be distributed.

### N-04 — App startup now awaits platform metadata — P3
- **Files:** `lib/main.dart`, `lib/src/config.dart`.
- **Verified:** `main()` now `await AppConfig.initialize()` before `runApp`, which awaits `PackageInfo.fromPlatform()` (a platform-channel call). There is a try/catch, so failure is non-fatal, but startup latency now depends on plugin registration on first frame.
- **Issue:** A hung/slow platform channel delays first paint (bounded only by the plugin's own timeout, if any). Minor, but it moves a network-free journal's cold start onto a native call.
- **Recommendation:** Acceptable; optionally fire-and-forget the UA refresh after `runApp` so first paint never waits on metadata.

### N-05 — Photo review persisted before recognition — verify on device — P2 (verify)
- **Files:** `lib/src/recognition/photo_service.dart`, photo-review/recovery path.
- **Verified:** The resolution states pending photo review is now persisted **before** recognition and stripped from portable backups.
- **Issue:** This is a more complex state machine (retain → persist draft → recognize → resume/cancel). Automated tests are claimed, but the failure/edge matrix (recognition throws, app killed mid-recognition, orphan cleanup with the new retained path) still needs physical-device confirmation, consistent with the unchanged "physical-device checklist" gate.
- **Recommendation:** Exercise kill/reopen during recognition on Android and iPad before considering the fix complete.

## 3. Confirmed resolved (spot-check)

- **SEC-05** — `AppConfig.initialize` + `package_info_plus` User-Agent: present and sanitized.
- **COM-04/COH-04** — `initialValue` retained; `ValueKey(_primary)` recreation removed (`game_editor.dart`).
- **COH-05** — scaffold-messenger captured before pop (per resolution; behavior covered by test claim).
- **COM-03** — tile attribution/URL now configurable (`TALLYBOWL_TILE_ATTRIBUTION` / `_URL`).
- **A11Y-01/A11Y-04** — dark theme and scorecard frame semantics added.
- **MNT-03** — place-search cache has explicit insertion-order comment + LRU promotion.

## 4. Bottom line

The fix pass is high quality and resolved the majority of round-1 findings. The actionable new items are **N-01 (unsigned release — must fix)** and **N-02 (record accuracy)**, with N-03/N-04/N-05 as secondary. Physical-device camera/OCR/share/accessibility checks remain the standing release gate, unchanged.
