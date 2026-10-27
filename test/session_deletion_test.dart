import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/journal.dart';

BowlData sample() => BowlData(
  alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
  balls: const [BowlingBall(id: 'b', name: 'My ball')],
  sessions: [
    BowlingSession(
      id: 'old',
      alleyId: 'a',
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026, 1, 2),
    ),
    BowlingSession(id: 'active', alleyId: 'a', startedAt: DateTime(2026, 1, 3)),
  ],
  games: [
    for (final id in ['old', 'active'])
      BowlingGame(
        id: 'g-$id',
        sessionId: id,
        frames: List.filled(10, '9-'),
        createdAt: DateTime(2026),
        ballIds: const ['b'],
      ),
  ],
  draft: {
    'sessionId': 'active',
    'frames': List.filled(10, ''),
    'sourcePath': '/private/test-photo.image',
  },
);
void main() {
  sqfliteFfiInit();
  test('deleting a session persists its games and draft atomically', () async {
    final store = await BowlStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);
    await store.save(sample());
    final c = BowlController(store, await store.load());
    addTearDown(c.dispose);
    expect(await c.deleteSession('active'), '/private/test-photo.image');
    expect(c.activeSession, isNull);
    expect(c.data.draft, isNull);
    expect(c.data.sessions.single.id, 'old');
    expect(c.data.games.single.sessionId, 'old');
    expect(c.journal.gamesForSession('active'), isEmpty);
    expect(c.data.alleys, hasLength(1));
    expect(c.data.balls, hasLength(1));
    expect((await store.load()).toJson(), c.data.toJson());
  });
  test(
    'deleting past history preserves another session and its draft',
    () async {
      final c = BowlController(null, sample());
      addTearDown(c.dispose);
      expect(await c.deleteSession('old'), isNull);
      expect(c.data.draft!['sessionId'], 'active');
      expect(c.activeSession!.id, 'active');
      expect(c.data.games.single.sessionId, 'active');
    },
  );
  test('a failed transaction preserves everything and allows retry', () async {
    final store = await BowlStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);
    await store.save(sample());
    final c = BowlController(store, await store.load());
    addTearDown(c.dispose);
    final before = c.data.toJson();
    await store.database.execute(
      "CREATE TRIGGER fail_session BEFORE DELETE ON sessions BEGIN SELECT RAISE(ABORT,'disk failure'); END",
    );
    await expectLater(
      c.deleteSession('active'),
      throwsA(isA<DatabaseException>()),
    );
    expect(c.data.toJson(), before);
    expect((await store.load()).toJson(), before);
    await store.database.execute('DROP TRIGGER fail_session');
    await c.deleteSession('active');
    expect(c.data.sessions.single.id, 'old');
  });
  test(
    'photo acquisition prevents deleting a session underneath a picker',
    () async {
      final c = BowlController(null, sample().copyWith(clearDraft: true));
      addTearDown(c.dispose);
      final release = await c.reservePhotoAcquisition(sessionId: 'active');
      await expectLater(c.deleteSession('active'), throwsStateError);
      expect(c.data.sessions, hasLength(2));
      release();
    },
  );
  testWidgets(
    'session detail confirms deletion, supports cancel and returns to history',
    (tester) async {
      final c = BowlController(null, sample());
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSession(context, c, c.data.sessions.first),
                child: const Text('Open session'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open session'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete session'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 saved game'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.data.sessions, hasLength(2));
      await tester.tap(find.byTooltip('Delete session'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete session'));
      await tester.pumpAndSettle();
      expect(find.text('Open session'), findsOneWidget);
      expect(c.data.sessions.single.id, 'active');
      expect(tester.takeException(), isNull);
    },
  );
}
