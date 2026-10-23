# TallyBowl! project roadmap

Updated: October 23, 2026

## Product goal

**TallyBowl! — How you bowled, tonight.**

A Flutter app for macOS, iPadOS, and Android that turns scoreboard photos into a personal bowling history. The bowler confirms their row and frame results, associates games with an alley, lane, and balls, and shares a branded recap after league or practice.

## Confirmed decisions

| Area | Launch scope |
| --- | --- |
| Platforms | macOS, iPadOS, Android |
| Bowling format | Standard ten-pin |
| Profiles | One bowler, with name and nickname aliases |
| Photo extraction | Frame-by-frame results at launch, including individual delivery marks and tenth-frame bonus deliveries |
| AI | All recognition and inference run on the device; no cloud AI fallback |
| Storage | Local database, backup/export and restore; cross-device synchronization deferred |
| Maps | OpenStreetMap data with the native Flutter `flutter_map` package |
| Ball attribution | Tag all balls used in a game; allow an optional primary ball |
| Sharing | Locally rendered branded image, previewed and shared through the operating system share sheet |

## The main user journey

1. Set up the bowler's display name and scoreboard aliases.
2. Add owned balls and favorite bowling alleys.
3. Start a league or practice session. Pick an alley and lane or lane pair; allow changes for individual games.
4. Take a photo or select one or more existing photos. Support platform-appropriate photo/file import and macOS drag and drop.
5. Crop or rotate as needed. Analyze the image locally and locate candidate bowler rows and game panels.
6. Suggest a row using the bowler's aliases, then require explicit row confirmation. Names and visual similarity are suggestions, not proof of identity.
7. Show an editable frame grid beside the relevant image crop. Highlight uncertain marks, missing deliveries, and discrepancies between calculated and displayed scores.
8. Confirm the game, its date, lane, and balls used. The game enters the permanent history and statistics only after review.
9. Repeat for the session's remaining games, then finish the session.
10. Preview a TallyBowl! recap image and open the native share sheet.

Manual game and frame entry remains available when a photo is missing, unreadable, or unsupported. Imported dates are suggestions; the user confirms the bowling date, which can differ from the photo date.

## Product structure

| Section | Purpose |
| --- | --- |
| Tonight | Active session, camera/import, review, game list, finish and share |
| History | Sessions and games, source review when retained, corrections, filters |
| Insights | Scoring trends, frame statistics, alley visits, ball usage and comparisons |
| My Bag | Owned balls, manufacturer/model, nickname, weight, photo, notes, active/retired status |
| Alleys | Map selection, favorites, manual locations, visit and scoring history |
| Settings | Bowler aliases, photo retention, backup/restore, data export, privacy and attribution |

Use layouts suited to each screen: a navigation rail/sidebar and split review panes on Mac and larger iPads, with compact navigation on smaller Android devices. Include keyboard operation, accessible labels, scalable text, and clear contrast in the frame editor.

## Delivery milestones

Milestones describe completion criteria rather than calendar promises. Recognition feasibility and the supported device range should be measured before committing to a release date.

### 1. Prove frame recognition and platform access

- Gather a small, permissioned collection of real scoreboard photos from the intended alleys. Include different display layouts, multiple bowlers, multi-game summaries, glare, perspective distortion, small marks, and tenth frames. Keep working images and annotations local.
- Create manually verified expected results for row selection, each delivery, cumulative frame scores, and game totals. Reserve examples for evaluation that are not used to tune the parser.
- Prototype Apple Vision recognition on macOS and iPadOS and bundled ML Kit text recognition on Android behind a common result interface.
- Combine text boxes with local layout/symbol detection. Plain text extraction alone may not reliably distinguish a spare slash, a grid line, and a stylized strike symbol.
- Measure exact delivery accuracy, complete-game accuracy before corrections, wrong-row suggestions, correction effort, processing time, and memory use on representative devices. A correct final total alone does not establish correct frames.
- Verify camera, photo/file selection, map display, and image sharing on all three platforms. Include an actual macOS camera path and the iPad share popover.
- Record supported scoreboard layouts, minimum device/OS requirements, and a measurable recognition acceptance target based on the sample results. Difficult layouts may need a dedicated local detector or parser.

