# Pre-test review — October 23, 2026

Reviewed the Flutter screens, navigation, forms, scoring/parser, persistence, exports, photo lifecycle, native recognition/camera bridge, platform permissions, and new suggestion services.

## Changes made

| Area | Finding and change | Verification |
| --- | --- | --- |
| Alley selection | Manual-only entry and map navigation made the first alley difficult to add. Added explicit Photon search to Add Alley, a separate map action, address confirmation, and reuse by OSM identity. Saved markers now edit their existing alley rather than create a duplicate. | Live documented API check; parsing/network-limit tests; selection and duplicate widget checks. |
| Ball entry | Free-text-only forms offered no help with names. Added an offline, name-only starter catalog and the owner's previously entered models, with manufacturer filtering and editable custom values. | Catalog and desktop/phone form tests. |
| Form persistence | Inventory, profile, and session dialogs closed before writes completed. They now remain open until success, retain entries on failure, prevent overlapping saves, and support retry. | Failure/retry ball widget test and session workflow tests. |
| Game editing | Back navigation silently discarded edits to saved games. Added confirmation, waits for pending draft writes, and blocks navigation during a save. Added inline ball creation to the game editor. | Existing-game cancel/discard test and draft-resume workflow tests. |
| Storage | Every draft keystroke deleted and reinserted the entire journal. Storage now diffs serialized rows and writes only changes in one transaction. Schema v2 stores explicit order; upgrades retain existing data. Failed loads close their connection. | SQL audit triggers prove draft saves do not change history rows; v1 migration, restart, reordered restore, foreign-key and transaction rollback/retry tests. |
| Consistency | Editing a ball/alley moved it to the end of its list. Edits now preserve order. Dates now include the year in history and recap contexts. | Inventory order and existing recap tests. |
| CSV safety | Leading whitespace/control characters could bypass formula-prefix protection. Export now quotes and neutralizes these cases while retaining numeric data and bowling marks. | Formula, BOM/control, multiline and delivery-export tests. |
| Photo handling | A large Mac file was allocated before its size was rejected. File length is checked first, streamed reads remain capped if the file grows, and recognition uses the same bound. Import buttons prevent overlapping operations; cleanup failures are retried on launch. | Oversized sparse-file and growing-stream tests; existing recognition tests. |
| Native camera | Concurrent macOS camera start/stop tasks could race during quick cancellation. They now share a serial session queue and ignore preparation after cancellation. | Source review and native macOS compilation. Physical-camera timing remains a device test. |
| Network boundary | Added HTTPS-only configuration, bounded JSON parsing, timeout, no redirects, cache, request spacing, server cooldown, and stale-query suppression to the place-search service. No photo or bowling record is part of a request. | HTTP contract, malformed/oversized response, cooldown, encoding and stale-result tests. |

The unit/widget suite currently has **41 passing tests**. `flutter analyze` passes. Native build and visual verification results are recorded in DEVELOPMENT.md.

## Remaining limits for testing

- Recognition remains a conservative prototype for clear horizontal rows, not a broad real-scoreboard benchmark. Short/sparse labels have triggered upside-down Apple Vision interpretation in a synthetic case. Confirm every delivery and scratch total; manual correction remains available. Representative photos are the highest-priority next evidence.
- Physical camera permissions/capture, native share destinations, Android recognition runtime, and OS lifecycle interruptions still need device testing. A successful build does not establish those behaviors.
- Photon and public OSM tiles have no production capacity reserved for this app. Their development defaults, policies, privacy boundary, and replacement settings are documented in DATA_SOURCES.md. The ball starter list is intentionally incomplete.
- SQLite and exported JSON/CSV use the device sandbox and chosen file destinations; they are not encrypted by the app. OS-managed backups follow device settings. There is no application account or cloud sync.
- Snapshot validation/serialization remains proportional to journal size even though disk writes are incremental. Profile large imported histories before optimizing further. The raw draft map remains small and validated; a typed draft model would be useful if multiple draft kinds are introduced.
- Distribution signing/notarization, store submission configuration and physical iPad installation are separate from development builds.
