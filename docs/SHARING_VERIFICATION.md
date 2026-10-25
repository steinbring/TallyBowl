# Recap handoff verification

Verified for development build 0.1.5 (6), October 25, 2026.

TallyBowl renders a branded PNG locally and uses the system share sheet with MIME type `image/png`. On Android, share_plus 13.3.1 supplies an ACTION_SEND intent, a FileProvider content URI, and temporary read permission. No recipient is hardcoded. AeroSloth advertises `image/*` sharing, opens that URI and copies the attachment into its private draft storage before presenting its composer.

An isolated Android 17 emulator exercised the actual **Share image → AeroSloth** route using a synthetic bowler/alley recap with a verified score of 90. AeroSloth copied the PNG successfully. The sender and receiver files were identical (SHA-256 `02329331a46dc17a3292a8e40ad9f7efcd987f1a2d6d4cd579a0506287cba6f2`); the received image was 1080 × 1456 pixels, with the correct score, totals, branding and website. AeroSloth's normal application then presented **Compose** with **Attachment 1, image**. No account was configured on the test emulator and nothing was queued or posted. The first available debug APK was an AeroSloth integration harness; the normal app build was used to verify the composer.

The widget regression checks the actual exported file, PNG signature, 1080-pixel width, MIME type, neutral filename when Date is hidden, and disabled privacy controls during handoff. The original scoreboard photo and other bowlers are excluded from the recap.

To share an owner's results, finish the session and open **Share your night**, choose the desired privacy switches, then **Share image** and the destination app. A recipient may require an account, caption or image description before sending; those are recipient requirements. AeroSloth's composer can be reviewed before posting. Email and message attachment compatibility use the same ordinary PNG contract, but their individual recipient apps were not all exercised in this pass.

Screenshots, diagnostic APKs and received files from this verification are ignored local build output. None contains a public post or a message to another person.