**Done when:** real photos can pass through capture/import, local analysis, and a reviewable frame draft on each target platform; limitations and benchmark results are documented. Unsupported images produce an explicit correction path.

### 2. Establish the Flutter app and reliable manual recording

- Scaffold the three platform targets and an adaptive app shell.
- Add local persistence with schema migrations, stable IDs, and recoverable session/import drafts.
- Implement the bowler profile and aliases, ball inventory, manually maintained alleys, sessions, games, and an editable frame grid.
- Build a pure Dart scoring engine independent of OCR. Validate roll legality, strike/spare bonuses, fouls, misses, and tenth-frame rack resets and bonus deliveries.
- Keep scratch scores separate from any reported handicap and handicap-adjusted totals. Launch does not require a league-management or handicap-calculation system.
- Support editing and retiring balls/alleys without losing the meaning of historical records.

**Done when:** a bowler can record and correct a complete league or practice session manually, restart the app without losing it, and obtain consistently calculated scores.

### 3. Ship the complete photo-to-game flow

- Integrate local recognition into the app and persist drafts safely if interrupted.
- Detect candidate rows and games, apply alias suggestions, and require the bowler to select their row.
- Map visible marks into frames and deliveries, preserving the distinction between unknown, unplayed, foul, miss, strike, spare, and numeric pinfall.
- Compare calculated scores against visible cumulative totals and final scratch totals. Surface contradictions even if recognition appears confident.
- Provide fast corrections with a zoomed source crop and an editable frame grid.
- Handle multiple photos and multiple game panels with explicit game assignment. Detect exact duplicate files and warn about likely duplicate games without rejecting legitimate repeated scores.
- Let users combine photos of the same game when they show different frames. A totals-only image cannot uniquely reconstruct delivery results: retain an incomplete draft or request manual completion.
- Offer configurable retention of source images. Avoid leaking other bowlers' rows through previews, logs, or share cards.

**Done when:** users can import, review, correct, and save complete frame results from the supported layouts; incomplete or conflicting data cannot silently become a verified full game.

### 4. Add OpenStreetMap alley selection

- Use `flutter_map` for map interaction and visible OpenStreetMap attribution.
- Separate the map tile service from the place-search service; a map widget does not supply an alley directory.
- Select OSM-compatible tile and search providers with terms suitable for the intended release scale. Make endpoints configurable and cache within the chosen providers' rules.
- Support explicit search, selecting a map location, editing the alley name/address, and manual entry when an alley is absent or connectivity is unavailable.
- Request location only when the bowler chooses a nearby search. Keep location permission optional.
- Save the selected alley locally, including its name/address snapshot, coordinates, and OSM object type/ID when available. Use a local ID for history so later map edits do not disconnect games.
- Allow merging duplicate saved alleys while preserving historical sessions.

**Done when:** the bowler can find or manually add an alley, reuse saved alleys offline, and associate games with the correct lane or lane pair. A network outage does not prevent recording at a saved alley.

### 5. Add history and useful statistics

- Display game averages, session totals, best games, and scoring trends by date and session type.
- Define alley frequency as sessions/visits and games, shown separately. One session counts as one visit even when multiple lanes are used.
- Define ball usage as games in which that ball was tagged; also show sessions used and games designated as the primary ball. Multi-ball game counts overlap and do not add up to the number of unique games.
- Compare scores by alley, lane, and ball alongside sample counts, date filters, and league/practice filters.
- Label multi-ball results explicitly. A game's score is shared context for its tagged balls, not a score earned separately by each ball.
- Add frame-derived strike rate, spare conversion rate, open-frame counts, and first-delivery averages. Specify denominators and treatment of tenth-frame bonus deliveries before implementation.
- Exclude incomplete drafts from verified frame metrics and avoid displaying unavailable measures as zero. Do not infer specific pin leaves from pinfall counts alone.

