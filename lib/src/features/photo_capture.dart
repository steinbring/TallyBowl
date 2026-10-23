import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../recognition/photo_service.dart';
import '../recognition/score_parser.dart';
import '../theme.dart';
import '../ui/common.dart';
import 'game_editor.dart';
import '../ui/score_photo_preview.dart';

Future<void> importScorePhoto(
  BuildContext context,
  BowlController controller,
  BowlingSession session, {
  bool camera = false,
  String? recoveredPath,
}) async {
  if (controller.data.draft != null) {
    message(
      context,
      'Save or discard your unfinished game before importing another photo.',
    );
    return;
  }
  String? path;
  try {
    path = recoveredPath ?? await PhotoService.pick(camera: camera);
    if (path == null) return;
    if (!context.mounted) {
      await PhotoService.remove(path);
      return;
    }
    final selection = await Navigator.of(context).push<PhotoSelection>(
      MaterialPageRoute(
        builder: (_) => PhotoReviewPage(
          controller: controller,
          session: session,
          path: path!,
        ),
      ),
    );
    if (selection != null && context.mounted) {
      final row = selection.row;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => GameEditor(
            controller: controller,
            session: session,
            initialFrames: row?.frames ?? List.filled(10, ''),
            sourcePath: path,
            sourceLabel: row?.text,
            displayedTotal: row?.displayedTotal,
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
        onPressed: _busy ? null : () => _open(camera: true),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Scan scoreboard'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : _open,
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
  @override
  void initState() {
    super.initState();
    _rows = PhotoService.recognize(widget.path).then(
      (lines) => ScoreSheetParser.rows(lines, widget.controller.data.profile),
    );
  }

  void _review(ScoreRow? row) {
    Navigator.pop(context, PhotoSelection(row));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find your row')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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
                      icon: Icons.image_search_rounded,
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
                                ? BowlColors.mint
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
                                row.extracted
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
                      const Text(
                        'Name matches are suggestions. Only your confirmed frames are saved. The source photo is deleted after you save or discard its draft.',
                        style: TextStyle(
                          color: BowlColors.muted,
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
