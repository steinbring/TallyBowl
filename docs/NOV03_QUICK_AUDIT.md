# November 3, 2026 quick audit

The requested review covered recap rendering/export, temporary-file handling, Android intent/provider grants, database and backup/restore boundaries, photo-acquisition coordination, bounded place-search requests, and Apple release configuration. It was a focused source review with automated verification, not a full penetration test or physical-device acceptance pass.

## Fixed

| Finding | Change |
| --- | --- |
| Android Export image opened the share chooser | A distinct save method publishes a new PNG to Pictures/TallyBowl on Android 10+, or uses the system save picker on older Android. Share image retains its existing chooser and read-only attachment contract. |
| No confirmed-save feedback and ambiguous busy label | Success appears only after a save completes; Sharing… and Saving… identify the active action. Cancellation is silent. Failures restore the controls and show a useful retry message without raw exception/path text. |
| Export staging accepted directory components in filenames | Filenames reject separators, dot paths and control characters before any file is created. Current callers already supply generated names; this makes the helper's safe boundary explicit. |
| Cleanup/encoding failures could leave unnecessary resources or block an export | Old-file cleanup is best effort, failed staging writes attempt cleanup, and rendered images are disposed even if PNG encoding fails. |
| New public image could be incomplete after a failed write | Native export writes off the UI thread with IS_PENDING set until close/publication succeeds. Write or publication failures remove the pending media entry. A new entry preserves earlier images when exporting repeatedly. |
| Export documentation described the old transport | The bundled guide/policy now distinguish sharing, direct Android saves, older-Android save dialogs and independent gallery/backup behavior. Release metadata is updated for build 17. |

Save and share reuse one canonical-containment/PNG/20 MiB validator. No storage or photo-library permission, new runtime dependency, recipient enumeration or write/persistable attachment grant was added. JSON/CSV exports retain their existing transport. The Android path uses [app-owned MediaStore images](https://developer.android.com/training/data-storage/shared/media); older devices use [ACTION_CREATE_DOCUMENT](https://developer.android.com/training/data-storage/shared/documents-files).

## Verification

- **242 Flutter unit/widget tests pass**, including all existing recognition fixtures, frame-editor import/resume flows, persistence/backup tests, large-text checks, actual recap rendering and three-platform share transport. New checks cover Android's separate save call and confirmed feedback, date-hidden filenames, cancellation/failure/retry, and staging path rejection.
- **7 Android instrumentation tests pass** on the isolated API-37 emulator. Real MediaStore saves are read back byte-for-byte, published with PNG MIME in the expected folder, and repeated saves receive distinct URIs. Injected write/publication failures remove unfinished entries; invalid PNG/private paths are rejected before insertion. Existing separate-UID attachment read/write-denial tests pass.
- Static analysis is clean. Android Lint has **0 errors and 10 advisory warnings** concerning the SDK-managed Gradle version, existing icon/resources, and optional Bitmap KTX style. The merged manifest has no storage/photo-library permission.
- Generated Markdown agrees with the bundled guide and policy. No journal schema or recognition algorithm changed.

No additional critical issue was identified in the inspected paths. Older Android's save intent and cancellation contract are tested, but an API-28 device was not available for picker acceptance. No physical Samsung camera/gallery/Chat or installed Apple TestFlight acceptance is claimed. Recognition on tiny online images and unfamiliar layouts retains the limits in the [October 31 report](OCT31_PHOTO_EVALUATION.md); passing the regression suite does not make every scoreboard automatically readable.
