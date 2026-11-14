import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/photo_quality.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

/// A synthetic score band: [count] light bars of [textHeight] pixels on black,
/// optionally blurred or dimmed, plus the text boxes an engine would report.
Future<(Uint8List, List<RecognizedLine>)> band({
  double textHeight = 60,
  double blur = 0,
  int ink = 240,
  int count = 10,
}) async {
  const width = 1600.0, height = 900.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, width, height),
    ui.Paint()..color = const ui.Color(0xFF101010),
  );
  final paint = ui.Paint()..color = ui.Color.fromARGB(255, ink, ink, ink);
  if (blur > 0) {
    paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
  }
  final lines = <RecognizedLine>[];
  for (var i = 0; i < count; i++) {
    final x = 100 + i * 140.0, y = 400.0;
    // Two strokes per "character" give real edges inside each box.
    canvas.drawRect(
      ui.Rect.fromLTWH(x, y, textHeight * .18, textHeight),
      paint,
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(x + textHeight * .4, y, textHeight * .18, textHeight),
      paint,
    );
    lines.add(
      RecognizedLine(
        text: '${i + 1}',
        x: x / width,
        y: y / height,
        width: textHeight * .6 / width,
        height: textHeight / height,
      ),
    );
  }
  final image = await recorder.endRecording().toImage(
    width.round(),
    height.round(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return (png!.buffer.asUint8List(), lines);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calibrated thresholds name each likely photo problem', () {
    PhotoMeasurements m({
      double text = 100,
      double sharp = .5,
      double contrast = 150,
    }) => PhotoMeasurements(
      textHeight: text,
      sharpness: sharp,
      contrast: contrast,
    );
    expect(PhotoQuality.issuesFor(m()), isEmpty);
    expect(PhotoQuality.issuesFor(m(text: 0, sharp: .1, contrast: 20)), [
      PhotoIssue.noText,
    ]);
    expect(PhotoQuality.issuesFor(m(text: 22)), [PhotoIssue.smallText]);
    expect(PhotoQuality.issuesFor(m(sharp: .2)), [PhotoIssue.blurry]);
    expect(PhotoQuality.issuesFor(m(contrast: 50)), [PhotoIssue.underexposed]);
    // Sharpness is judged relative to text size; tiny text gets its own advice.
    expect(PhotoQuality.issuesFor(m(text: 22, sharp: .1)), [
      PhotoIssue.smallText,
    ]);
  });

  test(
    'measures blur, dim ink and small text from the photographed band',
    () async {
      final (sharpBytes, sharpLines) = await band();
      final sharp = await PhotoQuality.measure(sharpBytes, sharpLines);
      expect(sharp.textHeight, closeTo(60, 1));
      expect(PhotoQuality.issuesFor(sharp), isEmpty);

      final (blurBytes, blurLines) = await band(blur: 12);
      final blurred = await PhotoQuality.measure(blurBytes, blurLines);
      expect(blurred.sharpness, lessThan(sharp.sharpness));
      expect(PhotoQuality.issuesFor(blurred), contains(PhotoIssue.blurry));

      final (dimBytes, dimLines) = await band(ink: 60);
      expect(
        PhotoQuality.issuesFor(await PhotoQuality.measure(dimBytes, dimLines)),
        contains(PhotoIssue.underexposed),
      );

      final (smallBytes, smallLines) = await band(textHeight: 20);
      expect(
        PhotoQuality.issuesFor(
          await PhotoQuality.measure(smallBytes, smallLines),
        ),
        [PhotoIssue.smallText],
      );
    },
  );

  test('a missing bowler name is reported unless no text was found', () async {
    const profile = BowlerProfile(name: 'Bowler');
    final (bytes, lines) = await band();
    final other = ScoreRow(
      text: 'Someone',
      frames: List.filled(10, ''),
      suggested: false,
      y: .4,
      height: .1,
    );
    expect((await PhotoQuality.assess(bytes, lines, [other], profile)).issues, [
      PhotoIssue.nameMissing,
    ]);
    final mine = ScoreRow(
      text: 'Bowler',
      frames: List.filled(10, ''),
      suggested: true,
      y: .4,
      height: .1,
    );
    expect(
      (await PhotoQuality.assess(bytes, lines, [mine], profile)).issues,
      isEmpty,
    );
    expect(
      (await PhotoQuality.assess(bytes, const [], const [], profile)).issues,
      [PhotoIssue.noText],
    );
  });
}
