import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'common.dart';

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
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return MergeSemantics(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Game $number',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${game.score}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                if (game.lane.isNotEmpty)
                  Text('Lane ${game.lane}', style: TextStyle(color: muted)),
                const SizedBox(height: 6),
                Text(
                  game.ballIds.isEmpty
                      ? 'No ball tags'
                      : game.ballIds
                            .map((id) => data.ball(id)!.name)
                            .join(' · '),
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.result.strikes} strikes · ${game.result.spares} spares',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.data,
    required this.games,
    required this.onTap,
  });
  final BowlingSession session;
  final BowlData data;
  final List<BowlingGame> games;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return MergeSemantics(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.alley(session.alleyId)!.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${dateLabel(session.startedAt)} · ${session.league ? 'League' : 'Practice'} · ${games.length} games${session.finished ? '' : ' · In progress'}',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Average: ${averageLabel(games)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
