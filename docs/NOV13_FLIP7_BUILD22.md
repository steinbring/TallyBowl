# Galaxy Z Flip 7 owner build 22 — November 13, 2026

Superseded later the same day by [final build 23](NOV13_FLIP7_BUILD23.md), which preserves the privacy-policy changes from main.

Updated the connected **SM-F766U** from **0.1.18 (19)** to **0.1.20 (22)**
in place, without uninstalling or clearing data. Build 22 uses latest application
source `f13bfbb` (the same runtime changes as Apple build 21) plus launch-packet
documentation at `29736b0`. Only owner Android packaging advanced the build
number; no TallyBowl build 22 was uploaded to TestFlight.

Flutter analysis and all **303 Flutter tests passed**, including the retained
recognition/backup/accessibility regressions. A fresh arm64 debug owner APK
matched the installed development certificate before installation. Its SHA-256
is `018eec90a0452deaddb2739fff08c843b2166c49accd0179c80b541cbe0a22d5`.
The separate production-signed **1.0.0 (22)** AAB/Galaxy APK were not installed.

A private, stopped-app database copy was retained before the update. Before and
after SQLite integrity checks returned `ok`, schema version remained 2 and
all existing table counts matched. This Flip had an empty journal before the
update: settings, balls, alleys, sessions and games were all zero. This is
retention evidence for that state, not a populated-history migration test.
Original installation time was retained. Tonight and Settings opened, including
the privacy/help area and displayed **Version 0.1.20 (build 22)**. The launched
app's scoped log had no observed fatal or Unhandled Flutter exception.

No journal record, photo, export or share was created. Camera/recognition,
recap handoff, TalkBack and fold/rotation acceptance were not repeated on this
phone. Existing recognition limitations still apply. Raw screenshots, logs,
owner APK, database copies and verification JSON stay private in the temporary
launch working directory; real data was not committed to Git.

[Launch readiness](LAUNCH-READINESS.md) records the remaining public-store gates.
