import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';

class GrowingPhoto extends XFile {
  GrowingPhoto() : super('growing-photo');
  @override
  Future<int> length() async => 1;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    final chunk = Uint8List(1024 * 1024);
    for (var i = 0; i < 41; i++) {
      yield chunk;
    }
  }
}

void main() {
  test(
    'photo reader caps files before allocation and checks a growing stream',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tallybowl-photo-size-',
      );
      try {
        final file = File('${directory.path}/large.photo');
        final handle = await file.open(mode: FileMode.write);
        await handle.truncate(PhotoService.maxPhotoBytes + 1);
        await handle.close();
        await expectLater(
          PhotoService.readPhoto(XFile(file.path)),
          throwsFormatException,
        );
        await expectLater(
          PhotoService.readPhoto(GrowingPhoto()),
          throwsFormatException,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test('editing inventory keeps display order stable', () async {
    final controller = BowlController(
      null,
      const BowlData(
        balls: [
          BowlingBall(id: 'a', name: 'First'),
          BowlingBall(id: 'b', name: 'Second'),
        ],
        alleys: [
          BowlingAlley(id: 'a', name: 'First'),
          BowlingAlley(id: 'b', name: 'Second'),
        ],
      ),
    );
    await controller.saveBall(const BowlingBall(id: 'a', name: 'Renamed'));
    await controller.saveAlley(const BowlingAlley(id: 'a', name: 'Renamed'));
    expect(controller.data.balls.map((b) => b.id), ['a', 'b']);
    expect(controller.data.alleys.map((a) => a.id), ['a', 'b']);
  });
  testWidgets('existing game edits require confirmation before discarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026, 10, 23),
    );
    final game = BowlingGame(
      id: 'g',
      sessionId: 's',
      frames: List.filled(10, '9-'),
      createdAt: session.startedAt,
    );
    final controller = BowlController(
      null,
      BowlData(
        alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
        sessions: [session],
        games: [game],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  openGameEditor(context, controller, session, game: game),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('frame-0')), '8-');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('frame-0')))
          .controller!
          .text,
      '8-',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(controller.data.games.single.score, 90);
    expect(tester.takeException(), isNull);
  });
}
