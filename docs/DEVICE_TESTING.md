# Device testing and owner installations

The Samsung has owner build **0.1.9 (10)**; the last verified local Mac/iPad installations are **0.1.7 (8)**. Both Apple 0.1.10 (11) builds are available in owner TestFlight and submitted for external beta review. A physical TestFlight installation has not been verified. Repeat this checklist on the distribution-signed candidate and record its exact version. Current distribution gates and archive evidence are in [TESTFLIGHT.md](TESTFLIGHT.md).

Start with the Samsung Galaxy Z Fold 8, then repeat the camera, import, sharing, and accessibility checks on a physical iPad and a supported Mac. Current automated checks are described in [development status](DEVELOPMENT.md). The Samsung was installed with build 0.1.4 (5) and supplied the first real-photo regression. This checklist separates further hardware checks from automated evidence.

## Verified Samsung update — October 27, 2026

Updated the Samsung Galaxy Z Fold 8 (SM_F971U1) in place from **0.1.7 (8)** to **0.1.9 (10)** at the owner's request. The installed old APK and final normal-entry-point APK use the same development signing certificate. `adb install -r` succeeded; the activity launched with a running app process. The installed APK SHA-256 matches the verified release artifact exactly. No uninstall, app-data clearing, saved-game change, or outgoing message was performed.

Protected private snapshots before and after startup have identical SQLite logical dumps and pass integrity checks: **3 alleys, 2 balls, 1 session, 3 games**, with profile and draft settings unchanged. The previous APK, data snapshots and comparison evidence are retained under ignored `build/owner-updates/0.1.9/samsung/`. The app was left open. Normal-entry-point installation and startup also passed on the isolated emulator. Google Chat composer acceptance remains unverified; the separate-UID Android receiver tests are described in [Android sharing](ANDROID_SHARING.md).

## Earlier Samsung update — October 25, 2026

The Samsung Galaxy Z Fold 8 (SM_F971U1) was updated in place from **0.1.6 (7)** to **0.1.7 (8)**. The normal `lib/main.dart` debug APK was rebuilt with the final Joe Steinbring/jws.dev support information. The installed and new APK signing certificates matched, both bundled documents matched source, installation succeeded with `adb install -r`, and the new activity launched with a running app process. The original install time was retained; no uninstall or app-data clearing was performed.

Private before/after app-data snapshots and SQLite integrity/record comparisons verified **3 alleys, 2 balls, no sessions/games**, and all profile/draft fields unchanged. The original APK and app data are retained under ignored `build/owner-updates/0.1.7/samsung/`. No game was saved, discarded, or shared during the update. This installation check does not add new camera, recognition-accuracy, recipient-sharing or accessibility evidence.

## Verified Mac/iPad update — October 25, 2026

Normal `lib/main.dart` release builds of **0.1.7 (8)** were installed in place and launched on this Mac mini and the owner's iPad Air 11-inch (M3), iPadOS 27.0.1. The iPad was updated from 0.1.4 (5) using the existing Apple Development identity/team and a verified device-covering profile. The Mac was updated from 0.1.6 (7) using its verified owner-only package; its previous application bundle was retained privately for rollback.

Before/after SQLite comparisons verified every record, profile and draft unchanged. The iPad retains **3 alleys and 2 balls**, with no sessions/games; the Mac journal remains empty. The updated iPad process remained running. The Mac home screen and Settings were inspected, including **Version 0.1.7 (build 8)**, new guide/privacy controls and logo. Private snapshots/install logs are under ignored `build/owner-updates/0.1.7/`. No game was saved or shared during this installation. This verifies owner installation/launch/data preservation, not the remaining camera, sharing, accessibility or TestFlight acceptance checks.

## Previous branding update — October 25, 2026

Version 0.1.6 (7) was installed on the Samsung and Mac in the previous update. The pointing bowler is used in launcher icons, app headers/navigation, Settings and recap images. My Bag symbols and ball illustrations show three finger holes with no seam. A live native preview showed the production shell in light and dark themes; the installed Mac header and My Bag empty state were inspected. All 103 unit/widget checks and normal native builds passed.

Before/after comparisons verified unchanged records, profile and draft on both devices. Samsung still has 3 alleys, 2 balls, 1 session, no saved games and its complete unsaved photo draft. No user result was saved or shared during this branding update. Camera/recognition and recipient integration coverage below remains labeled by its original build.

## Verified update evidence — October 25, 2026

Build 0.1.5 (6) was installed in place on the Samsung (Android 17 / SM_F971U1) and this Mac. Read-only before/after phone snapshots verified unchanged alleys, balls, session, profile and saved history. Resume of the owner's retained blank draft produced all ten correct deliveries and score 90 while preserving lane, ball selection, primary ball and notes. The game was left unsaved for the owner. Original photos and snapshots are private ignored build output.

