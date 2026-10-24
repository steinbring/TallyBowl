import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';

void main() {
  BowlController journal() => BowlController(
    null,
    BowlData(
      alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
      sessions: [
        BowlingSession(
          id: 's',
          alleyId: 'a',
          startedAt: DateTime(2026, 10, 24),
        ),
      ],
    ),
  );
  test('photo reservation releases only its own operation', () async {
    final controller = journal();
    final first = await controller.reservePhotoAcquisition(sessionId: 's');
    await expectLater(
      controller.reservePhotoAcquisition(sessionId: 's'),
      throwsStateError,
    );
    first();
    final second = await controller.reservePhotoAcquisition(sessionId: 's');
    first(); // A stale completion must not unlock the next operation.
    expect(controller.isAcquiringPhoto, isTrue);
    await expectLater(
      controller.saveDraft({'sessionId': 's', 'frames': List.filled(10, '')}),
      throwsStateError,
    );
    second();
    expect(controller.isAcquiringPhoto, isFalse);
  });
  test(
    'acquisition waits for earlier writes and rejects a finished session',
    () async {
      final controller = journal();
      final finishing = controller.finishSession('s');
      await expectLater(
        controller.reservePhotoAcquisition(sessionId: 's'),
        throwsStateError,
      );
      await finishing;
      expect(controller.activeSession, isNull);
      expect(controller.isAcquiringPhoto, isFalse);
    },
  );
  testWidgets(
    'pending camera acquisition protects its session and releases on cancellation',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BowlingSession(
        id: 's',
        alleyId: 'a',
        startedAt: DateTime(2026, 10, 24),
      );
      final controller = BowlController(
        null,
        BowlData(
          alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
          sessions: [session],
        ),
      );
      final camera = Completer<Uint8List?>();
      var calls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoService.channel,
        (call) {
          expect(call.method, 'capturePhoto');
          calls++;
          return camera.future;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          PhotoService.channel,
          null,
        ),
      );
      await tester.pumpWidget(TallyBowlApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Scan scoreboard'));
      await tester.tap(find.text('Scan scoreboard'));
      await tester.pump();
      try {
        expect(calls, 1);
        final record = tester.widget<ButtonStyleButton>(
          find
              .ancestor(
                of: find.text('Record a game'),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              )
              .first,
        );
        expect(record.onPressed, isNull);
        await expectLater(controller.finishSession('s'), throwsStateError);
        await expectLater(
          controller.restore(const BowlData()),
          throwsStateError,
        );
      } finally {
        camera.complete(null);
        await tester.pumpAndSettle();
      }
      expect(controller.activeSession, same(session));
      expect(controller.data.draft, isNull);
      final record = tester.widget<ButtonStyleButton>(
        find
            .ancestor(
              of: find.text('Record a game'),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .first,
      );
      expect(record.onPressed, isNotNull);
    },
  );
}
