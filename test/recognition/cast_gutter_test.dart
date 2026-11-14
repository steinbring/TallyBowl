import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const profile = BowlerProfile(name: 'Bowler');
const openFrames = ['-1', '1-', '--', '81', '8-', '-8', '1-', '-1', '81', '3-'];
const openChecks = [1, 2, 2, 11, 19, 27, 28, 29, 38, 41];
const spareFrames = ['-/', 'X', '9-', '18', '9/', '9-', '63', '-7', '61', '7-'];
const spareChecks = [20, 39, 48, 57, 76, 85, 94, 101, 108, 115];

RecognizedLine box(String text, double x, double y, double w, double h) =>
    RecognizedLine(text: text, x: x, y: y, width: w, height: h);

List<RecognizedLine> observations(List<int> checks, {bool spare = false}) => [
  box('Bowler', .01, .31, .09, .06),
  for (var i = 0; i < 10; i++) ...[
    box('${i + 1}', .14 + i * .075, .2, .02, .02),
    box('${checks[i]}', .135 + i * .075, .41, .03, .06),
  ],
  for (final i in spare ? [3, 6, 8] : [3, 8])
    box((spare ? spareFrames : openFrames)[i], .12 + i * .075, .31, .05, .06),
  if (!spare) box('3', .12 + 9 * .075, .31, .02, .06),
  box('${checks.last}', .92, .41, .05, .06),
];

// Anonymous raster with tinted delivery ink and thin decorative outlines.
// Neither photographed pixels nor native OCR responses are used here.
Future<Uint8List> board(
  List<String> frames, {
  bool missingGutter = false,
  String? totalInk,
}) async {
  final bank = jsonDecode(
    File('assets/recognition/glyphs.json').readAsStringSync(),
  ) as Map;
  final variants = (bank['variants'] as List).cast<Map>();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFF202535), ui.BlendMode.src);
  final ink = ui.Paint()..color = const ui.Color(0xFFC3CDFF);
  final decoration = ui.Paint()
    ..color = const ui.Color(0xFFBE9DD8)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;
  for (var i = 0; i < 10; i++) {
    final left = (.12 + i * .075) * 1000;
    const top = .31 * 600;
    canvas.drawPath(
      ui.Path()
        ..moveTo(left + 17, top + 6)
        ..lineTo(left + 3, top + 25)
        ..lineTo(left + 17, top + 44),
      decoration,
    );
    for (var roll = 0; roll < frames[i].length; roll++) {
      final mark = frames[i][roll];
      final x = left + roll * 30;
      if (mark == '-') {
        if (missingGutter && i == 0 && roll == 0) continue;
        canvas.drawRect(ui.Rect.fromLTWH(x + 3, top + 21, 12, 8), ink);
        continue;
      }
      final glyph =
          variants.lastWhere((v) => v['text'] == mark)['mask'] as String;
      for (var y = 0; y < 32; y++) {
        for (var xx = 0; xx < 24; xx++) {
          if (glyph[y * 24 + xx] == '1') {
            canvas.drawRect(
              ui.Rect.fromLTWH(x + xx * .8, top + y * 1.5, .8, 1.5),
              ink,
            );
          }
        }
      }
    }
  }
  if (totalInk != null) {
    for (var i = 0; i < totalInk.length; i++) {
      final glyph =
          variants.lastWhere((v) => v['text'] == totalInk[i])['mask'] as String;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 24; x++) {
          if (glyph[y * 24 + x] == '1') {
            canvas.drawRect(
              ui.Rect.fromLTWH(
                920 + i * 22 + x * .65,
                246 + y.toDouble(),
                .65,
                1,
              ),
              ink,
            );
          }
        }
      }
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(1000, 600);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<ScoreRow?> read(Uint8List bytes, List<RecognizedLine> lines) async {
  final recovered = await FrameGlyphReader.read(
    bytes,
    lines,
    profile,
    recovery: true,
    deskew: true,
  );
  return ScoreSheetParser.automaticRow(
    ScoreSheetParser.rows([...lines, ...recovered], profile),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'tinted gutters retain leading, trailing and double-miss order',
    () async {
      final row = await read(await board(openFrames), observations(openChecks));
      expect(row?.frames, openFrames);
      expect(row?.displayedTotal, 41);
    },
  );
  test(
    'a tinted first-ball gutter and spare remain two observed rolls',
    () async {
      final row = await read(
        await board(spareFrames),
        observations(spareChecks, spare: true),
      );
      expect(row?.frames, spareFrames);
      expect(row?.displayedTotal, 115);
    },
  );
  test('matching checkpoints cannot supply an absent gutter mark', () async {
    expect(
      await read(
        await board(openFrames, missingGutter: true),
        observations(openChecks),
      ),
      isNull,
    );
  });
  test(
    'color separation cannot override a conflicting scratch total',
    () async {
      final lines = observations(openChecks)..removeLast();
      lines.add(box('42', .92, .41, .05, .06));
      expect(await read(await board(openFrames), lines), isNull);
    },
  );
  test('color separation cannot replace a legal primary delivery', () async {
    final lines = observations(openChecks);
    lines[lines.indexWhere((w) => w.text == '81')] = box(
      '71',
      .12 + 3 * .075,
      .31,
      .05,
      .06,
    );
    expect(await read(await board(openFrames), lines), isNull);
  });
  test(
    'a repeated total fragment needs independent full-number pixels',
    () async {
      final lines = observations(openChecks)
        ..add(box('Tot.', .92, .2, .05, .02))
        ..add(box('1', .92, .41, .05, .06));
      final row = await read(await board(openFrames, totalInk: '41'), lines);
      expect(row?.frames, openFrames);
      expect(row?.displayedTotal, 41);
      expect(
        await read(await board(openFrames, totalInk: '11'), lines),
        isNull,
      );
    },
  );
  test(
    'two full total readings remain ambiguous despite matching pixels',
    () async {
      final lines = observations(openChecks)
        ..add(box('Tot.', .92, .2, .05, .02))
        ..add(box('51', .92, .41, .05, .06));
      expect(
        await read(await board(openFrames, totalInk: '41'), lines),
        isNull,
      );
    },
  );
  test(
    'photo service recovers tinted gutters within four native calls',
    () async {
      final directory = await Directory.systemTemp.createTemp('cast-gutters-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/anonymous.png');
      await file.writeAsBytes(await board(openFrames));
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, (call) async {
            calls++;
            final args = call.arguments as Map;
            if (args['regions'] != null && args['context'] != true) return [];
            return [
              for (final word in observations(openChecks))
                {
                  'text': word.text,
                  'x': word.x,
                  'y': word.y,
                  'width': word.width,
                  'height': word.height,
                },
            ];
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PhotoService.channel, null),
      );
      final lines = await PhotoService.recognize(file.path, profile: profile);
      final row = ScoreSheetParser.automaticRow(
        ScoreSheetParser.rows(lines, profile),
      );
      expect(row?.frames, openFrames);
      expect(row?.displayedTotal, 41);
      expect(calls, lessThanOrEqualTo(4));
    },
  );
}
