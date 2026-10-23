import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/domain/models.dart';

void main() {
  test('measure and verify a 10,000-game journal', () async {
    sqfliteFfiInit();
    final store = await BowlStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final sessions = [
      for (var i = 0; i < 1000; i++)
        BowlingSession(
          id: 's$i',
          alleyId: 'a${i % 10}',
          startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          finishedAt: i == 999
              ? null
              : DateTime(2026, 1, 1).add(Duration(days: i, hours: 2)),
        ),
    ];
    final data = BowlData(
      alleys: [
        for (var i = 0; i < 10; i++)
          BowlingAlley(id: 'a$i', name: 'Synthetic lanes $i'),
      ],
      balls: const [BowlingBall(id: 'b', name: 'Synthetic ball')],
      sessions: sessions,
      games: [
        for (var i = 0; i < 10000; i++)
          BowlingGame(
            id: 'g$i',
            sessionId: 's${i ~/ 10}',
            frames: List.filled(10, '9-'),
            createdAt: sessions[i ~/ 10].startedAt,
            ballIds: const ['b'],
          ),
      ],
    );
    final results = <String, Object>{
      'games': 10000,
      'sessions': 1000,
      'runtime': 'Flutter test / Dart JIT on ${Platform.operatingSystem}',
    };
    final timer = Stopwatch()..start();
    try {
      data.validate();
      results['validation_ms'] = timer.elapsedMilliseconds;
      timer.reset();
      await store.save(data);
      results['initial_save_ms'] = timer.elapsedMilliseconds;
      timer.reset();
      final loaded = await store.load();
      results['load_ms'] = timer.elapsedMilliseconds;
      expect(loaded.games.length, 10000);
      await store.database.execute('CREATE TABLE audit (event TEXT)');
      for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
        await store.database.execute(
          "CREATE TRIGGER audit_$event AFTER $event ON games BEGIN INSERT INTO audit VALUES ('$event'); END",
        );
      }
      final controller = BowlController(store, loaded);
      timer.reset();
      await controller.saveDraft({
        'sessionId': 's999',
        'frames': ['X', ...List.filled(9, '')],
      });
      results['draft_save_ms'] = timer.elapsedMilliseconds;
      expect(await store.database.query('audit'), isEmpty);
      expect(controller.data.games.last.score, 90);
      expect((await store.load()).draft!['frames'].first, 'X');
      final directory = await Directory('build/benchmarks')
          .create(recursive: true);
      await File('${directory.path}/journal.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(results)}\n',
      );
      // Observations, not a machine-dependent timing assertion or device claim.
      stdout.writeln(jsonEncode(results));
    } finally {
      await store.close();
    }
  });
}
