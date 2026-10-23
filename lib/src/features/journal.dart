import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../ui/dialogs.dart';
import 'game_editor.dart';

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
        : data.sessionGames(session.id);
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
                          fontSize: 11,
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
                        onPressed: () => session == null
                            ? startSession(context, controller)
                            : openGameEditor(context, controller, session),
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
                if (c.maxWidth > 600) ...[
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
                  ? '${data.sessions.where((s) => data.sessionGames(s.id).isNotEmpty).map((s) => s.alleyId).toSet().length}'
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
                onPressed: () async {
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
                    await safely(
                      context,
                      () => controller.finishSession(session.id),
                    );
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
                  await safely(context, controller.discardDraft);
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
                onTap: () => showSession(context, controller, s),
              ),
            ),
        ],
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.number,
    required this.data,
    required this.onTap,
  });
  final BowlingGame game;
  final int number;
  final BowlData data;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: BowlColors.canvas,
              child: Text(
                '$number',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game $number${game.lane.isEmpty ? '' : ' · Lane ${game.lane}'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.ballIds.isEmpty
                        ? 'No ball tags'
                        : game.ballIds
                              .map((id) => data.ball(id)!.name)
                              .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: BowlColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${game.result.strikes} strikes · ${game.result.spares} spares',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BowlColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${game.score}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.data,
    required this.onTap,
  });
  final BowlingSession session;
  final BowlData data;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final games = data.sessionGames(session.id);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: BowlColors.mint,
          child: Icon(
            session.league ? Icons.emoji_events_outlined : Icons.sports_rounded,
            color: BowlColors.ink,
          ),
        ),
        title: Text(
          data.alley(session.alleyId)!.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${dateLabel(session.startedAt)} · ${session.league ? 'League' : 'Practice'} · ${games.length} games${session.finished ? '' : ' · In progress'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              averageLabel(games),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const Text(
              'AVG',
              style: TextStyle(fontSize: 10, color: BowlColors.muted),
            ),
          ],
        ),
        onTap: onTap,
      ),
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
        final games = controller.data.sessionGames(session.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(controller.data.alley(session.alleyId)!.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
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
          onChanged: (v) => setState(() => query = v),
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
                onSelected: (_) => setState(() => league = item.$2),
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
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SessionCard(
              session: s,
              data: data,
              onTap: () => showSession(context, widget.controller, s),
            ),
          ),
      ],
    );
  }
}