**Done when:** statistics reconcile with the saved games, remain correct after edits, and clearly state what is being compared. Present observed associations; lane conditions, practice, and ball selection can confound claims that a ball or alley caused an improvement.

### 6. Finish branded sharing and data portability

- Design a branded recap using “TallyBowl!” and “How you bowled, tonight.” Include individual game scores, session total/average, and optional frame detail, alley, lane, date, and balls.
- Render the image locally, provide a preview, and allow the bowler to hide identifying details. Keep other bowlers and original scoreboard photos out of the default card.
- Share the rendered image as a file through the native share sheet on each platform; also provide Save Image.
- Export a versioned backup with records and optional retained images. Restore with format validation, a review of what will change, and protection for existing records.
- Offer CSV export for analysis, including a separate delivery-level export. CSV is not a complete backup format.

**Done when:** the branded image is readable at common sharing sizes, native image sharing works on all targets, and a backup can restore an equivalent history on a fresh installation.

### 7. Validate and prepare the first release

- Run focused scoring/parser tests for perfect games, all misses, all spares, consecutive strikes, fouls, ambiguous symbols, and legal/illegal tenth frames. Include image fixtures with expected row and delivery results.
- Verify the complete flow on real macOS, iPadOS, and Android hardware, including permission denial, interrupted imports, app restarts, large images, and offline recording.
- Check database migrations, backup round trips, duplicate handling, and statistics after corrections.
- Verify recognition without a network connection and audit app-controlled network paths so scoreboard photos and extracted bowling data are never sent to an AI service. Maps/search still use the selected external map services.
- Review image retention, temporary share-file cleanup, dependency licenses, map attribution, signing, and platform distribution requirements.

**Done when:** the capture-to-share journey meets the recorded recognition target, corrections are usable for unsupported images, data survives restart/restore, and each supported platform passes its release checklist.

## Proposed architecture

Use Flutter for interface, workflows, scoring, parsing, image rendering, and statistics. Keep native capabilities behind small adapters so macOS support is explicit.

| Component | Responsibility |
| --- | --- |
| Image acquisition adapter | Camera, photo/file selection, desktop drag and drop, permissions and interrupted-picker recovery |
| Recognition adapter | Apple Vision on Apple platforms; bundled ML Kit on Android; common text/geometry results with confidence where available |
| Local image/layout pipeline | Orientation, crop/perspective handling, row/frame localization, delivery-symbol recognition |
| Bowling parser | Candidate names, game panels, normalized deliveries, source bounds and uncertainty |
| Scoring engine | Deterministic ten-pin validation and cumulative scores; independent of image recognition |
| Repository/database | Local records, migrations, draft recovery, transactional writes, export and restore |
| Mapping adapter | `flutter_map`, tile configuration, optional location, place search and saved alley selection |
| Share renderer/adapter | Local branded PNG generation and native image sharing; evaluate `share_plus` during the platform prototype |

Choose and pin package versions during the platform prototype, after verifying their current platform support and OS requirements. Add custom Swift/Kotlin adapters where the chosen Flutter packages do not cover required capabilities. A general-purpose local language model is not a prerequisite; add a bundled local model only if the image benchmark demonstrates a need.

## Initial data model

| Record | Key information |
| --- | --- |
| BowlerProfile | Display name, aliases, preferences |
| Ball | Stable ID, make/model, nickname, weight, notes/photo, active/retired state |
| Alley | Stable local ID, name/address snapshot, coordinates, optional OSM identity, notes |
| Session | Bowling date/time and time zone, league/practice type, optional league label, alley, lane/pair defaults, notes |
| Game | Session, game order, lane/pair override, scratch total, optional reported handicap/adjusted total, review/completeness state |
| Frame / Delivery | Frame and delivery order, pinfall, mark, foul flag, optional explicitly observed annotations, calculated cumulative score |
| GameBallUsage | Game-to-ball relationship and optional primary designation; no inferred per-delivery attribution |
| Import / SourceImage | Local image reference, hash, extracted candidates, source bounds, recognition/parser version, correction and confirmation state |

