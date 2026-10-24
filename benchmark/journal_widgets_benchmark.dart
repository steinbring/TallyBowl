import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';

void main() {
  testWidgets('measure views with 10,000 games and 1,000 sessions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = [
      for (var i = 0; i < 1000; i++)
        BowlingSession(
          id: 's$i',
          alleyId: 'a${i % 10}',
          startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          finishedAt: DateTime(2026, 1, 1).add(Duration(days: i, hours: 2)),
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
    final controller = BowlController(null, data);
    final timings = <String, Object>{
      'games': 10000,
      'sessions': 1000,
      'runtime':
          'Flutter widget test / Dart JIT on ${Platform.operatingSystem}',
    };
    final watch = Stopwatch()..start();
    await tester.pumpWidget(TallyBowlApp(controller: controller));
    await tester.pumpAndSettle();
    timings['Tonight_ms'] = watch.elapsedMilliseconds;
    for (final page in ['History', 'Insights', 'Alleys']) {
      watch.reset();
      await tester.tap(find.widgetWithText(ListTile, page));
      await tester.pumpAndSettle();
      timings['${page}_ms'] = watch.elapsedMilliseconds;
      expect(tester.takeException(), isNull);
    }
    await tester.runAsync(() async {
      final folder = await Directory('build/benchmarks')
          .create(recursive: true);
      await File('${folder.path}/journal-widgets.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(timings)}\n',
      );
    });
    stdout.writeln(jsonEncode(timings));
  });
}
