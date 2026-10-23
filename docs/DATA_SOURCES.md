# Suggestions and public services

## Bowling alleys

TallyBowl uses the documented [Photon search API](https://github.com/komoot/photon/blob/master/docs/api-v1.md), backed by OpenStreetMap, at `https://photon.komoot.io/api/`. It needs no API key and does not scrape web pages. Search is explicitly submitted; typing does not generate requests. Only the entered words are sent, with the identifying TallyBowl User-Agent. No GPS coordinates, photos, aliases, or bowling history are sent.

The [public demo server policy](https://github.com/komoot/photon#demo-server) permits reasonable usage, may throttle or ban excessive use, and provides no availability guarantee. The app limits searches to five results, caches up to 30 queries for ten minutes, prevents overlapping requests, spaces uncached requests by at least one second, and backs off on HTTP 429/503. There are no automatic retries. Responses have a 12-second timeout and a 256 KiB limit. Search is optional; manual entry and saved alleys work offline.

Search results include any matching place, not just the `leisure=bowling_alley` category: venues with lanes can have a primary pub or entertainment tag. The user must confirm the address. OSM coverage and venue status can be incomplete. OSM identity is retained to reuse an already saved venue. Attribution links to [OSM copyright and ODbL terms](https://www.openstreetmap.org/copyright). This is an application lookup, not a redistributed global venue database.

Live API verification on October 23, 2026: an unfiltered request for “Holler House Milwaukee” returned the venue, its address, `N/12168828291`, and its location. A bowling-only tag filter excluded it because its principal tag is `amenity=pub`.

For a larger release, choose Photon hosting appropriate to actual traffic or self-host it. Override the HTTPS endpoint using `--dart-define=TALLYBOWL_PHOTON_URL=https://your-host/api/`; it must implement the same GeoJSON contract. No public Nominatim autocomplete is used. The [public Nominatim policy](https://operations.osmfoundation.org/policies/nominatim/) prohibits autocomplete and limits aggregate application traffic.

Map tiles are a separate service, configured by `TALLYBOWL_TILE_URL`. Public OSM raster tiles remain a development default; see their [usage policy](https://operations.osmfoundation.org/policies/tiles/) before wider distribution.

## Bowling balls

Research did not identify a documented, maintained public bowling-ball catalog API with both no authentication key and permission for this use. This is a research result, not a claim that no such service can exist. [Channel3's bowling-ball API](https://trychannel3.com/product-data/sporting-goods-indoor-games-bowling-bowling-balls) requires an API key. The [USBC equipment pages](https://bowl.com/equipment-specifications) and [PBA certified ball list](https://www.pba.com/pba-league-bowler-certification/certified-bowling-balls) are references, not documented public catalog API contracts.

Do not turn retail pages, undocumented store endpoints, or a PDF approval list into a scraping dependency. A future public JSON catalog at tallybowl.jws.app could provide key-free updates, once its data source and redistribution rights are settled. Ball suggestions must allow custom, old, and regional models and must not be presented as tournament eligibility or purchasing advice.
