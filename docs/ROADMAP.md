# TallyBowl! roadmap

Updated October 25, 2026. This replaces the original implementation proposal with the shipped scope and remaining milestones. Current beta candidate: 0.1.7 (8). See [TestFlight readiness](TESTFLIGHT.md) for the acceptance record.

## Confirmed launch scope

Native macOS, iPadOS and Android; standard ten-pin; one bowler with aliases; local storage and portable backups; frames at launch; game-level ball tags with optional primary; saved alleys and `flutter_map` using OpenStreetMap data; local recognition only; branded image sharing. There is no automatic cross-device sync.

## Implemented foundation

The adaptive app, deterministic scoring, editable frames, persistent drafts, inventory, alley search/manual map selection, sessions/history/statistics, branded sharing, JSON recovery and CSV exports are implemented. Apple Vision and bundled Android ML Kit feed a shared geometry-aware parser. A unique matching name and a complete consistent sequence can autofill; other cases require review. Offline help and privacy are bundled with the app.

The first real owner photo uncovered that name/cumulative OCR was not enough to populate deliveries. That regression is fixed and now has native/geometry/parser coverage on Android and Mac. One monitor layout is verified; this is not a measured recognition accuracy claim for arbitrary alleys.

## Next milestone: small internal Apple beta

1. Publish the privacy policy and keep the approved public support contact reachable: Joe Steinbring, https://jws.dev/contact.
2. Verify Apple Developer membership, agreements, App Store Connect app/platform records, correct team and App Store distribution signing. Build, validate and upload production-entry-point archives; retain symbols.
3. Install via TestFlight on the owner's iPad and Mac. Back up existing journals first; verify in-place migration, camera/photo access, offline recognition, a complete session, native sharing and recovery.
4. Record defects and resolve any crash, data loss, wrong-row silent acceptance, unusable correction path, permission dead end or inaccessible essential control before expanding access.

An internal owner TestFlight install is a useful way to perform distribution-signing and hardware checks. Broad layout accuracy measurement need not prevent that first controlled install. No upload or tester invitations are performed by documentation preparation alone.

## Next milestone: invited external beta

Complete Apple's beta information/review requirements and use a reachable support contact. Repeat the device checklist with VoiceOver/TalkBack, large text, light/dark appearance, rotation/folding, Mac keyboard navigation and iPad popovers. Test multiple recipients including AeroSloth where that platform offers image receiving. Treat an available system share target as a dependency of the recipient app.

Build a permissioned evaluation set across common monitor/printout layouts, light/glare conditions and supported devices. Keep a held-out set that does not tune the parser. Record exact deliveries, full-game accuracy before corrections, wrong-row suggestions, correction effort, runtime and memory. Set numerical public-release targets from these observations. Obtain provider capacity/privacy decisions before increasing public map/search traffic.

## Public release milestone

Resolve beta defects, confirm backup/migration recovery across supported minimum OS versions, finish store privacy/encryption/age-rating/territory information and reviewed screenshots, establish support and release ownership, and protect signing keys. Native Mac TestFlight/App Store distribution and a separately notarized direct Mac download are different paths. Android store delivery needs protected release signing and its own testing track; Apple TestFlight does not cover Android.

## Deferred product work

Accounts/sync, multiple bowlers, iPhone, other bowling rules, handicap/league administration, per-delivery ball attribution, pin-leave diagrams, multi-photo combining, crop/rotation controls, retained photo archives, desktop drag/drop, nearby GPS search, duplicate-alley merging and backup merging are outside the current beta scope. These were possibilities in the original roadmap, not implemented promises. Revisit them from beta evidence and user demand.

Statistics describe associations with sample counts. Multi-ball game counts overlap; none of these comparisons proves that equipment or alley choice caused score changes.
