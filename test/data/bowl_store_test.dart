import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late BowlStore store;
  setUp(() async {
    store = await BowlStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() => store.close());
  BowlData sample() => BowlData(
    profile: const BowlerProfile(name: 'Joe', aliases: ['JWS']),
    balls: const [BowlingBall(id: 'b1', name: 'My ball')],
    alleys: const [BowlingAlley(id: 'a1', name: 'Home lanes')],
    sessions: [
      BowlingSession(
        id: 's1',
        alleyId: 'a1',
        startedAt: DateTime(2026, 10, 23),
        lane: '7–8',
      ),
    ],
    games: [
      BowlingGame(
        id: 'g1',
        sessionId: 's1',
        frames: List.filled(10, '9-'),
        createdAt: DateTime(2026, 10, 23),
        ballIds: ['b1'],
        primaryBallId: 'b1',
      ),
    ],
    draft: {'sessionId': 's1', 'frames': List.filled(10, '')},
  );
  test(
    'database and backup preserve frame records, references and drafts',
    () async {
      final data = sample();
      await store.save(data);
      final loaded = await store.load();
      expect(loaded.toJson(), data.toJson());
      final backup = store.backup(loaded);
      final restored = BowlStore.readBackup(backup);
      expect(restored.toJson(), data.toJson());
      expect(restored.games.single.score, 90);
    },
  );
  test('invalid replacement leaves the saved history intact', () async {
    final data = sample();
    await store.save(data);
    await expectLater(
      store.save(data.copyWith(balls: [])),
      throwsFormatException,
    );
    expect((await store.load()).games.single.score, 90);
  });
  test(
    'backup rejects broken references, incomplete games and future formats',
    () {
      final data = sample().toJson();
      final envelope = {'format': 'tallybowl', 'version': 1, 'data': data};
      (data['games'] as List).first['frames'] = List.filled(10, '');
      expect(
        () => BowlStore.readBackup(jsonEncode(envelope)),
        throwsFormatException,
      );
      expect(
        () => BowlStore.readBackup('{"format":"tallybowl","version":99}'),
        throwsFormatException,
      );
      expect(() => BowlStore.readBackup('not a backup'), throwsFormatException);
    },
  );
}
