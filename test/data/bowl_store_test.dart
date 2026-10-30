import 'dart:convert';
import 'dart:io';

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
    'a new database connection recovers the journal after restart',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'tallybowl-db-test-',
      );
      final path = '${folder.path}/journal.db';
      try {
        var disk = await BowlStore.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        await disk.save(sample());
        await disk.close();
        disk = await BowlStore.open(factory: databaseFactoryFfi, path: path);
        expect((await disk.load()).toJson(), sample().toJson());
        await disk.close();
      } finally {
        await folder.delete(recursive: true);
      }
    },
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
  test('ball colors survive database, backup and color removal', () async {
    for (final color in BallColor.values) {
      final data = sample().copyWith(
        balls: [BowlingBall(id: 'b1', name: 'My ball', color: color)],
      );
      await store.save(data);
      final loaded = await store.load();
      expect(loaded.balls.single.color, color);
      expect(
        BowlStore.readBackup(store.backup(loaded)).balls.single.color,
        color,
      );
    }
    final legacy = sample(); // Its JSON has no optional color field.
    expect(legacy.balls.single.toJson().containsKey('color'), isFalse);
    final oldBackup = BowlStore.readBackup(BowlStore.encodeBackup(legacy));
    expect(oldBackup.balls.single.color, isNull);
    await store.save(oldBackup);
    expect((await store.load()).balls.single.color, isNull);
    expect((await store.load()).games.single.score, 90);
  });
  test(
    'backup rejects unsupported ball colors without changing the journal',
    () async {
      await store.save(sample());
      for (final invalid in [
        'magenta sparkle',
        42,
        ['blue'],
      ]) {
        final data = sample().toJson();
        (data['balls'] as List).first['color'] = invalid;
        expect(
          () => BowlStore.readBackup(
            jsonEncode({'format': 'tallybowl', 'version': 1, 'data': data}),
          ),
          throwsFormatException,
        );
      }
      expect((await store.load()).toJson(), sample().toJson());
    },
  );
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
  test('draft autosave leaves every history row untouched', () async {
    final data = sample();
    await store.save(data);
    await store.database.execute('CREATE TABLE audit (event TEXT)');
    for (final table in ['balls', 'alleys', 'sessions', 'games']) {
      for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
        await store.database.execute(
          "CREATE TRIGGER audit_${table}_$event AFTER $event ON $table BEGIN INSERT INTO audit VALUES ('$table $event'); END",
        );
      }
    }
    await store.save(
      data.copyWith(
        draft: {
          'sessionId': 's1',
          'frames': ['X', ...List.filled(9, '')],
        },
      ),
    );
    expect(await store.database.query('audit'), isEmpty);
    expect((await store.load()).draft!['frames'][0], 'X');
  });
  test(
    'failed database transaction rolls back and remains retryable',
    () async {
      final data = sample();
      await store.save(data);
      await store.database.execute(
        "CREATE TRIGGER fail_game BEFORE UPDATE ON games BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final replacement = data.copyWith(
        profile: const BowlerProfile(name: 'Changed'),
        games: [
          BowlingGame(
            id: 'g1',
            sessionId: 's1',
            frames: [...List.filled(9, 'X'), 'XXX'],
            createdAt: data.games.single.createdAt,
          ),
        ],
      );
      await expectLater(
        store.save(replacement),
        throwsA(isA<DatabaseException>()),
      );
      expect((await store.load()).toJson(), data.toJson());
      await store.database.execute('DROP TRIGGER fail_game');
      await store.save(replacement);
      expect((await store.load()).games.single.score, 300);
    },
  );
  test('restore can reorder records and replace foreign-key parents', () async {
    final data = sample().copyWith(
      balls: const [
        BowlingBall(id: 'b1', name: 'First'),
        BowlingBall(id: 'b2', name: 'Second'),
      ],
    );
    await store.save(data);
    final replacement = data.copyWith(
      balls: data.balls.reversed.toList(),
      alleys: const [BowlingAlley(id: 'new', name: 'New lanes')],
      sessions: [
        BowlingSession(
          id: 's1',
          alleyId: 'new',
          startedAt: data.sessions.single.startedAt,
        ),
      ],
    );
    await store.save(replacement);
    expect((await store.load()).toJson(), replacement.toJson());
    expect(await store.database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
  test(
    'upgrades a first-build database without losing record order or drafts',
    () async {
      final folder = await Directory.systemTemp.createTemp('tallybowl-v1-');
      final path = '${folder.path}/journal.db';
      try {
        final legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute(
                'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
              );
              await db.execute(
                'CREATE TABLE balls (id TEXT PRIMARY KEY, document TEXT NOT NULL)',
              );
              await db.execute(
                'CREATE TABLE alleys (id TEXT PRIMARY KEY, document TEXT NOT NULL)',
              );
              await db.execute(
                'CREATE TABLE sessions (id TEXT PRIMARY KEY, alley_id TEXT NOT NULL REFERENCES alleys(id), document TEXT NOT NULL)',
              );
              await db.execute(
                'CREATE TABLE games (id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(id), document TEXT NOT NULL)',
              );
            },
          ),
        );
        final data = sample();
        await legacy.insert('settings', {
          'key': 'profile',
          'value': jsonEncode(data.profile.toJson()),
        });
        await legacy.insert('settings', {
          'key': 'draft',
          'value': jsonEncode(data.draft),
        });
        for (final table in ['balls', 'alleys', 'sessions', 'games']) {
          for (final document in data.toJson()[table] as List) {
            await legacy.insert(table, {
              'id': document['id'],
              'document': jsonEncode(document),
              if (table == 'sessions') 'alley_id': document['alleyId'],
              if (table == 'games') 'session_id': document['sessionId'],
            });
          }
        }
        await legacy.close();
        final upgraded = await BowlStore.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        try {
          expect((await upgraded.load()).toJson(), data.toJson());
          await upgraded.save(
            data.copyWith(
              balls: [
                ...data.balls,
                const BowlingBall(id: 'b2', name: 'Second'),
              ],
            ),
          );
          expect((await upgraded.load()).balls.map((b) => b.id), ['b1', 'b2']);
        } finally {
          await upgraded.close();
        }
      } finally {
        await folder.delete(recursive: true);
      }
    },
  );
}
