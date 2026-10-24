import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/journal_index.dart';
import 'package:tallybowl/src/domain/models.dart';

void main() {
  final sessions = [
    for (var i = 0; i < 3; i++)
      BowlingSession(
        id: 's$i',
        alleyId: i < 2 ? 'a' : 'empty',
        startedAt: DateTime(2026, 1, i + 1),
        finishedAt: DateTime(2026, 1, i + 1, 2),
      ),
  ];
  BowlingGame game(String id, String session, List<String> balls) =>
      BowlingGame(
        id: id,
        sessionId: session,
        createdAt: DateTime(2026),
        frames: List.filled(10, '9-'),
        ballIds: balls,
      );
  final games = [
    game('1', 's0', ['b', 'c']),
    game('2', 's0', ['b']),
    game('3', 's1', []),
  ];

  test(
    'groups preserve order, overlapping tags and distinct recorded visits',
    () {
      final index = JournalIndex(sessions, games);
      expect(index.gamesForSession('s0'), games.take(2));
      expect(index.gamesAtAlley('a'), games);
      expect(index.gamesWithBall('b'), games.take(2));
      expect(index.gamesWithBall('c'), [games.first]);
      expect(index.visitsAtAlley('a'), 2);
      expect(index.visitsAtAlley('empty'), 0);
      expect(index.visitedAlleyCount, 1);
      expect(index.gamesForSession('missing'), isEmpty);
      expect(index.gamesAtAlley('missing'), isEmpty);
      expect(index.gamesWithBall('missing'), isEmpty);
      expect(() => index.gamesAtAlley('a').clear(), throwsUnsupportedError);
    },
  );

  test('controller reuses record index and invalidates saved/deleted/restored games', () async {
    final data = BowlData(
      alleys: const [
        BowlingAlley(id: 'a', name: 'Lanes'),
        BowlingAlley(id: 'empty', name: 'Other lanes'),
      ],
      balls: const [
        BowlingBall(id: 'b', name: 'Ball B'),
        BowlingBall(id: 'c', name: 'Ball C'),
      ],
      sessions: sessions,
      games: games,
    );
    final controller = BowlController(null, data);
    final initial = controller.journal;
    await controller.saveProfile(const BowlerProfile(name: 'Joe'));
    await controller.saveBall(const BowlingBall(id: 'b', name: 'Renamed'));
    expect(controller.journal, same(initial));
    await controller.saveGame(game('4', 's2', ['b']));
    final added = controller.journal;
    expect(added, isNot(same(initial)));
    expect(added.visitsAtAlley('empty'), 1);
    expect(initial.visitsAtAlley('empty'), 0);
    await controller.deleteGame('4');
    expect(controller.journal, isNot(same(added)));
    expect(controller.journal.visitsAtAlley('empty'), 0);
    await controller.restore(data.copyWith(games: [games.first]));
    expect(controller.journal.gamesWithBall('b'), [games.first]);
    expect(controller.journal.visitsAtAlley('a'), 1);
    await controller.startSession(
      BowlingSession(id: 'active', alleyId: 'a', startedAt: DateTime(2026, 2)),
    );
    final activeIndex = controller.journal;
    await controller.saveDraft({
      'sessionId': 'active',
      'frames': List.filled(10, ''),
    });
    expect(controller.journal, same(activeIndex));
    await controller.discardDraft();
    await controller.finishSession('active');
    expect(controller.journal, isNot(same(activeIndex)));
    expect(controller.journal.visitsAtAlley('a'), 1);
  });
}
