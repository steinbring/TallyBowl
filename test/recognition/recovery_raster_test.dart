import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const profile = BowlerProfile(name: 'Bowler');
RecognizedLine box(
  String text,
  double x,
  double y, [
  double width = .03,
  double height = .06,
]) => RecognizedLine(text: text, x: x, y: y, width: width, height: height);
List<RecognizedLine> observations({bool wrongTotal = false}) => [
  box('Bowler', .01, .31, .09),
  for (var i = 0; i < 10; i++) ...[
    box('${i + 1}', .14 + i * .075, .2, .02, .02),
    box('${(i + 1) * 30}', .135 + i * .075, .41),
    if ([0, 4, 8].contains(i)) box('X', .12 + i * .075, .31),
  ],
  box(wrongTotal ? '299' : '300', .92, .41, .05),
  box('216', .92, .31, .05), // Another game total cannot validate this row.
];

Future<Uint8List> scoreboard({
  required bool dark,
  bool mixed = false,
  bool missingStrike = false,
}) async {
  final bank = jsonDecode(
    File('assets/recognition/glyphs.json').readAsStringSync(),
  ) as Map;
  final glyph =
      (bank['variants'] as List).firstWhere((v) => v['text'] == 'X')['mask']
          as String;
  const width = 1000, height = 600;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFF5080B0), ui.BlendMode.src);
  for (var i = 0; i < 10; i++) {
    final inverse = mixed ? i.isEven : dark;
    final paper = inverse
        ? const ui.Color(0xFFE8E8E8)
        : const ui.Color(0xFF152030);
    final ink = inverse
        ? const ui.Color(0xFF101010)
        : const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(
        (.15 + i * .075 - .57 * .075) * width,
        .285 * height,
        .075 * width,
        .13 * height,
      ),
      ui.Paint()..color = paper,
    );
    if (missingStrike && i == 5) continue;
    for (var roll = 0; roll < (i == 9 ? 3 : 1); roll++) {
      final x = (.12 + i * .075) * width + roll * 26;
      for (var y = 0; y < 32; y++) {
        for (var px = 0; px < 24; px++) {
          if (glyph[y * 24 + px] == '1') {
            canvas.drawRect(
              ui.Rect.fromLTWH(x + px, .31 * height + y, 1, 1),
              ui.Paint()..color = ink,
            );
          }
        }
      }
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final dark in [true, false]) {
    test(
      'recovery reads omitted strikes with ${dark ? 'dark' : 'light'} ink',
      () async {
        final rows = await FrameGlyphReader.read(
          await scoreboard(dark: dark),
          observations(),
          profile,
          recovery: true,
        );
        final selected = ScoreSheetParser.automaticRow(
          ScoreSheetParser.rows(rows, profile),
        );
        expect(selected?.frames, [...List.filled(9, 'X'), 'XXX']);
        expect(selected?.displayedTotal, 300);
      },
    );
  }
  test('alternating ink polarities remain one observed game', () async {
    final rows = await FrameGlyphReader.read(
      await scoreboard(dark: false, mixed: true),
      observations(),
      profile,
      recovery: true,
    );
    expect(
      ScoreSheetParser.automaticRow(ScoreSheetParser.rows(rows, profile))
          ?.displayedTotal,
      300,
    );
  });
  test('matching checkpoints cannot reconstruct a missing delivery', () async {
    expect(
      await FrameGlyphReader.read(
        await scoreboard(dark: true, missingStrike: true),
        observations(),
        profile,
        recovery: true,
      ),
      isEmpty,
    );
  });
  test('a conflicting independent total prevents recovery', () async {
    expect(
      await FrameGlyphReader.read(
        await scoreboard(dark: true),
        observations(wrongTotal: true),
        profile,
        recovery: true,
      ),
      isEmpty,
    );
  });
}
