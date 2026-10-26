import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';

// The same raster cases run against Apple Vision and Android ML Kit bridges.
// Keep these in step with docs/RECOGNITION_STROKES.md.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final lightBackground in [false, true]) {
    final label = lightBackground ? 'paper' : 'monitor';
    for (final scenario in ['dash', 'blank', 'grid', 'outside band', 'limit']) {
      testWidgets('$label: native stroke recovery $scenario', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final foreground = lightBackground ? Colors.black : Colors.white;
        canvas.drawColor(
          lightBackground ? Colors.white : const Color(0xff282838),
          BlendMode.src,
        );
        final paint = Paint()..color = foreground;
        final expected = <Rect>[];
        if (scenario == 'dash') {
          expected.add(const Rect.fromLTWH(70, 28, 18, 4));
        } else if (scenario == 'outside band') {
          canvas.drawRect(const Rect.fromLTWH(70, 2, 18, 4), paint);
        } else if (scenario == 'grid') {
          canvas.drawRect(const Rect.fromLTWH(30, 0, 2, 60), paint);
          canvas.drawRect(const Rect.fromLTWH(0, 28, 120, 2), paint);
        } else if (scenario == 'limit') {
          // Different areas make the retained three deterministic.
          for (var i = 0; i < 4; i++) {
            final rect = Rect.fromLTWH(8.0 + i * 28, 28, 12.0 + i * 2, 4);
            canvas.drawRect(rect, paint);
            if (i > 0) expected.add(rect);
          }
        }
        if (scenario == 'dash') canvas.drawRect(expected.single, paint);
        final picture = recorder.endRecording();
        final image = await picture.toImage(120, 60);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final raw = await PhotoService.channel.invokeMethod<List<dynamic>>(
          'recognizeText',
          {
            'bytes': png!.buffer.asUint8List(),
            'regions': [
              {'x': 0.0, 'y': 0.0, 'width': 1.0, 'height': 1.0},
            ],
          },
        );
        final strokes =
            (raw ?? [])
                .cast<Map>()
                .where((line) => line['stroke'] == true)
                .toList()
              ..sort((a, b) => (a['x'] as num).compareTo(b['x'] as num));
        expect(strokes, hasLength(expected.length));
        for (var i = 0; i < expected.length; i++) {
          final actual = strokes[i];
          final target = expected[i];
          expect(actual['text'], '-');
          expect(actual['x'], closeTo(target.left / 120, .01));
          expect(actual['y'], closeTo(target.top / 60, .01));
          expect(actual['width'], closeTo(target.width / 120, .01));
          expect(actual['height'], closeTo(target.height / 60, .01));
        }
        image.dispose();
        picture.dispose();
      });
    }
  }
}