The Mac package launched successfully after strict signature and sealed owner-policy verification. An isolated Android emulator verified **Share image → AeroSloth → Compose** with an image attachment and identical received PNG; no public content was sent. This does not claim new camera capture, TalkBack/VoiceOver or every recipient app was tested.

## Install and preserve data

- Use the packaged **Android debug APK** for this first local test. Public/store release signing is a separate setup task.
- If an earlier version contains bowling history, export a JSON backup first. Update in place with the same development signing key. A signature mismatch is a reason to inspect signing, not to uninstall and erase data automatically.
- Confirm the intended version/build after updating in place (currently 0.1.9/10 on Samsung; the last verified local Mac/iPad installs are 0.1.7/8); retain existing alleys, balls, sessions and drafts.

## First complete session

- Add the bowler name and scoreboard aliases. Add an alley by name/city search, confirm its address, and select a map pin. Try a manual alley with networking disabled. Try Enter coordinates with the keyboard and TalkBack; save an existing search result from the map and confirm the map closes.
- Add a ball from manufacturer/model suggestions, then a custom model. Add a second ball. Verify everything remains after closing/reopening.
- Start practice or league, choose alley/lane, and record a manual game. Check a strike, spare, open frame, and valid tenth-frame fills against a known scorecard.
- Tag both balls, select a primary ball, then untag it. Confirm the primary selection clears and another ball can be chosen.
- Save, edit, finish the session, and inspect history, visit/ball counts and calculated statistics.

## Camera, gallery, and local recognition

- Photograph an actual final scoreboard using **Scan scoreboard**. Cancel once, then complete a capture. Test the installed camera app's permission-denied/retry behavior if offered.
- Import a gallery image; cancel once, then select it again. Include JPEG and any camera format actually enabled on the device, portrait/landscape EXIF orientations, and a large photo.
- Verify automatic name/row selection, or select the correct row when ambiguous, and compare **every delivery**, tenth-frame fill and scratch total with the source. Correct every mismatch. Record the scoreboard layout and corrections needed; synthetic test success is not evidence of real-photo accuracy.
- Try an unclear image: manual frame entry must remain available. A mismatched displayed total or intermediate cumulative checkpoint must require explicit review before saving.
- Disable networking and repeat import/recognition with a local photo. Recognition must remain available without a model download or cloud service.

## Interruption and fold/window behavior

- While the camera/gallery app is open, background TallyBowl and return. Separately test Android activity/process recreation during picking using development tools; do not assume an ordinary back press simulates process death.
- Close/reopen during recognition or row review: the retained photo should reopen for review. Explicitly cancel review: the pending photo draft should clear.
- Type partial frames, leave the editor, reopen the app, and resume. Saved history must remain unchanged until a complete game is saved.
- Move between cover and unfolded displays while editing frames, reviewing a photo, opening suggestions, and viewing a recap. Try rotation and multiwindow. Check retained text/focus, scrolling, navigation, keyboard visibility and reachable Save controls.
- Use 150–200% system text/display settings and light/dark appearance. Check all five sections and Settings. With TalkBack enabled, navigate the scorecard: each frame should announce number, marks and cumulative score; chart labels should announce values.

## Recap and backups

The Android 17 emulator share sheet handed a real PNG to AeroSloth and its normal composer displayed the image attachment. See [handoff evidence](SHARING_VERIFICATION.md). Repeat with the owner's installed recipient accounts and platform share extensions as part of hardware testing.


- Finish the session, inspect the branded image and privacy switches, then export to a local destination. Test the native share sheet and cancel it. Send to another person only when the owner chooses to do so.
- Turn Date off and check that the exported attachment is named `tallybowl-recap.png`, with no date in the image.
- Confirm the recap contains the correct scores, chosen details, TallyBowl branding and tallybowl.jws.app, with no clipping or hidden private details.
- Export JSON and both CSV formats. Reopen the JSON on the same device, confirm replacement, and verify inventory, history and unfinished frames. Source photos are intentionally excluded from portable backups.
- Verify the before-restore recovery action is available after reopening. Preserve the original export outside the app before experimenting with replacements.

## Test log

For each failure, record app/build, device/OS, folded/unfolded or window size, system text/theme, steps, expected/actual behavior, and whether it repeats after reopening. Use a copy of a scoreboard photo with permission; omit other bowlers' names from shared bug reports.

Public release additionally requires real-photo accuracy evaluation, supported-version coverage, protected signing/provisioning/notarization, and map/search capacity/attribution decisions. These are not prerequisites for installing the local owner-test APK.
