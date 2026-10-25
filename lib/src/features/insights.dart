import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../domain/journal_index.dart';
import '../ui/common.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.controller});
  final BowlController controller;
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool? league;
  int days = 0;
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final since = days == 0
        ? null
        : DateTime.now().subtract(Duration(days: days));
    final sessions = data.sessions
        .where(
          (s) =>
              (league == null || s.league == league) &&
              (since == null || !s.startedAt.isBefore(since)),
        )
        .toList();
    final ids = sessions.map((s) => s.id).toSet();
    final games = data.games.where((g) => ids.contains(g.sessionId)).toList();
    final journal = JournalIndex(sessions, games);
    final strikes = games.fold<int>(0, (n, g) => n + g.result.strikes);
    final spares = games.fold<int>(0, (n, g) => n + g.result.spares);
    final opportunities = games.fold<int>(
      0,
      (n, g) => n + g.result.spareOpportunities,
    );
    final recent = games.length > 12 ? games.sublist(games.length - 12) : games;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Find your rhythm.',
          'Small patterns. Better questions. More nights on the lanes.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final item in <(String, bool?)>[
              ('All games', null),
              ('League', true),
              ('Practice', false),
            ])
              ChoiceChip(
                label: Text(item.$1),
                selected: league == item.$2,
                onSelected: (_) => setState(() => league = item.$2),
              ),
            const SizedBox(width: 12),
            for (final item in [
              ('All time', 0),
              ('90 days', 90),
              ('30 days', 30),
            ])
              ChoiceChip(
                label: Text(item.$1),
                selected: days == item.$2,
                onSelected: (_) => setState(() => days = item.$2),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (games.isEmpty)
          const EmptyCard(
            icon: Icon(Icons.insights_rounded),
            title: 'Patterns come with practice.',
            body: 'Record a few games to see your averages, strike rate, spare conversions, and equipment comparisons.',
          )
        else ...[
          MetricRow(
            children: [
              MetricCard(
                'Average',
                averageLabel(games),
                '${games.length} games in this view',
                accent: true,
              ),
              MetricCard(
                'High game',
                '${games.map((g) => g.score).reduce((a, b) => a > b ? a : b)}',
                'Scratch score',
              ),
              MetricCard(
                'Strike rate',
                '${(strikes / (games.length * 10) * 100).toStringAsFixed(1)}%',
                '$strikes of ${games.length * 10} frames',
              ),
              MetricCard(
                'Spare conversion',
                opportunities == 0
                    ? '—'
                    : '${(spares / opportunities * 100).toStringAsFixed(1)}%',
                '$spares of $opportunities opportunities',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your recent games',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scratch scores · scale 0–300 · latest 12 saved games',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < recent.length; i++)
                          Semantics(
                            excludeSemantics: true,
                            label:
                                'Game ${games.length - recent.length + i + 1}, score ${recent[i].score}',
                            child: SizedBox(
                              width:
                                  64 *
                                  (MediaQuery.textScalerOf(context).scale(16) /
                                      16),
                              child: Column(
                                children: [
                                  Text(
                                    '${recent[i].score}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 140,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 30,
                                        height: (recent[i].score / 300 * 140)
                                            .clamp(2, 140),
                                        decoration: BoxDecoration(
                                          color: i == recent.length - 1
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'G${games.length - recent.length + i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Comparison(
            title: 'Where you bowl',
            subtitle: 'Visits count sessions with at least one saved game.',
            rows: [
              for (final a in data.alleys.where(
                (a) => journal.gamesAtAlley(a.id).isNotEmpty,
              ))
                (
                  a.name,
                  '${journal.visitsAtAlley(a.id)} visits',
                  journal.gamesAtAlley(a.id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _Comparison(
            title: 'What you roll',
            subtitle: 'Game-level tags overlap when several balls were used. Scores describe those games, not the contribution of a single ball.',
            rows: [
              for (final b in data.balls.where(
                (b) => journal.gamesWithBall(b.id).isNotEmpty,
              ))
                (
                  b.name,
                  '${journal.gamesWithBall(b.id).where((g) => g.primaryBallId == b.id).length} primary',
                  journal.gamesWithBall(b.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Frame strike rate and spare opportunities use frames 1–10, excluding bonus deliveries. These comparisons show associations; lane conditions, practice, and ball selection also affect scores.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.title,
    required this.subtitle,
    required this.rows,
  });
  final String title, subtitle;
  final List<(String, String, List<BowlingGame>)> rows;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty) const Text('No tagged games in this view.'),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${row.$3.length} games · ${row.$2}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    row.$3.isEmpty
                        ? '—'
                        : (row.$3.fold<int>(0, (n, g) => n + g.score) /
                                  row.$3.length)
                              .toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
