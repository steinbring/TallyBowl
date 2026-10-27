import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/session_share.dart';

class _ExportPaths extends PathProviderPlatform {
  _ExportPaths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  testWidgets(
    'image handoff hides the date from the attachment name',
    (tester) async {
      final android = defaultTargetPlatform == TargetPlatform.android;
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(1440, 2800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final directory = await Directory.systemTemp.createTemp(
          'tallybowl-recap-privacy-',
        );
        final original = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _ExportPaths(directory.path);
        addTearDown(() => PathProviderPlatform.instance = original);
        addTearDown(() => directory.delete(recursive: true));
        final shared = Completer<Map<dynamic, dynamic>>();
        final dismissed = Completer<String>();
        final channel = MethodChannel(
          android
              ? 'app.jws.tallybowl/share'
              : 'dev.fluttercommunity.plus/share',
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) {
            shared.complete(call.arguments as Map);
            return dismissed.future;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final session = BowlingSession(
          id: 's',
          alleyId: 'a',
          startedAt: DateTime(2026, 10, 23),
        );
        final data = BowlData(
          alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
          sessions: [session],
          games: [
            BowlingGame(
              id: 'g',
              sessionId: 's',
              frames: List.filled(10, '9-'),
              createdAt: session.startedAt,
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: SessionSharePage(data: data, session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share image'));
        await tester.pump();
        // Continue painting while a cold asset decode completes, as a real
        // application does before exporting the finished recap.
        for (var i = 0; i < 100 && !shared.isCompleted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump(const Duration(milliseconds: 16));
        }
        final args = await shared.future.timeout(const Duration(seconds: 10));
        try {
          final path = android
              ? args['path'] as String
              : (args['paths'] as List).single as String;
          expect(await File(path).exists(), isTrue);
          if (!android) expect(args['mimeTypes'], ['image/png']);
          expect(args.containsKey('text'), isFalse);
          final png = await File(path).readAsBytes();
          expect(png.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
          final codec = await ui.instantiateImageCodec(png);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1080);
          frame.image.dispose();
          codec.dispose();
          expect(p.basename(path), 'tallybowl-recap.png');
          expect(path, isNot(contains('2026-10-23')));
          for (final chip in tester.widgetList<FilterChip>(
            find.byType(FilterChip),
          )) {
            expect(chip.onSelected, isNull);
          }
        } finally {
          dismissed.complete('');
          await tester.pumpAndSettle();
        }
      });
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );
}
