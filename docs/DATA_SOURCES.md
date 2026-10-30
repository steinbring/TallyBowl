# Suggestions and public services

## Bowling alleys

TallyBowl uses the documented [Photon search API](https://github.com/komoot/photon/blob/master/docs/api-v1.md), backed by OpenStreetMap, at `https://photon.komoot.io/api/`. It needs no API key and does not scrape web pages. Search is explicitly submitted; typing does not generate requests. Only the entered words are sent, with the identifying TallyBowl User-Agent, including the installed package version/build (or a versionless identity if metadata is unavailable). No GPS coordinates, photos, aliases, or bowling history are sent.

The [public demo server policy](https://github.com/komoot/photon#demo-server) permits reasonable usage, may throttle or ban excessive use, and provides no availability guarantee. The app limits searches to five results, caches up to 30 queries for ten minutes with least-recently-used eviction (cache hits do not extend expiry), prevents overlapping requests, spaces uncached requests by at least one second, and backs off on HTTP 429/503. There are no automatic retries. Responses have a 12-second timeout and a 256 KiB limit. Search is optional; manual entry and saved alleys work offline.

Search results include any matching place, not just the `leisure=bowling_alley` category: venues with lanes can have a primary pub or entertainment tag. The user must confirm the address. OSM coverage and venue status can be incomplete. OSM identity is retained to reuse an already saved venue. Attribution links to [OSM copyright and ODbL terms](https://www.openstreetmap.org/copyright). This is an application lookup, not a redistributed global venue database.

Live API verification on October 23, 2026: an unfiltered request for “Holler House Milwaukee” returned the venue, its address, `N/12168828291`, and its location. A bowling-only tag filter excluded it because its principal tag is `amenity=pub`.

For a larger release, choose Photon hosting appropriate to actual traffic or self-host it. Override the HTTPS endpoint using `--dart-define=TALLYBOWL_PHOTON_URL=https://your-host/api/`; it must implement the same GeoJSON contract. No public Nominatim autocomplete is used. The [public Nominatim policy](https://operations.osmfoundation.org/policies/nominatim/) prohibits autocomplete and limits aggregate application traffic.

Map tiles are a separate service, configured by `TALLYBOWL_TILE_URL`. Configure the provider credit with `TALLYBOWL_TILE_ATTRIBUTION` and its link with `TALLYBOWL_TILE_ATTRIBUTION_URL`. Public OSM raster tiles remain a development default; see their [usage policy](https://operations.osmfoundation.org/policies/tiles/) before wider distribution.

## Bowling balls

Research did not identify a documented, maintained public bowling-ball catalog API with both no authentication key and permission for this use. This is a research result, not a claim that no such service can exist. [Channel3's bowling-ball API](https://trychannel3.com/product-data/sporting-goods-indoor-games-bowling-bowling-balls) requires an API key. The [USBC equipment pages](https://bowl.com/equipment-specifications) and [PBA certified ball list](https://www.pba.com/pba-league-bowler-certification/certified-bowling-balls) are references, not documented public catalog API contracts.

Do not turn retail pages, undocumented store endpoints, or a PDF approval list into a scraping dependency. A future public JSON catalog at tallybowl.jws.app could provide key-free updates, once its data source and redistribution rights are settled. Ball suggestions must allow custom, old, and regional models and must not be presented as tournament eligibility or purchasing advice.

The offline catalog contains 11 manufacturer/brand names and 85 model names: the original 22 selected models plus 50 current Brunswick and 13 current Radical names checked on October 30, 2026. Suggestions also include the owner's previously entered brands and models, including retired equipment. Choosing a model fills its manufacturer; both fields remain editable. No catalog request leaves the device. This is a dated name snapshot, not a live stock or eligibility list. Weight, optional basic color, surface and notes remain the owner's entries.

Current-name expansion checked October 30, 2026, from the official product listings at the owner's request (names only; no descriptions, images, prices or specifications are bundled):

- [Brunswick Current](https://brunswickbowling.com/products/balls/current): 50 distinct products across [page 2](https://brunswickbowling.com/products/balls/current/p2), [page 3](https://brunswickbowling.com/products/balls/current/p3) and [page 4](https://brunswickbowling.com/products/balls/current/p4), including the first page. The named color variants, polyester balls and Viz-A-Ball designs are included. The earlier generic Rhino and Mesmerize suggestions remain available.
- [Radical Current](https://radicalbowling.com/products/balls/current): 13 products. The owner-supplied [All Balls](https://radicalbowling.com/products/balls) listing also includes retired models; those were excluded from the current expansion.

Original name-only starter references checked October 23, 2026:

- [Storm/SPI buyer's guide](https://www.stormbowling.com/bowling-ball-buyers-guide): selected Storm, Roto Grip, and 900 Global names.
- [Hammer Black Widow 3.0](https://hammerbowling.com/products/black-widow-3-0): Black Widow 3.0 and the referenced 2.0 Hybrid.
- [Ebonite Game Breaker 4](https://ebonite.com/products/game-breaker-4).
- [MOTIV exclusive lineup](https://www.motivbowling.com/products/balls/exclusives/): Jackal Ghost V2 and Venom Shock.
- [Brunswick ball lineup](https://brunswickbowling.com/products/balls/p2?sort=newest) and [Brunswick's registered products](https://www.pba.com/registered-products/brunswick): Rhino and Mesmerize.
- [DV8 Trouble Maker](https://dv8bowling.com/products/balls/retired/trouble-maker).
- [Track Cypher](https://trackbowling.com/products/cypher) and [Cyborg](https://trackbowling.com/products/cyborg).
- [Columbia 300](https://columbia300.com/): brand-only suggestion.

Manufacturer suggestions are derived from the starter models plus explicit brand-only entries. Tests check that brands/models are nonempty, unique, and consistent. Keep this reference list and `BallCatalog.starter` in sync when adding manually verified names. Do not imply endorsement or manufacturer affiliation.

## On-device recognition SDKs

Apple platforms use the system Vision framework. Android bundles ML Kit Text Recognition 16.0.1; recognition works without a model download or an AI server. TallyBowl does not upload scoreboard images or extracted bowling records for recognition.

Google's bundled SDK can send diagnostic metadata independently of application API calls: device/application information and installation identifiers, input format/dimensions, processing performance, configuration and errors. This was also observed as queued `FIREBASE_ML_SDK` events during emulator verification. See Google's [ML Kit Android data disclosure](https://developers.google.com/ml-kit/android-data-disclosure). Do not describe the Android SDK as network-silent or claim an unsupported telemetry opt-out. The Settings privacy text distinguishes local image processing from these SDK diagnostics.
