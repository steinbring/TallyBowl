import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/photo_capture.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';

BowlData recoveryData() => BowlData(
  alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
  sessions: [
    BowlingSession(id: 's', alleyId: 'a', startedAt: DateTime(2026, 10, 23)),
  ],
);

void main() {
  test(
    'pending photo review survives database reopen but not portable backup',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'tallybowl-pending-photo-',
      );
      final path = '${directory.path}/journal.db';
      var store = await BowlStore.open(factory: databaseFactoryFfi, path: path);
      try {
        final controller = BowlController(store, recoveryData());
        await controller.beginPhotoReview('s', '/private/imports/photo.image');
        await store.close();
        store = await BowlStore.open(factory: databaseFactoryFfi, path: path);
        final loaded = await store.load();
        expect(loaded.draft!['pendingPhotoReview'], isTrue);
        expect(loaded.draft!['sourcePath'], '/private/imports/photo.image');
        final restored = BowlStore.readBackup(BowlStore.encodeBackup(loaded));
        expect(restored.draft!['sourcePath'], isNull);
        expect(restored.draft!['pendingPhotoReview'], isNull);
        await expectLater(
          BowlController(null, loaded).beginPhotoReview('s', '/another.image'),
          throwsStateError,
        );
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );
  for (final resume in [false, true]) {
    testWidgets(
      resume
          ? 'resume returns to the retained photo review'
          : 'photo is retained before recognition completes',
      (tester) async {
        final controller = BowlController(null, recoveryData());
        final path = '${Directory.current.path}/test/goldens/recap.png';
        if (resume) await controller.beginPhotoReview('s', path);
        final pending = Completer<List<dynamic>>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              PhotoService.channel,
              (_) => pending.future,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(PhotoService.channel, null),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    if (resume) {
                      recordOrResumeGame(
                        context,
                        controller,
                        controller.activeSession!,
                      );
                    } else {
                      importScorePhoto(
                        context,
                        controller,
                        controller.activeSession!,
                        recoveredPath: path,
                      );
                    }
                  },
                  child: const Text('Open photo'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open photo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(controller.data.draft!['sourcePath'], path);
        expect(controller.data.draft!['pendingPhotoReview'], isTrue);
        expect(find.byType(PhotoReviewPage), findsOneWidget);
        await tester.pageBack();
        pending.complete([]);
        await tester.pumpAndSettle();
        expect(controller.data.draft, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
