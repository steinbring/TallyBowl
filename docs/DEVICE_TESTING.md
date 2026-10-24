# Owner testing — build 0.1.4 (5)

Start with the Samsung Galaxy Z Fold 8, then repeat the camera, import, sharing, and accessibility checks on a physical iPad and a supported Mac. Current automated checks are described in [development status](DEVELOPMENT.md). This checklist is preparation; no physical phone has been installed or tested yet.

## Install and preserve data

- Use the packaged **Android debug APK** for this first local test. Public/store release signing is a separate setup task.
- If an earlier version contains bowling history, export a JSON backup first. Update in place with the same development signing key. A signature mismatch is a reason to inspect signing, not to uninstall and erase data automatically.
- Confirm version 0.1.4/build 5 in the installed package. Initial installation/USB setup will be handled with the owner in the next step.

## First complete session

- Add the bowler name and scoreboard aliases. Add an alley by name/city search, confirm its address, and select a map pin. Try a manual alley with networking disabled. Try Enter coordinates with the keyboard and TalkBack; save an existing search result from the map and confirm the map closes.
- Add a ball from manufacturer/model suggestions, then a custom model. Add a second ball. Verify everything remains after closing/reopening.
- Start practice or league, choose alley/lane, and record a manual game. Check a strike, spare, open frame, and valid tenth-frame fills against a known scorecard.
- Tag both balls, select a primary ball, then untag it. Confirm the primary selection clears and another ball can be chosen.
- Save, edit, finish the session, and inspect history, visit/ball counts and calculated statistics.

## Camera, gallery, and local recognition

- Photograph an actual final scoreboard using **Scan scoreboard**. Cancel once, then complete a capture. Test the installed camera app's permission-denied/retry behavior if offered.
- Import a gallery image; cancel once, then select it again. Include JPEG and any camera format actually enabled on the device, portrait/landscape EXIF orientations, and a large photo.
- Verify the intended bowler alias, select the correct row and compare **every delivery**, tenth-frame fill and scratch total with the source. Correct every mismatch. Record the scoreboard layout and corrections needed; synthetic test success is not evidence of real-photo accuracy.
- Try an unclear image: manual frame entry must remain available. A mismatched displayed total must require explicit review before saving.
- Disable networking and repeat import/recognition with a local photo. Recognition must remain available without a model download or cloud service.

## Interruption and fold/window behavior

- While the camera/gallery app is open, background TallyBowl and return. Separately test Android activity/process recreation during picking using development tools; do not assume an ordinary back press simulates process death.
- Close/reopen during recognition or row review: the retained photo should reopen for review. Explicitly cancel review: the pending photo draft should clear.
- Type partial frames, leave the editor, reopen the app, and resume. Saved history must remain unchanged until a complete game is saved.
- Move between cover and unfolded displays while editing frames, reviewing a photo, opening suggestions, and viewing a recap. Try rotation and multiwindow. Check retained text/focus, scrolling, navigation, keyboard visibility and reachable Save controls.
- Use 150–200% system text/display settings and light/dark appearance. Check all five sections and Settings. With TalkBack enabled, navigate the scorecard: each frame should announce number, marks and cumulative score; chart labels should announce values.

## Recap and backups

- Finish the session, inspect the branded image and privacy switches, then export to a local destination. Test the native share sheet and cancel it. Send to another person only when the owner chooses to do so.
- Turn Date off and check that the exported attachment is named `tallybowl-recap.png`, with no date in the image.
- Confirm the recap contains the correct scores, chosen details, TallyBowl branding and tallybowl.jws.app, with no clipping or hidden private details.
- Export JSON and both CSV formats. Reopen the JSON on the same device, confirm replacement, and verify inventory, history and unfinished frames. Source photos are intentionally excluded from portable backups.
- Verify the before-restore recovery action is available after reopening. Preserve the original export outside the app before experimenting with replacements.

## Test log

For each failure, record app/build, device/OS, folded/unfolded or window size, system text/theme, steps, expected/actual behavior, and whether it repeats after reopening. Use a copy of a scoreboard photo with permission; omit other bowlers' names from shared bug reports.

Public release additionally requires real-photo accuracy evaluation, supported-version coverage, protected signing/provisioning/notarization, and map/search capacity/attribution decisions. These are not prerequisites for installing the local owner-test APK.
