import 'models.dart';

/// Read-only groups for one journal snapshot. Controller mutations replace the
/// session/game lists; inventory, profile and draft edits can reuse these groups.
class JournalIndex {
  JournalIndex(this._sessions, this._games) {
    final sessionsById = {for (final s in _sessions) s.id: s};
    final visits = <String, Set<String>>{};
    for (final game in _games) {
      (_bySession[game.sessionId] ??= []).add(game);
      final alleyId = sessionsById[game.sessionId]?.alleyId;
      if (alleyId != null) {
        (_byAlley[alleyId] ??= []).add(game);
        (visits[alleyId] ??= {}).add(game.sessionId);
      }
      for (final ballId in game.ballIds.toSet()) {
        (_byBall[ballId] ??= []).add(game);
      }
    }
    for (final groups in [_bySession, _byAlley, _byBall]) {
      groups.updateAll((_, games) => List.unmodifiable(games));
    }
    _visitCounts.addAll({
      for (final v in visits.entries) v.key: v.value.length,
    });
  }

  final List<BowlingSession> _sessions;
  final List<BowlingGame> _games;
  final _bySession = <String, List<BowlingGame>>{};
  final _byAlley = <String, List<BowlingGame>>{};
  final _byBall = <String, List<BowlingGame>>{};
  final _visitCounts = <String, int>{};

  bool matches(List<BowlingSession> sessions, List<BowlingGame> games) =>
      identical(sessions, _sessions) && identical(games, _games);
  List<BowlingGame> gamesForSession(String id) => _bySession[id] ?? const [];
  List<BowlingGame> gamesAtAlley(String id) => _byAlley[id] ?? const [];
  List<BowlingGame> gamesWithBall(String id) => _byBall[id] ?? const [];
  int visitsAtAlley(String id) => _visitCounts[id] ?? 0;
  int get visitedAlleyCount => _visitCounts.length;
}
