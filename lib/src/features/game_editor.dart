import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../domain/scoring.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../ui/score_photo_preview.dart';
import '../ui/dialogs.dart';
import '../recognition/photo_service.dart';

Future<void> openGameEditor(
  BuildContext context,
  BowlController controller,
  BowlingSession session, {
  BowlingGame? game,
  List<String>? initialFrames,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => GameEditor(
      controller: controller,
      session: session,
      game: game,
      initialFrames: initialFrames,
    ),
  ),
);

class GameEditor extends StatefulWidget {
  const GameEditor({
    super.key,
    required this.controller,
    required this.session,
    this.game,
    this.initialFrames,
    this.sourcePath,
    this.sourceLabel,
    this.displayedTotal,
  });
  final BowlController controller;
  final BowlingSession session;
  final BowlingGame? game;
  final List<String>? initialFrames;
  final String? sourcePath, sourceLabel;
  final int? displayedTotal;
  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor> {
  late final List<TextEditingController> _frames;
  late final TextEditingController _lane;
  late final TextEditingController _notes;
  late Set<String> _balls;
  String? _primary;
  String? _sourcePath, _sourceLabel;
  int? _displayedTotal;
  bool _mismatchAcknowledged = false;
  bool _saving = false;
  bool _draftError = false;
  bool _allowExit = false, _leaving = false;
  int _draftVersion = 0;
  Future<void> _pendingDraft = Future.value();
  List<String> get frames => _frames.map((c) => c.text).toList();
  @override
  void initState() {
    super.initState();
    final draft =
        widget.game == null &&
            widget.controller.data.draft?['sessionId'] == widget.session.id
        ? widget.controller.data.draft
        : null;
    final values =
        widget.initialFrames ??
        widget.game?.frames ??
        (draft?['frames'] as List?)?.cast<String>() ??
        List.filled(10, '');
    _sourcePath = widget.sourcePath ?? draft?['sourcePath'] as String?;
    _sourceLabel = widget.sourceLabel ?? draft?['sourceLabel'] as String?;
    _displayedTotal = widget.displayedTotal ?? draft?['displayedTotal'] as int?;
    _frames = [for (final value in values) TextEditingController(text: value)];
    _lane = TextEditingController(
      text:
          widget.game?.lane ?? draft?['lane'] as String? ?? widget.session.lane,
    );
    _notes = TextEditingController(
      text: widget.game?.notes ?? draft?['notes'] as String? ?? '',
    );
    _balls =
        (widget.game?.ballIds ??
                (draft?['ballIds'] as List?)?.cast<String>() ??
                <String>[])
            .toSet();
    _primary = widget.game?.primaryBallId ?? draft?['primaryBallId'] as String?;
    if (widget.initialFrames != null) _persistDraft();
  }

  @override
  void dispose() {
    for (final c in [..._frames, _lane, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    setState(() => _mismatchAcknowledged = false);
    _persistDraft();
  }

  Future<void> _persistDraft() async {
    if (widget.game != null || _saving) return;
    final version = ++_draftVersion;
    try {
      _pendingDraft = widget.controller.saveDraft({
        'sessionId': widget.session.id,
        'frames': frames,
        'lane': _lane.text,
        'notes': _notes.text,
        'ballIds': _balls.toList(),
        'primaryBallId': _primary,
        'sourcePath': _sourcePath,
        'sourceLabel': _sourceLabel,
        'displayedTotal': _displayedTotal,
      });
      await _pendingDraft;
      if (_draftError && mounted && version == _draftVersion) {
        setState(() => _draftError = false);
      }
    } catch (_) {
      if (mounted && version == _draftVersion) {
        setState(() => _draftError = true);
      }
    }
  }

  bool get _hasEdits {
    final game = widget.game;
    return game != null &&
        (!listEquals(frames, game.frames) ||
            _lane.text.trim() != game.lane ||
            _notes.text.trim() != game.notes ||
            !setEquals(_balls, game.ballIds.toSet()) ||
            _primary != game.primaryBallId);
  }

  Future<void> _leave() async {
    if (_saving || _leaving) return;
    _leaving = true;
    try {
      try {
        await _pendingDraft;
      } catch (_) {
        /* The draft error is shown below. */
      }
      if (!mounted) return;
      if ((_hasEdits || _draftError) &&
          !await confirm(
            context,
            'Leave without saving?',
            _draftError
                ? 'The latest draft changes could not be saved. Leaving will lose those changes.'
                : 'Your changes to this saved game will be discarded.',
            action: 'Discard changes',
          )) {
        return;
      }
      if (mounted) {
        setState(() => _allowExit = true);
        Navigator.pop(context);
      }
    } finally {
      _leaving = false;
    }
  }

  Future<void> _save() async {
    final result = TenPinScorer.score(frames);
    if (!result.complete ||
        _saving ||
        (_displayedTotal != null &&
            _displayedTotal != result.total &&
            !_mismatchAcknowledged)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.controller.saveGame(
        BowlingGame(
          id: widget.game?.id ?? widget.controller.newId(),
          sessionId: widget.session.id,
          frames: result.frames.map((f) => f.notation).toList(),
          createdAt: widget.game?.createdAt ?? DateTime.now(),
          lane: _lane.text.trim(),
          ballIds: _balls.toList(),
          primaryBallId: _primary,
          notes: _notes.text.trim(),
        ),
      );
      try {
        await PhotoService.remove(_sourcePath);
      } catch (_) {
        /* Retried by orphan cleanup on the next launch. */
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        setState(() {
          _allowExit = true;
          _saving = false;
        });
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Game saved · ${result.total}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        message(context, 'Could not save this game. $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = TenPinScorer.score(frames);
    final completeCount = result.frames
        .where((f) => f.complete && f.error == null)
        .length;
    final data = widget.controller.data;
    final availableBalls = data.balls
        .where((b) => !b.retired || _balls.contains(b.id))
        .toList();
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.game == null ? 'Record a game' : 'Edit game'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed:
                    result.complete &&
                        !_saving &&
                        (_displayedTotal == null ||
                            _displayedTotal == result.total ||
                            _mismatchAcknowledged)
                    ? _save
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save game'),
              ),
            ),
          ],
        ),
        body: IgnorePointer(
          ignoring: _saving,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width > 700 ? 32 : 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeading(
                      data.alley(widget.session.alleyId)?.name ??
                          'Your session',
                      '${dateLabel(widget.session.startedAt)} · ${widget.session.league ? 'League' : 'Practice'}',
                      action: LabelPill('$completeCount / 10 frames'),
                    ),
                    if (_sourcePath != null) ...[
                      ScorePhotoPreview(path: _sourcePath!),
                      if (_sourceLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Your selected row: $_sourceLabel',
                            style: const TextStyle(
                              color: BowlColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                    if (_displayedTotal != null &&
                        result.complete &&
                        _displayedTotal != result.total) ...[
                      Card(
                        color: const Color(0xFFFFE4DE),
                        child: CheckboxListTile(
                          value: _mismatchAcknowledged,
                          onChanged: (v) => setState(
                            () => _mismatchAcknowledged = v ?? false,
                          ),
                          title: Text(
                            'The photo shows $_displayedTotal; these frames score ${result.total}.',
                          ),
                          subtitle: const Text(
                            'Check the row, scratch score, and deliveries. Confirm only after reviewing the difference.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      color: BowlColors.mint,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            const Icon(Icons.scoreboard_outlined, size: 34),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.complete
                                        ? 'Ready to save'
                                        : 'Every delivery counts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'X strike · / spare · - miss · F foul. Examples: X, 9/, 81, X7/.',
                                    style: TextStyle(height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${result.total ?? result.runningTotal}',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScoreStrip(frames: frames),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, c) {
                        final count = c.maxWidth > 750
                            ? 5
                            : (c.maxWidth > 430 ? 3 : 2);
                        return Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            for (var i = 0; i < 10; i++)
                              SizedBox(
                                width: (c.maxWidth - (count - 1) * 12) / count,
                                child: TextField(
                                  key: ValueKey('frame-$i'),
                                  controller: _frames[i],
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  maxLength: i == 9 ? 3 : 2,
                                  textInputAction: i == 9
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Frame ${i + 1}',
                                    hintText: i == 9 ? 'X7/' : '9/',
                                    counterText: '',
                                    errorText: result.frames[i].error,
                                    errorMaxLines: 3,
                                  ),
                                  onChanged: (_) => _changed(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'What were you rolling?',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tag every ball used. Choose a primary ball if you wish.',
                      style: TextStyle(color: BowlColors.muted),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              await editBall(context, widget.controller);
                              if (mounted) setState(() {});
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Add a ball to your bag'),
                    ),
                    if (availableBalls.isEmpty)
                      const Text(
                        'No balls in your bag yet. You can save without a ball tag.',
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final b in availableBalls)
                            FilterChip(
                              label: Text(b.name),
                              selected: _balls.contains(b.id),
                              onSelected: (selected) {
                                if (selected) {
                                  _balls.add(b.id);
                                } else {
                                  _balls.remove(b.id);
                                  if (_primary == b.id) _primary = null;
                                }
                                _changed();
                              },
                            ),
                        ],
                      ),
                    if (_balls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _primary ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Primary ball',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('No primary ball'),
                          ),
                          for (final b in availableBalls.where(
                            (b) => _balls.contains(b.id),
                          ))
                            DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                b.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          _primary = value == '' ? null : value;
                          _changed();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextField(
                      controller: _lane,
                      decoration: const InputDecoration(
                        labelText: 'Lane or lane pair for this game',
                      ),
                      onChanged: (_) => _changed(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Game notes',
                        hintText: 'How did it feel? Any adjustments?',
                      ),
                      onChanged: (_) => _changed(),
                    ),
                    const SizedBox(height: 20),
                    if (_draftError)
                      const Text(
                        'Draft could not be saved. Keep this screen open and try again.',
                        style: TextStyle(color: Colors.red),
                      )
                    else if (widget.game == null)
                      const Text(
                        'Your unfinished game stays on this device when you leave this screen.',
                        style: TextStyle(fontSize: 12, color: BowlColors.muted),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
