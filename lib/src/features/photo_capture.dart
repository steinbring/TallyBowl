import '../ui/layout.dart';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
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
    return;
  }
  String? path;
  try {
    if (!resuming) {
      final release = await controller.reservePhotoAcquisition(
        sessionId: session.id,
      );
      try {
        path = recoveredPath ?? await PhotoService.pick(camera: camera);
        if (path == null || !context.mounted) return;
        // Attach before releasing acquisition so finish/restore cannot race the
        // transition from an external picker to a persisted review draft.
        await controller.beginPhotoReview(session.id, path);
      } finally {
        release();
      }
    } else {
      path = recoveredPath;
    }
    if (!context.mounted) return;
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
      return; // Keep the pending review for the next launch.
    }
    if (selection == null) {
      if (controller.data.draft?['sourcePath'] == path &&
          controller.data.draft?['pendingPhotoReview'] == true) {
        await controller.discardDraft();
      }
      return;
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
      if (!context.mounted) return;
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
  const PhotoSelection(this.row);
  final ScoreRow? row;
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
  late Future<List<ScoreRow>> _rows;
  ScoreRow? _selected;
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    _rows =
        PhotoService.recognize(
          widget.path,
          profile: widget.controller.data.profile,
        ).then((lines) {
          final rows = ScoreSheetParser.rows(
            lines,
            widget.controller.data.profile,
          );
          final automatic = ScoreSheetParser.automaticRow(rows);
          if (automatic != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                _review(automatic);
              }
            });
          }
          return rows;
        });
  }

  void _review(ScoreRow? row) {
    if (_leaving) return;
    _leaving = true;
    Navigator.pop(context, PhotoSelection(row));
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
              FutureBuilder<List<ScoreRow>>(
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
                  final rows = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
