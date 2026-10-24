import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/photo_capture.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';

BowlData recoveryData() => BowlData(
  alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
  sessions: [
    BowlingSession(id: 's', alleyId: 'a', startedAt: DateTime(2026, 10, 23)),
  ],
);

class _PrivateTestPaths extends PathProviderPlatform {
  _PrivateTestPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  test(
    'reopened pending review keeps its real photo through orphan cleanup',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'tallybowl-pending-photo-',
      );
      final path = '${directory.path}/journal.db';
      final originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _PrivateTestPaths(directory.path);
      addTearDown(() => PathProviderPlatform.instance = originalPaths);
      var store = await BowlStore.open(factory: databaseFactoryFfi, path: path);
      try {
        final source = await PhotoService.retain(
          await File('test/goldens/recap.png').readAsBytes(),
        );
        final orphan = await PhotoService.retain(Uint8List.fromList([1, 2, 3]));
        final outside = await File('${directory.path}/outside.image')
            .writeAsString('keep');
        final controller = BowlController(store, recoveryData());
        await controller.beginPhotoReview('s', source);
        await store.close();
        store = await BowlStore.open(factory: databaseFactoryFfi, path: path);
        final loaded = await store.load();
        expect(loaded.draft!['pendingPhotoReview'], isTrue);
        expect(loaded.draft!['sourcePath'], source);
        await PhotoService.cleanOrphans(loaded.draft!['sourcePath'] as String);
        expect(await File(source).exists(), isTrue);
        expect(await File(orphan).exists(), isFalse);
        expect(await outside.exists(), isTrue);
        final restored = BowlStore.readBackup(BowlStore.encodeBackup(loaded));
        expect(restored.draft!['sourcePath'], isNull);
        expect(restored.draft!['pendingPhotoReview'], isNull);
        await expectLater(
          BowlController(null, loaded).beginPhotoReview('s', '/another.image'),
          throwsStateError,
        );
        await BowlController(store, loaded).discardDraft();
        await PhotoService.cleanOrphans(null);
        expect(await File(source).exists(), isFalse);
        expect(await outside.exists(), isTrue);
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
  testWidgets('recognition failure keeps the source for manual correction', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final controller = BowlController(null, recoveryData());
      final path = '${Directory.current.path}/test/goldens/recap.png';
      final called = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoService.channel,
        (_) async {
          called.complete();
          throw PlatformException(
            code: 'recognition',
            message: 'Fixture failure',
          );
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          PhotoService.channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => importScorePhoto(
                  context,
                  controller,
                  controller.activeSession!,
                  recoveredPath: path,
                ),
                child: const Text('Open photo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await called.future.timeout(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(controller.data.draft!['pendingPhotoReview'], isTrue);
      final manual = find.text('Enter frames with photo');
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      expect(find.byType(GameEditor), findsOneWidget);
      expect(controller.data.draft!['sourcePath'], path);
      expect(controller.data.draft!['pendingPhotoReview'], isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.data.draft!['sourcePath'], path);
      expect(tester.takeException(), isNull);
    });
  });
  testWidgets(
    'failed draft persistence skips OCR and removes the imported file',
    (tester) async {
      await tester.runAsync(() async {
        sqfliteFfiInit();
        final directory = await Directory.systemTemp.createTemp(
          'tallybowl-photo-write-failure-',
        );
        final originalPaths = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _PrivateTestPaths(directory.path);
        addTearDown(() => PathProviderPlatform.instance = originalPaths);
        addTearDown(() => directory.delete(recursive: true));
        final store = await BowlStore.open(
          factory: databaseFactoryFfi,
          path: '${directory.path}/journal.db',
        );
        final source = await PhotoService.retain(
          await File('test/goldens/recap.png').readAsBytes(),
        );
        await store.close();
        final controller = BowlController(store, recoveryData());
        var calls = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          PhotoService.channel,
          (_) async {
            calls++;
            return [];
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            PhotoService.channel,
            null,
          ),
        );
        late Future<void> operation;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    operation = importScorePhoto(
                      context,
                      controller,
                      controller.activeSession!,
                      recoveredPath: source,
                    );
                  },
                  child: const Text('Open photo'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open photo'));
        await operation.timeout(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(controller.data.draft, isNull);
        expect(await File(source).exists(), isFalse);
        expect(
          find.textContaining('Could not open this photo.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );
}
