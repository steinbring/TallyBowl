import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/photo_capture.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/theme.dart';

void main() {
  final session = BowlingSession(
    id: 's',
    alleyId: 'a',
    startedAt: DateTime(2026, 11, 14),
  );

  /// Opens the review page for a photo in which the engine finds no text.
  Future<List<PhotoSelection?>> openUnreadable(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoService.channel,
      (_) async => <Object>[],
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoService.channel,
        null,
      ),
    );
    final controller = BowlController(
      null,
      BowlData(
        profile: const BowlerProfile(name: 'Bowler'),
        alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
        sessions: [session],
      ),
    );
    final results = <PhotoSelection?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await Navigator.of(context).push<PhotoSelection>(
                  MaterialPageRoute(
                    builder: (_) => PhotoReviewPage(
                      controller: controller,
                      session: session,
                      path:
                          '${Directory.current.path}/test/fixtures/practice_89.png',
                    ),
                  ),
                ),
              ),
              child: const Text('Open photo'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open photo'));
    // Recognition and raster measurement finish outside fake time.
    for (
      var i = 0;
      i < 300 && find.text('Another photo may read better').evaluate().isEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 100));
    }
    return results;
  }

  testWidgets('an unreadable photo explains why and offers a retake', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await openUnreadable(tester);
      expect(find.text('Another photo may read better'), findsOneWidget);
      expect(
        find.textContaining('No scoreboard text was found'),
        findsOneWidget,
      );
      expect(find.text('Take another photo'), findsOneWidget);
      expect(find.text('Choose another'), findsOneWidget);
    });
  });

  testWidgets('the retake prompt can be dismissed to keep this photo', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final results = await openUnreadable(tester);
      await tester.tap(find.text('Use this photo anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Another photo may read better'), findsNothing);
      expect(
        find.text('My row isn’t listed · Enter frames myself'),
        findsOneWidget,
      );
      expect(results, isEmpty);
    });
  });

  testWidgets('the close button also dismisses the prompt', (tester) async {
    await tester.runAsync(() async {
      await openUnreadable(tester);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Another photo may read better'), findsNothing);
    });
  });

  for (final camera in [true, false]) {
    testWidgets(
      'retake returns to the ${camera ? 'camera' : 'photo library'}',
      (tester) async {
        await tester.runAsync(() async {
          final results = await openUnreadable(tester);
          await tester.tap(
            find.text(camera ? 'Take another photo' : 'Choose another'),
          );
          await tester.pumpAndSettle();
          expect(results.single?.retakeWithCamera, camera);
          expect(results.single?.row, isNull);
        });
      },
    );
  }
}