Store observed marks separately from user corrections where needed for review. Preserve unknown values explicitly. Retaining an image is optional and independent from retaining the bowler's confirmed game records.

## Concerns and design responses

| Concern | Response |
| --- | --- |
| Different scoreboards, glare, stylized marks | Benchmark real images first, support correction, document supported layouts, and add local detectors if needed |
| Correct total but incorrect deliveries | Validate the full frame sequence and compare visible cumulative scores; total equality alone cannot verify extraction |
| Wrong bowler or duplicate names | Suggest aliases and require explicit row selection; keep the selected source crop visible |
| Missing frames in a summary photo | Keep an incomplete draft, combine additional images, or complete it manually; do not invent deliveries |
| Several balls used in one game | Record game-level usage and optional primary ball; limit comparisons to the information actually recorded |
| Claims about score improvement | Show sample sizes and filters and describe associations rather than causal effects |
| macOS capability gaps | Validate native OCR, camera, photo/file access, and sharing early; budget for native adapters |
| Data loss with local storage | Ship versioned backup and verified restore, recover drafts, and provide export |
| OSM data versus hosted services | Choose tile/search hosting deliberately; include attribution, service configuration, and offline manual entry |

## Deferred scope and remaining implementation choices

Cross-device sync, accounts, multiple profiles, alternative bowling formats, per-delivery ball attribution, automatic pin-leave diagrams, and league/team administration are outside the first release.

Before finalizing the platform prototype, select the minimum OS/device range, initial scoreboard layouts and sample photos, map/search hosting, source-image retention defaults, and the exact backup restore/merge behavior. These can be resolved during implementation without reopening the confirmed product scope. iPhone support is a separate scope decision; it was not requested with the initial targets.

## Technical references

References checked October 23, 2026. Recheck SDK and service requirements when implementation begins.

- Apple documents on-device text recognition in [Recognizing Text in Images](https://developer.apple.com/documentation/vision/recognizing-text-in-images). The shared recognition interface still needs separate platform integration and image-layout parsing.
- Google's [Android text-recognition documentation](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) distinguishes bundled models from models downloaded through Play Services. Use the bundled option so recognition does not depend on an initial model download.
- [Leaflet](https://leafletjs.com/) is a JavaScript map library. [`flutter_map`](https://docs.fleaflet.dev/) supplies a pure Flutter map client across Flutter platforms; it is the approved choice here.
- The Flutter-maintained [`image_picker_macos` documentation](https://pub.dev/packages/image_picker_macos) states that camera capture requires a camera delegate. Desktop image import does not by itself complete the camera requirement.
- [`share_plus` documentation](https://pub.dev/packages/share_plus) describes native file sharing and iPad popover positioning. Confirm image handling on every target during the prototype.
- The [OSM tile usage policy](https://operations.osmfoundation.org/policies/tiles/) requires attribution, an identifying User-Agent, and compliant caching; its public raster tile service does not allow offline prefetch/bulk download and offers no availability guarantee. Do not assume public hosting is the production solution.
- If considering the public Nominatim service, read its [usage policy](https://operations.osmfoundation.org/policies/nominatim/) first: at most one request per second across the entire app's users, identification/attribution, no client-side autocomplete, and a switchable endpoint are required. This roadmap does not select or integrate that public endpoint; use a suitable hosted or self-hosted search provider for production.
- USBC's [Keeping Score](https://bowl.com/keeping-score) provides a ten-pin scoring reference, including strike/spare bonuses and a tenth-frame walkthrough.
