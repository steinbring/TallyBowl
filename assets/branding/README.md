# TallyBowl! bowler mark

`tallybowl-logo.png` is the selected, committed master. The cream abstract bowler points forward in the spirit of “Tally ho!” and carries a warm orange bowling ball with three finger holes. A fixed dark teal badge preserves contrast in light and dark app themes. The master is used in the phone header, desktop navigation, Settings and branded recap images.

Created October 25, 2026 using the built-in imagegen tool. This is a build-time brand asset; image generation is not part of the app or its on-device score recognition pipeline. A transparent extraction study was rejected and is not used by the project.

Selected generation prompt:

> Use case: logo-brand. Asset type: production square app icon and brand mark for TallyBowl!, a bowling journal. Create one polished, bold, abstract geometric symbol of a ten-pin bowler pointing the way with an outstretched arm and clearly extended index finger angled slightly upward, conveying the cheerful forward invitation 'Tally ho!'. The other arm cradles a bowling ball at the hip, with exactly three clear dark finger holes. Abstract head without facial features; confident forward stride; balanced, compact silhouette with large simple shapes and generous negative space. Cream/off-white figure, warm copper-orange bowling ball, on a completely solid deep teal (#173C3C) opaque square background. Flat vector-like graphic, crisp edges, excellent recognition at 32px. Center the complete symbol and keep it inside the central 76 percent of the canvas for platform icon masks. No words, letters, numbers, border, shadows, gradients, texture, racket, ball seams, pins, scenery, or mockup. One icon only, square canvas.

Rebuild the platform icon sizes from this master using `swift tool/generate_icons.swift`. macOS uses a transparent outer margin and rounded tile; iPad and Android icon files are opaque. Keep the committed master rather than regenerating artwork during builds.

The small bowling-ball glyph in My Bag navigation and empty states is drawn by `BowlingBallIcon`; its three holes are cut out of a filled circle and it inherits the theme's icon color. Inventory/hero ball artwork also has three finger holes, with no curved seam.
