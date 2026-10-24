import '../ui/layout.dart';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../ui/journal_cards.dart';
import '../ui/dialogs.dart';
import 'game_editor.dart';
import 'photo_capture.dart';
import 'session_share.dart';
import '../recognition/photo_service.dart';

class TonightPage extends StatelessWidget {
  const TonightPage({
    super.key,
    required this.controller,
    required this.onHistory,
  });
  final BowlController controller;
  final VoidCallback onHistory;
  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final session = controller.activeSession;
    final games = session == null
        ? <BowlingGame>[]
        : controller.journal.gamesForSession(session.id);
    final name = data.profile.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          name.isEmpty ? 'Your night. Your game.' : 'Ready to roll, $name?',
          dateLabel(DateTime.now()),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [BowlColors.ink, Color(0xFF284E4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MAKE EVERY FRAME A MEMORY',
                        style: TextStyle(
                          color: Color(0xFFC5DDCC),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        session == null
                            ? 'How you bowled,\ntonight.'
                            : data.alley(session.alleyId)!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        session == null
                            ? 'Your scores, your favorite lanes, your trusty ball.\nA little history with every night out.'
                            : '${session.league ? 'League' : 'Practice'}${session.lane.isEmpty ? '' : ' · Lane ${session.lane}'} · ${dateLabel(session.startedAt)}',
                        style: const TextStyle(
                          color: Color(0xFFD6E3DB),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFAC8A),
                          foregroundColor: BowlColors.ink,
                        ),
                        onPressed: controller.isAcquiringPhoto
                            ? null
                            : () => session == null
                                  ? startSession(context, controller)
                                  : recordOrResumeGame(
                                      context,
                                      controller,
                                      session,
                                    ),
                        icon: Icon(
                          session == null
                              ? Icons.add_rounded
                              : Icons.edit_note_rounded,
                        ),
                        label: Text(
                          session == null
                              ? 'Start a session'
                              : data.draft?['sessionId'] == session.id
                              ? 'Resume game'
                              : 'Record a game',
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.maxWidth > BowlLayout.heroArtWidth) ...[
                  const SizedBox(width: 32),
                  Transform.rotate(
                    angle: -.22,
                    child: const BallArt(size: 160, color: Color(0xFFF48059)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (session != null) ...[
          PhotoCaptureActions(controller: controller, session: session),
          const SizedBox(height: 24),
        ],
        if (name.isEmpty) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 10,
              ),
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text(
                'Make it yours',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Add your name and the nicknames you use on scoreboards.',
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => editProfile(context, controller),
            ),
          ),
          const SizedBox(height: 24),
        ],
        MetricRow(
          children: [
            MetricCard(
              session == null ? 'Games recorded' : 'Games tonight',
              '${session == null ? data.games.length : games.length}',
              session == null
                  ? 'Your bowling story so far'
                  : 'One frame at a time',
            ),
            MetricCard(
              session == null ? 'Your average' : 'Tonight’s average',
              averageLabel(session == null ? data.games : games),
              'Scratch scores',
              accent: true,
            ),
            MetricCard(
              session == null ? 'Alleys visited' : 'Session total',
              session == null
                  ? '${controller.journal.visitedAlleyCount}'
                  : '${games.fold<int>(0, (n, g) => n + g.score)}',
              session == null
                  ? 'With recorded games'
                  : 'Total pins across your games',
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (session != null) ...[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tonight’s games',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              OutlinedButton.icon(
                onPressed: controller.isAcquiringPhoto
                    ? null
                    : () async {
                        if (data.draft?['sessionId'] == session.id) {
                          message(
                            context,
                            'Save or discard your unfinished game first.',
                          );
                          return;
                        }
                        if (await confirm(
                              context,
                              'Wrap up this session?',
                              'Your games stay editable in History.',
                              action: 'Finish session',
                            ) &&
                            context.mounted) {
                          await safely(context, () async {
                            await controller.finishSession(session.id);
                            if (context.mounted && games.isNotEmpty) {
                              await openSessionShare(
                                context,
                                controller,
                                session,
                              );
                            }
                          });
                        }
                      },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Finish session'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (games.isEmpty)
            const EmptyCard(
              icon: Icons.scoreboard_outlined,
              title: 'The first frame starts here.',
              body: 'Record your opening game. You can leave a draft and finish it later.',
            ),
          for (var i = 0; i < games.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GameCard(
                game: games[i],
                number: i + 1,
                data: data,
                onTap: () => openGameEditor(
                  context,
                  controller,
                  session,
                  game: games[i],
                ),
              ),
            ),
          if (data.draft?['sessionId'] == session.id)
            TextButton.icon(
              onPressed: () async {
                if (await confirm(
                      context,
                      'Discard unfinished game?',
                      'This removes the draft only. Saved games remain.',
                      action: 'Discard draft',
                    ) &&
                    context.mounted) {
                  await safely(context, () async {
                    final source =
                        controller.data.draft?['sourcePath'] as String?;
                    await controller.discardDraft();
                    await PhotoService.remove(source);
                  });
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Discard unfinished game'),
            ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onHistory,
                child: const Text('View history →'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.sessions.isEmpty)
            const EmptyCard(
              icon: Icons.nights_stay_outlined,
              title: 'A fresh scorecard.',
              body: 'Start a practice or league session, choose your lanes, and make tonight part of your story.',
            ),
          for (final s in data.sessions.reversed.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SessionCard(
                session: s,
                data: data,
                games: controller.journal.gamesForSession(s.id),
                onTap: () => showSession(context, controller, s),
              ),
            ),
        ],
      ],
    );
  }
}

Future<void> showSession(
  BuildContext context,
  BowlController controller,
  BowlingSession session,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final games = controller.journal.gamesForSession(session.id);
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: BowlLayout.toolbarHeight(context),
            title: Text(controller.data.alley(session.alleyId)!.name),
            actions: [
              if (games.isNotEmpty)
                IconButton(
                  tooltip: 'Share session',
                  onPressed: () =>
                      openSessionShare(context, controller, session),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BowlLayout.editorWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeading(
                      dateLabel(session.startedAt),
                      '${session.league ? 'League' : 'Practice'}${session.leagueName.isEmpty ? '' : ' · ${session.leagueName}'}${session.lane.isEmpty ? '' : ' · Lane ${session.lane}'}',
                    ),
                    MetricRow(
                      children: [
                        MetricCard(
                          'Games',
                          '${games.length}',
                          'Verified frame records',
                        ),
                        MetricCard(
                          'Average',
                          averageLabel(games),
                          'Scratch scores',
                          accent: true,
                        ),
                        MetricCard(
                          'Total',
                          '${games.fold<int>(0, (n, g) => n + g.score)}',
                          'Pins this session',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (games.isEmpty)
                      const EmptyCard(
                        icon: Icons.scoreboard_outlined,
                        title: 'No saved games',
                        body: 'Your session is ready for its first game.',
                      ),
                    for (var i = 0; i < games.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Game ${i + 1} · ${games[i].score}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit game',
                                      onPressed: () => openGameEditor(
                                        context,
                                        controller,
                                        session,
                                        game: games[i],
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete game',
                                      onPressed: () async {
                                        if (await confirm(
                                              context,
                                              'Delete game?',
                                              'This removes the game from your history and statistics.',
                                              action: 'Delete game',
                                            ) &&
                                            context.mounted) {
                                          await safely(
                                            context,
                                            () => controller.deleteGame(
                                              games[i].id,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ScoreStrip(frames: games[i].frames),
                                if (games[i].notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(games[i].notes),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});
  final BowlController controller;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String query = '';
  bool? league;
  static const _pageSize = 50;
  int _visibleSessions = _pageSize;
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final sessions = data.sessions.reversed
        .where(
          (s) =>
              (league == null || s.league == league) &&
              '${data.alley(s.alleyId)!.name} ${s.leagueName} ${dateLabel(s.startedAt)}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Your bowling story.',
          'Good nights, learning nights, and everything between.',
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search alleys, leagues, dates…',
          ),
          onChanged: (v) => setState(() {
            query = v;
            _visibleSessions = _pageSize;
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final item in <(String, bool?)>[
              ('All sessions', null),
              ('League', true),
              ('Practice', false),
            ])
              ChoiceChip(
                label: Text(item.$1),
                selected: league == item.$2,
                onSelected: (_) => setState(() {
                  league = item.$2;
                  _visibleSessions = _pageSize;
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (sessions.isEmpty)
          EmptyCard(
            icon: Icons.history_rounded,
            title: data.sessions.isEmpty
                ? 'Your history starts tonight.'
                : 'No matching sessions',
            body: data.sessions.isEmpty
                ? 'Every session you record will find a home here.'
                : 'Try a different search or session type.',
          ),
        for (final s in sessions.take(_visibleSessions))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SessionCard(
              session: s,
              data: data,
              games: widget.controller.journal.gamesForSession(s.id),
              onTap: () => showSession(context, widget.controller, s),
            ),
          ),
        if (sessions.length > _visibleSessions) ...[
          Text('Showing $_visibleSessions of ${sessions.length} sessions'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _visibleSessions += _pageSize),
            child: const Text('Show more sessions'),
          ),
        ],
      ],
    );
  }
}
