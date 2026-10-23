import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native recognition reads a synthetic score row on the device', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('TallyBowl! · On-device recognition check')),
        ),
      ),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    final text = TextPainter(
      text: const TextSpan(
        text: 'JWS    X    X    X    X    X    X    X    X    X    XXX    300',
        style: TextStyle(
          color: Colors.black,
          fontSize: 72,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 3900);
    text.paint(canvas, const Offset(48, 80));
    final image = await recorder.endRecording().toImage(4000, 300);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final raw = await PhotoService.channel.invokeMethod<List<dynamic>>(
      'recognizeText',
      {'bytes': data!.buffer.asUint8List()},
    );
    final lines = (raw ?? [])
        .map((v) => RecognizedLine.fromJson(v as Map))
        .toList();
    final rows = ScoreSheetParser.rows(
      lines,
      const BowlerProfile(name: 'Joe', aliases: ['JWS']),
    );
    expect(
      rows.any(
        (row) => row.suggested && row.extracted && row.displayedTotal == 300,
      ),
      isTrue,
      reason: 'Recognized text: ${lines.map((l) => l.text).join(' | ')}',
    );
    image.dispose();
  });
}
