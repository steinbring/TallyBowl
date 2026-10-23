import 'dart:ui' as ui;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';
import 'package:tallybowl/src/features/session_share.dart';
import 'package:tallybowl/src/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('renders a branded recap PNG entirely on the device', (
    tester,
  ) async {
    final session = BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026, 10, 23),
    );
    final data = BowlData(
      profile: const BowlerProfile(name: 'Sample bowler'),
      alleys: const [BowlingAlley(id: 'a', name: 'Sample lanes')],
      sessions: [session],
      games: [
        BowlingGame(
          id: 'g',
          sessionId: 's',
          frames: List.filled(10, '9-'),
          createdAt: DateTime(2026, 10, 23),
        ),
      ],
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlTheme,
        home: Scaffold(
          body: Center(
            child: FittedBox(
              child: RepaintBoundary(
                key: key,
                child: RecapCard(data: data, session: session),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final preview = File(
      '${(await getTemporaryDirectory()).path}/tallybowl-integration-recap.png',
    );
    await preview.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    debugPrint('Synthetic recap preview: ${preview.path}');
    expect(image.width, 1080);
    expect(png.buffer.asUint8List().take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(find.text('tallybowl.jws.app'), findsOneWidget);
    image.dispose();
  });
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
        text: 'Sample bowler    X    X    X    X    X    X    X    X    X    XXX    300',
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
      const BowlerProfile(name: 'Sample bowler', aliases: ['JWS']),
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
