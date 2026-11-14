# TallyBowl! public-store preparation

Prepared November 13, 2026. Target: **March 1, 2027**, **US$9.95**, all eligible territories. This is a draft packet, not a public release approval. Account, policy and final-review gates are recorded in [launch readiness](../../docs/LAUNCH-READINESS.md).

- `en-US.json`: store copy, public URLs, review notes, pricing/date intent. `appleDescription`, when present, overrides the general description for Apple.
- `assets/`: nine opaque RGB PNGs with store dimensions; `assets-manifest.json` records dimensions and byte counts. Public demo screens are used, with aspect ratio preserved; the source does not contain personal account captures. Final-release screens still need review against the shipping UI. Two screenshots alone do not establish any Google promotional-placement eligibility.
- `source/` and `asset-provenance.json`: original public website art and provenance. These are staged marketing examples, not fresh device acceptance evidence.
- `package-verification.json`: sanitized checks, hashes and public certificate fingerprints for the signed **1.0.0 (22) Android candidate**. This does not enroll Play App Signing or upload a package.
- `certificates/` and `signing-certificates.json`: public certificates only. [Signing recovery](SIGNING-RECOVERY.md) explains custody and the required off-device backup.
- [Privacy review](PRIVACY-DISCLOSURE-REVIEW.md): source-based assessment that must inform final store declarations; no privacy labels were submitted by this packet.

Validate metadata and artwork with `python3 release/store/check_store_packet.py`. To also verify local package hashes, add `--artifacts "/Users/joe/Code/TallyBowl/build/store-prep/2026-11-13-build-22"`.

To reproduce artwork on macOS, copy `source/` into an empty temporary packet directory, compile `render-store-assets.swift` with `swiftc -framework AppKit`, and run the resulting tool with `tallybowl` and that directory. It deliberately refuses to overwrite existing PNGs. Review the output before replacing draft artwork. Never overwrite an archived release export.

Public version **1.0.0** requires a matching final Apple binary; existing beta version numbers are separate. Do not submit a public review, enable immediate release, or migrate a populated development installation merely because the packet validates.
