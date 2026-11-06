# TestFlight metadata

Current build: **0.1.17 (18)** for iPad and native Mac, both **Testing in Owner testing**, verified November 5, 2026. Build-specific notes and the owner-approved encryption/France answers are saved on both builds. This release was assigned only to Owner testing. See the [runbook](TESTFLIGHT.md) for evidence and limits. Existing group membership is retained. Beta description, feedback email and private reviewer contact/instructions remain in App Store Connect; sign-in is not required.

## Public contact and remaining account fields

- Public developer/support name: **Joe Steinbring** (approved by the owner).
- Public support/contact URL: **https://jws.dev/contact** (owner-approved; returned HTTP 200 and the Joe Steinbring contact page on October 25, 2026).
- TestFlight feedback email: **configured in App Store Connect** with owner approval; private account contact is intentionally omitted here.
- Beta reviewer contact name: **Joe Steinbring**; email and phone were supplied/approved by the owner and saved privately in App Store Connect. Do not commit private contact details.
- Privacy policy URL: `https://tallybowl.jws.app/privacy` — planned and still unavailable. The current policy is bundled offline in Settings. Publish and verify the hosted copy before expanding the beta; do not enter a nonexistent URL as a live policy in Apple metadata.
- Support URL: `https://jws.dev/contact`. The app's bundled user guide remains available offline in Settings.
- Marketing URL: `https://tallybowl.jws.app` — planned, not currently hosted.
- Export-compliance and privacy-label decisions: see [runbook](TESTFLIGHT.md); do not infer them from this draft.

## Beta description

TallyBowl! records how you bowled, tonight. Keep a personal ten-pin journal with your balls, alleys, league/practice sessions, frames and notes. Photograph or import a final scoreboard; on-device recognition helps fill your frames for review. Track scores and equipment usage, then share a branded recap image through the system share sheet.

This beta stores your journal locally, has no login or subscription, and includes backup/restore. Map/search requests need internet; saved alleys and recording work offline. Recognition still needs testing on additional scoreboard layouts. Compare every delivery with the source before saving.

## What to test

Build 0.1.17 (18) improves scoreboard row alignment, light/dark and mixed delivery ink, and current-game scratch-total selection. Existing successful photo imports remain covered by regression tests; unfamiliar or small scoreboards may still require manual correction.

Please test importing a final scoreboard with your saved name/alias, compare all ten frames and the scratch total, and resume an interrupted photo draft. Test offline recognition, multiple bowlers, splits, spares, strikes and tenth-frame fills. Confirm uncertain/incomplete images require review rather than inventing rolls. Also check session history, manual scoring, Share image, Export image, dark mode, large text and VoiceOver. Journal and backup formats are unchanged.

Keep a backup before testing restore or deletion. Report version/build, device/OS, expected and actual results. Use permissioned, redacted photos in feedback.

## Beta review notes

No account, demo credentials, purchase or hardware accessory is required. Camera access is optional. On first launch, open Settings to set a bowler name and aliases, add an alley manually in Alleys and a ball in My Bag, then start practice in Tonight. To test without a scoreboard, use manual frame entry: `9-` in each of ten frames gives a 90 game. Save, finish the session and open its recap to test native image sharing. Manual recording works in airplane mode.

For photo recognition, import a clear final ten-pin scoreboard including the bowler name, delivery marks, and all ten frames. A unique alias match with validated complete frames fills the editor; uncertain images request review/correction. Recognition uses Apple Vision on iPad/Mac and does not upload photos to an AI service. The app's Privacy policy and User guide are in Settings and available offline.

The iOS target is iPad-only. macOS uses a separate native Flutter target, not the iPad binary. Review each platform build's camera, sharing and sandbox behavior separately.

## Known beta limitations

The [twelve-photo evaluation](PHOTO_CORPUS_RESULTS.md) and earlier monitor regressions provide development evidence, not general recognition accuracy. Sparse, distorted or unfamiliar layouts may need manual marks. One image is processed at a time. There is no sync, iPhone support, handicap scoring or retained photo library. JSON backups omit original photos. Public map/search services have no availability guarantee; manual alley entry remains available. Android ML Kit diagnostics apply to Android builds, not Apple builds. The Android PNG transport passes separate-UID receiver tests; Google Chat composer verification on the Samsung remains pending.
