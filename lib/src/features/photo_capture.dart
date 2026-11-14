import '../ui/layout.dart';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../recognition/photo_quality.dart';
import '../recognition/photo_service.dart';
import '../recognition/score_parser.dart';
import '../ui/common.dart';
import 'game_editor.dart';
import '../ui/score_photo_preview.dart';

Future<void> recordOrResumeGame(
  BuildContext context,
  BowlController controller,
  BowlingSession session,
) async {
  if (controller.isAcquiringPhoto) {
    message(context, 'Finish or cancel the open photo picker first.');
    return;
  }
  final draft = controller.data.draft;
  if (draft?['pendingPhotoReview'] == true &&
      draft?['sessionId'] == session.id &&
      draft?['sourcePath'] is String) {
    return importScorePhoto(
      context,
      controller,
      session,
      recoveredPath: draft!['sourcePath'] as String,
      resumePendingReview: true,
    );
  }
  // Older drafts may contain a retained photo but no delivery marks. Retry with
  // the current parser while keeping lane, equipment and notes intact.
  if (draft?['sessionId'] == session.id &&
      draft?['sourcePath'] is String &&
      (draft?['frames'] as List?)?.every((v) => v == '') == true) {
    final release = await controller.reservePhotoAcquisition(
      sessionId: session.id,
      allowDraft: true,
    );
    try {
      final rows = ScoreSheetParser.rows(
        await PhotoService.recognize(
          draft!['sourcePath'] as String,
          profile: controller.data.profile,
        ),
        controller.data.profile,
      );
      final row = ScoreSheetParser.automaticRow(rows);
      if (row != null &&
          controller.data.draft?['sourcePath'] == draft['sourcePath']) {
        release();
        await controller.saveDraft({
          ...controller.data.draft!,
          'frames': row.frames,
          'sourceLabel': row.text,
          'displayedTotal': row.displayedTotal,
          'sourceCumulative': row.cumulativeTotals,
        });
      }
    } catch (_) {
      // Keep the existing draft and manual frame entry if reading fails.
    } finally {
      release();
    }
  }
  if (context.mounted) return openGameEditor(context, controller, session);
}

Future<void> importScorePhoto(
  BuildContext context,
  BowlController controller,
  BowlingSession session, {
  bool camera = false,
  String? recoveredPath,
  bool resumePendingReview = false,
}) async {
  // A dismissible quality prompt can ask for another photo. The previous
  // photo and its pending review are discarded before the new one is chosen.
  bool? retake = await _importScorePhotoOnce(
    context,
    controller,
    session,
    camera: camera,
    recoveredPath: recoveredPath,
    resumePendingReview: resumePendingReview,
  );
  while (retake != null) {
    if (!context.mounted) return;
    retake = await _importScorePhotoOnce(
      context,
      controller,
      session,
      camera: retake,
    );
  }
}

