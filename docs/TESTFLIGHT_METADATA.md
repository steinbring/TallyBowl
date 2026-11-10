# TestFlight metadata

Current release: **0.1.20 (21)** for iPad and native Mac. Both are **Testing** in
Owner testing and assigned to External testing with status **Waiting for Review**,
verified November 10, 2026. Automatic tester notification is enabled; external
access awaits Apple approval. Existing group membership is retained. Testing
notes and the owner-approved export-compliance answers are saved on both builds.
See the [release record](TESTFLIGHT.md). Beta description, feedback email and
private reviewer contact/instructions remain in App Store Connect; sign-in is
not required.

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

Build 0.1.20 (21) adds optional ball nicknames and consistent model/weight labels in used-ball and primary-ball selections, My Bag, history, insights, recaps and CSV. Matching balls use color and a numbered label when needed. Please test two TZone balls at different weights, identical-weight/color balls, editing or clearing a nickname, retiring a ball, and saving/resuming a game with the correct primary ball.

New optional Cover material and Cover type fields record reactive resin, urethane, polyester/plastic, rubber or other, plus solid/pearl/hybrid when known. The offline table has 71 verified manufacturer/model defaults. TZone defaults to polyester/plastic with no construction assumed. New entries receive known defaults until manually edited; unknown variants stay unset. Existing balls retain saved choices: Use model specifications applies a known match. Please test manual overrides, clearing fields, reopening, save retries, backups/restores and older backups.

The build-20 recognition pipeline is unchanged. Compare every delivery and scratch total with the original photo, including gutters, spares, splits and tenth-frame fills. Unfamiliar or small scoreboards may require manual correction. Also check offline use, Share image, Export image, dark mode, large text and VoiceOver.

Keep a backup before testing restore or deletion. Report version/build, device/OS, expected and actual results. Use permissioned, redacted photos in feedback.

## Beta review notes

No account, demo credentials, purchase or hardware accessory is required. Camera access is optional. On first launch, open Settings to set a bowler name and aliases, add an alley manually in Alleys and a ball in My Bag, then start practice in Tonight. To test without a scoreboard, use manual frame entry: `9-` in each of ten frames gives a 90 game. Save, finish the session and open its recap to test native image sharing. Manual recording works in airplane mode.

For photo recognition, import a clear final ten-pin scoreboard including the bowler name, delivery marks, and all ten frames. A unique alias match with validated complete frames fills the editor; uncertain images request review/correction. Recognition uses Apple Vision on iPad/Mac and does not upload photos to an AI service. The app's Privacy policy and User guide are in Settings and available offline.

The iOS target is iPad-only. macOS uses a separate native Flutter target, not the iPad binary. Review each platform build's camera, sharing and sandbox behavior separately.

## Known beta limitations

The [twelve-photo evaluation](PHOTO_CORPUS_RESULTS.md) and earlier monitor regressions provide development evidence, not general recognition accuracy. Sparse, distorted or unfamiliar layouts may need manual marks. One image is processed at a time. There is no sync, iPhone support, handicap scoring or retained photo library. JSON backups omit original photos. Public map/search services have no availability guarantee; manual alley entry remains available. Android ML Kit diagnostics apply to Android builds, not Apple builds. The Android PNG transport passes separate-UID receiver tests; Google Chat composer verification on the Samsung remains pending.
