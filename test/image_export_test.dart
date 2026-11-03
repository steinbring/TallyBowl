import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tallybowl/src/data/exports.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.directory);
  final String directory;
  @override
  Future<String?> getTemporaryPath() async => directory;
}

void main() {
  test(
    'temporary exports reject path traversal before creating a file',
    () async {
      for (final name in [
        '',
        '.',
        '..',
        '../private.png',
        '/private.png',
        r'..\private.png',
        'name\n.png',
        'bad\u0000.png',
      ]) {
        await expectLater(
          BowlExports.temporaryFile(name, Uint8List(0)),
          throwsArgumentError,
        );
      }
    },
  );

  testWidgets(
    'Android export cancellation and failure never fall back to sharing',
    (tester) async {
      await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'tallybowl-export-',
        );
        final original = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _Paths(directory.path);
        addTearDown(() => PathProviderPlatform.instance = original);
        addTearDown(() => directory.delete(recursive: true));
        BuildContext? context;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        );
        const channel = BowlExports.imageShareChannel;
        var calls = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            expect(call.method, 'saveImage');
            calls++;
            if (calls == 1) {
              return null; // The older-Android save picker was cancelled.
            }
            if (calls == 2) throw PlatformException(code: 'export_image');
            return 'Pictures/TallyBowl';
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        Future<String?> export() => BowlExports.exportFile(
          context!,
          name: 'recap.png',
          mime: 'image/png',
          bytes: Uint8List(8),
        );
        expect(await export(), isNull);
        await expectLater(export(), throwsA(isA<PlatformException>()));
        expect(await export(), 'Pictures/TallyBowl');
        expect(calls, 3);
        expect(tester.takeException(), isNull);
      });
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