/// Returns whether to take another photo with the camera (true) or the
/// library (false), or null when this import is finished.
Future<bool?> _importScorePhotoOnce(
  BuildContext context,
  BowlController controller,
  BowlingSession session, {
  bool camera = false,
  String? recoveredPath,
  bool resumePendingReview = false,
}) async {
  final draft = controller.data.draft;
  final resuming =
      resumePendingReview &&
      draft?['pendingPhotoReview'] == true &&
      draft?['sessionId'] == session.id &&
      recoveredPath != null &&
      draft?['sourcePath'] == recoveredPath;
  if (draft != null && !resuming) {
    message(
      context,
      'Save or discard your unfinished game before importing another photo.',
    );
    return null;
  }
  String? path;
  try {
    if (!resuming) {
      final release = await controller.reservePhotoAcquisition(
        sessionId: session.id,
      );
      try {
        path = recoveredPath ?? await PhotoService.pick(camera: camera);
        if (path == null || !context.mounted) return null;
        // Attach before releasing acquisition so finish/restore cannot race the
        // transition from an external picker to a persisted review draft.
        await controller.beginPhotoReview(session.id, path);
      } finally {
        release();
      }
    } else {
      path = recoveredPath;
    }
    if (!context.mounted) return null;
    final selection = await Navigator.of(context).push<PhotoSelection>(
      MaterialPageRoute(
        builder: (_) => PhotoReviewPage(
          controller: controller,
          session: session,
          path: path!,
        ),
      ),
    );
    if (!context.mounted) {
      return null; // Keep the pending review for the next launch.
    }
    if (selection == null || selection.retakeWithCamera != null) {
      if (controller.data.draft?['sourcePath'] == path &&
          controller.data.draft?['pendingPhotoReview'] == true) {
        await controller.discardDraft();
      }
      return selection?.retakeWithCamera;
    }
    if (context.mounted) {
      final row = selection.row;
      await controller.saveDraft({
        'sessionId': session.id,
        'frames': row?.frames ?? List.filled(10, ''),
        'sourcePath': path,
        'sourceLabel': row?.text,
        'displayedTotal': row?.displayedTotal,
        'sourceCumulative': row?.cumulativeTotals,
      });
      if (!context.mounted) return null;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => GameEditor(
            controller: controller,
            session: session,
            initialFrames: row?.frames ?? List.filled(10, ''),
            sourcePath: path,
            sourceLabel: row?.text,
            displayedTotal: row?.displayedTotal,
            sourceCumulative: row?.cumulativeTotals,
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) message(context, 'Could not open this photo. $e');
  } finally {
    if (path != null && controller.data.draft?['sourcePath'] != path) {
      try {
        await PhotoService.remove(path);
      } catch (_) {
        // Orphan cleanup retries on the next launch.
      }
    }
  }
  return null;
}

class PhotoCaptureActions extends StatefulWidget {
  const PhotoCaptureActions({
    super.key,
    required this.controller,
    required this.session,
  });
  final BowlController controller;
  final BowlingSession session;
  @override
  State<PhotoCaptureActions> createState() => _PhotoCaptureActionsState();
}

class _PhotoCaptureActionsState extends State<PhotoCaptureActions> {
  bool _busy = false;
  Future<void> _open({bool camera = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await importScorePhoto(
        context,
        widget.controller,
        widget.session,
        camera: camera,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      FilledButton.icon(
        onPressed: _busy || widget.controller.isAcquiringPhoto
            ? null
            : () => _open(camera: true),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Scan scoreboard'),
      ),
      OutlinedButton.icon(
        onPressed: _busy || widget.controller.isAcquiringPhoto ? null : _open,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Import photo'),
      ),
    ],
  );
}

class PhotoSelection {
  const PhotoSelection(this.row) : retakeWithCamera = null;

  /// Discard this photo and choose another, from the camera or the library.
  const PhotoSelection.retake({required bool camera})
    : row = null,
      retakeWithCamera = camera;
  final ScoreRow? row;
  final bool? retakeWithCamera;
}

class PhotoReviewPage extends StatefulWidget {
  const PhotoReviewPage({
    super.key,
    required this.controller,
    required this.session,
    required this.path,
  });
  final BowlController controller;
  final BowlingSession session;
  final String path;
  @override
  State<PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<PhotoReviewPage> {
  late Future<(List<ScoreRow>, PhotoQualityReport?)> _rows;
  ScoreRow? _selected;
  bool _leaving = false;
  bool _qualityDismissed = false;
  @override
  void initState() {
    super.initState();
    final profile = widget.controller.data.profile;
    _rows = PhotoService.recognize(widget.path, profile: profile).then((
      lines,
    ) async {
      final rows = ScoreSheetParser.rows(lines, profile);
      final automatic = ScoreSheetParser.automaticRow(rows);
      if (automatic != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            _review(automatic);
          }
        });
        return (rows, null);
      }
      // Only a photo that cannot be imported automatically is assessed. The
      // report explains likely causes; it never changes the recognized rows.
      PhotoQualityReport? quality;
      try {
        quality = await PhotoService.assessQuality(
          widget.path,
          lines,
          rows,
          profile,
        );
      } catch (_) {
        // Manual review stays available without a quality report.
      }
      return (rows, quality);
    });
  }

  void _review(ScoreRow? row) {
    if (_leaving) return;
    _leaving = true;
    Navigator.pop(context, PhotoSelection(row));
  }

  void _retake({required bool camera}) {
    if (_leaving) return;
    _leaving = true;
    Navigator.pop(context, PhotoSelection.retake(camera: camera));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: BowlLayout.toolbarHeight(context),
      title: const Text('Find your row'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: BowlLayout.editorWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                'That’s you on the board.',
                'Choose your row, then check every frame before saving.',
              ),
              ScorePhotoPreview(path: widget.path),
              const SizedBox(height: 24),
              FutureBuilder<(List<ScoreRow>, PhotoQualityReport?)>(
                future: _rows,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Reading your photo on this device…'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return EmptyCard(
                      icon: Icon(Icons.image_search_rounded),
                      title: 'This one needs a closer look.',
                      body: 'We couldn’t read the scoreboard clearly. Keep the photo alongside your frames and enter them yourself.',
                      action: FilledButton(
                        onPressed: () => _review(null),
                        child: const Text('Enter frames with photo'),
                      ),
                    );
                  }
                  final (rows, quality) = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quality != null &&
                          quality.suggestsRetake &&
                          !_qualityDismissed)
                        RetakePrompt(
                          issues: quality.issues,
                          bowlerName: widget.controller.data.profile.name,
                          onCamera: () => _retake(camera: true),
                          onLibrary: () => _retake(camera: false),
                          onDismiss: () =>
                              setState(() => _qualityDismissed = true),
                        ),
                      if (rows.isEmpty)
                        const Text(
                          'No clear bowler rows were found. You can still enter your frames with the photo open.',
                        ),
                      for (final row in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            color: identical(row, _selected)
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(
                                identical(row, _selected)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(
                                row.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                row.hasScoreConflict
                                    ? 'Delivery marks found · displayed scores need review'
                                    : row.extracted
                                    ? 'Frame sequence found · verify it against the photo'
                                    : 'Frame details need manual review',
                              ),
                              trailing: row.suggested
                                  ? const LabelPill('NAME MATCH')
                                  : null,
                              onTap: () => setState(() => _selected = row),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (_selected != null)
                        FilledButton.icon(
                          onPressed: () => _review(_selected),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('This is my row · Review frames'),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _review(null),
                        child: const Text(
                          'My row isn’t listed · Enter frames myself',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Name matches are suggestions. Only your confirmed frames are saved. The source photo is deleted after you save or discard its draft.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Explains why a photo that could not be imported may read better if
/// retaken. Always dismissible: the photo, row choice and manual entry remain.
class RetakePrompt extends StatelessWidget {
  const RetakePrompt({
    super.key,
    required this.issues,
    required this.bowlerName,
    required this.onCamera,
    required this.onLibrary,
    required this.onDismiss,
  });
  final List<PhotoIssue> issues;
  final String bowlerName;
  final VoidCallback onCamera, onLibrary, onDismiss;

  static String advice(PhotoIssue issue, String bowlerName) => switch (issue) {
    PhotoIssue.noText => 'No scoreboard text was found. Fit the whole scoreboard in the frame, hold steady and tap it to focus.',
    PhotoIssue.smallText => 'The scores are small in this photo. Move closer so the scoreboard fills the frame.',
    PhotoIssue.blurry =>
      'The photo looks blurry. Hold steady and tap the scoreboard to focus.',
    PhotoIssue.underexposed => 'The scores look dim. Avoid bright lights behind the screen and let the camera adjust.',
    PhotoIssue.nameMissing =>
      bowlerName.trim().isEmpty
          ? 'Your scoreboard name wasn’t found. Add it in Settings, then include your row.'
          : 'Your name wasn’t found. Include your row, or add the exact name shown on the scoreboard in Settings.',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_camera_back_outlined,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Another photo may read better',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Text(
                    '• ${advice(issue, bowlerName)}',
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take another photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onLibrary,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose another'),
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Use this photo anyway'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
