# Public launch readiness — November 13, 2026

**Prepared, with launch gates still open.** Target **March 1, 2027** at midnight America/Chicago; US base price **$9.95**, all eligible territories. The year is 2027 because these dates follow the current November 2026 preparation. Review approval and store propagation can affect availability; the date is not a guarantee.

## Prepared and verified

- Live marketing and privacy URLs responded over HTTPS. [Store copy and artwork](../release/store/README.md) include public demo screens, store-sized opaque PNGs, review instructions and source provenance.
- Apple iPad and native Mac **1.0.0** drafts have descriptions, keywords, support/marketing links, review notes and scheduled no-earlier-than release dates. Exact US price **$9.95** is available in Apple's additional price points and was saved. This prepares listings; it does not submit public review.
- Dedicated encrypted Android app-signing and separate Play-upload keys were created with owner approval. Passwords remain in the Mac login Keychain; encrypted keystores stay outside Git. Only public certificates and fingerprints are committed.
- Signed Android **1.0.0 (22)** Play AAB and Galaxy APK candidates were built from the source in `package-verification.json`. Upload/app-signing certificates were checked separately. Bundle validation, package/version, target API 36, non-debuggable manifest, 16 KiB native/ZIP alignment and no bundled private keys passed. No production package was uploaded or installed on the phones.

## Gates before public submission

| Gate | Actual state and next action |
| --- | --- |
| Apple commercial setup | Owner reported setup complete. A refreshed Business page still displays **Paid Apps Agreement: New** and **Complete Compliance Requirements**. Verify the correct provider and finish/resolve the paid agreement, tax/banking and EU trader requirements; do not claim paid/EU readiness until Apple shows the required active/verified state. The separate Developer Program agreement was accepted and TestFlight uploads work. |
| Google account | Account **5482766965702138921**, confirmed by the owner as reactivated, still displays **developer profile and apps removed** after refresh. The owner confirms reinstatement and submitted the enabled verification workflow. The console now lists **Google could not verify your identity** and **Google could not verify your merchant payment method** as action-required tasks. Complete/resolve these directly with Google and verify publishing access before creating app records or uploading. An unsent follow-up was prepared privately; no support case was sent and no second account was created. |
| Samsung account | Registered as a Private/Free Distribution Seller. Seller Portal explicitly prohibits Android content for private sellers, including free apps. Corporate Commercial Distribution Seller approval is required. Owner has no business/DBA yet; choose and establish legitimate seller eligibility, then apply with actual documents. No company details were invented and no Android listing was submitted. |
| Signing recovery | Copy the encrypted keystore archive off this Mac and independently retain all four Keychain passwords. A local archive is not an off-device backup. Enroll the intended app-signing identity in Play App Signing before first upload; use the separate upload certificate for AABs. |
| Privacy and safety | Review/update the hosted privacy policy against final source, complete Apple privacy and Google Data safety answers, age/content ratings, rights and required contact information. Dedicated Apple App Privacy URL entry was not saved: its editor kept Save disabled. URLs in the listing descriptions are saved; finish the dedicated field and declarations. No privacy answers were guessed or published. |
| Final Apple candidate | Build/archive/sign a matching public **1.0.0** binary for each platform. Beta uploads do not create or approve this public candidate. Select the final build, review screenshots against its UI, fill reviewer contacts/access and submit with sufficient review lead time. |
| Territory eligibility | Prepare all eligible territories, while resolving EU trader and encryption/export requirements, including France as applicable. Existing beta export answers cover testing outside France; they are not worldwide public authorization. |
| Final acceptance | Freeze source, back up real user data and check supported hardware, permissions, accessibility, offline behavior, upgrades and provider limits. Never uninstall a populated test app to bypass the production certificate change. |

Google launch setup must wait for account recovery. Then create the paid app (avoid an accidental free launch), complete identity/app ownership verification, Play App Signing, listing, content declarations and testing requirements. Use a closed test and the publishing controls applicable to a first release; managed publishing is not a guaranteed first-launch scheduler. Samsung launch dates use UTC; convert Chicago midnight for the target date and verify the portal before scheduling.

## Evidence and limits

Signed packages and complete private build logs are at `/Users/joe/Code/TallyBowl/build/store-prep/2026-11-13-build-22`. The committed packet contains hashes and public verification, not private keys. Public website screenshots are marketing evidence, not new physical-device testing. No public store submission, sale, reviewer login, or support message occurred in this preparation.

References: [Apple release options](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/), [Google publishing controls](https://support.google.com/googleplay/android-developer/answer/9859654), [Android target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878), [Samsung seller preparation](https://developer.samsung.com/galaxy-store/prepare.html), [Samsung launch](https://developer.samsung.com/galaxy-store/launch.html), [Android developer verification](https://developer.android.com/developer-verification).

## TallyBowl!-specific gates

The Android candidate uses source `f13bfbb`, the existing latest build-21 application plus documentation. Analysis and all **303 Flutter tests passed** again before the Flip 7 update. Owner Android build **0.1.20 (22)** was installed in place with a matching development certificate; [startup and empty-journal retention](NOV13_FLIP7_BUILD22.md) passed. Native photo/hardware acceptance was not repeated; successful packaging and unit tests do not establish OCR accuracy. Before public submission, repeat manual recording, recognition review/correction, backup/restore, image export/share and offline use on the supported devices. Always compare recognized deliveries with their original photo.

Review Android ML Kit diagnostics and map/search provider disclosures against the hosted policy and store definitions. There is no TallyBowl account and no reviewer sign-in requirement. Photos are processed on device for recognition; that statement does not waive SDK diagnostic disclosures.
