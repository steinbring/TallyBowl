import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../ui/layout.dart';
import '../ui/dialogs.dart';
import 'alley_map.dart';

class BagPage extends StatelessWidget {
  const BagPage({super.key, required this.controller});
  final BowlController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Your trusty lineup.',
          'Every ball has a story. Keep yours in your bag.',
          action: FilledButton.icon(
            onPressed: () => editBall(context, controller),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a ball'),
          ),
        ),
        if (data.balls.isEmpty)
          EmptyCard(
            icon: Icons.sports_baseball_rounded,
            title: 'Meet your next favorite ball.',
            body: 'Add the balls you own, then tag them in your games to track usage and scoring trends.',
            action: OutlinedButton(
              onPressed: () => editBall(context, controller),
              child: const Text('Add your first ball'),
            ),
          ),
        LayoutBuilder(
          builder: (context, c) {
            final count = BowlLayout.columns(
              context,
              c.maxWidth,
              minimumWidth: 280,
              maximum: 3,
            );
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < data.balls.length; i++)
                  SizedBox(
                    width: (c.maxWidth - (count - 1) * 16) / count,
                    child: Builder(
                      builder: (context) {
                        final ball = data.balls[i];
                        final games = data.games
                            .where((g) => g.ballIds.contains(ball.id))
                            .toList();
                        final primary = games
                            .where((g) => g.primaryBallId == ball.id)
                            .length;
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => editBall(context, controller, ball),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      BallArt(
                                        size: 68,
                                        color: [
                                          BowlColors.orange,
                                          const Color(0xFF557CB0),
                                          const Color(0xFF56775D),
                                        ][i % 3],
                                      ),
                                      const Spacer(),
                                      if (ball.retired)
                                        const LabelPill('RETIRED'),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    ball.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${ball.brand.isEmpty ? 'Your ball' : ball.brand} · ${ball.weight.toStringAsFixed(ball.weight % 1 == 0 ? 0 : 1)} lb',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    child: Divider(),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${games.length}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'games tagged',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              averageLabel(games),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'game average',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$primary games as primary ball',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (ball.notes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        ball.notes,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AlleysPage extends StatelessWidget {
  const AlleysPage({super.key, required this.controller});
  final BowlController controller;
  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Know your lanes.',
          'Favorite places. Familiar faces. A little home-lane advantage.',
          action: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => pickAlleyOnMap(context, controller),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on map'),
              ),
              FilledButton.icon(
                onPressed: () => editAlley(context, controller),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add an alley'),
              ),
            ],
          ),
        ),
        if (data.alleys.isEmpty)
          EmptyCard(
            icon: Icons.location_on_outlined,
            title: 'Where do you roll?',
            body: 'Save your favorite bowling alleys. Each session adds to their visit history and scoring averages.',
            action: OutlinedButton(
              onPressed: () => editAlley(context, controller),
              child: const Text('Add your first alley'),
            ),
          ),
        for (final alley in data.alleys)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Builder(
              builder: (context) {
                final sessions = data.sessions
                    .where(
                      (s) =>
                          s.alleyId == alley.id &&
                          data.sessionGames(s.id).isNotEmpty,
                    )
                    .toList();
                final ids = sessions.map((s) => s.id).toSet();
                final games = data.games
                    .where((g) => ids.contains(g.sessionId))
                    .toList();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: BowlColors.mint,
                              child: Icon(
                                Icons.location_on_outlined,
                                color: BowlColors.ink,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alley.name,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (alley.address.isNotEmpty)
                                    Text(
                                      alley.address,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (alley.retired) const LabelPill('ARCHIVED'),
                            IconButton(
                              tooltip: 'Edit alley',
                              onPressed: () =>
                                  editAlley(context, controller, alley),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 28,
                          runSpacing: 12,
                          children: [
                            Text(
                              '${sessions.length} visits',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text('${games.length} games'),
                            Text('${averageLabel(games)} average'),
                          ],
                        ),
                        if (alley.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(alley.notes),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
