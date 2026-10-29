import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/recognized_text.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('context crop keeps original coordinates and validates bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Local context check'))),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
    final text = TextPainter(
      text: const TextSpan(
        text: 'FOCUS 123',
        style: TextStyle(color: Colors.black, fontSize: 90),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(450, 650));
    final picture = recorder.endRecording();
    final image = await picture.toImage(2000, 1500);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    try {
      final result = await PhotoService.channel.invokeMethod<List<dynamic>>(
        'recognizeText',
        {
          'bytes': bytes,
          'aspect': 1.5,
          'context': true,
          'regions': [
            {'x': .2, 'y': .4, 'width': .5, 'height': .2},
          ],
        },
      );
      final lines = (result ?? [])
          .map((v) => RecognizedLine.fromJson(v as Map))
          .toList();
      expect(lines.any((l) => l.text.contains('123')), true);
      expect(
        lines.every(
          (l) =>
              l.x >= .19 &&
              l.y >= .39 &&
              l.x + l.width <= .71 &&
              l.y + l.height <= .61 &&
              !l.isStroke,
        ),
        true,
      );
      await expectLater(
        PhotoService.channel.invokeMethod('recognizeText', {
          'bytes': bytes,
          'context': true,
        }),
        throwsA(isA<PlatformException>()),
      );
    } finally {
      image.dispose();
      picture.dispose();
    }
  });
}
