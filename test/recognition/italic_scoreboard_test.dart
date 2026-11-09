import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const profile = BowlerProfile(name: 'Bowler');

RecognizedLine box(
  String text,
  double x,
  double y,
  double width,
  double height,
) => RecognizedLine(text: text, x: x, y: y, width: width, height: height);

List<RecognizedLine> observations({bool wrongTotal = false}) => [
  box('Bowler', .01, .31, .09, .06),
  for (var i = 0; i < 10; i++) ...[
    box('${i + 1}', .14 + i * .075, .2, .02, .02),
    box('${(i + 1) * 9}', .135 + i * .075, .41, .03, .06),
    if ([0, 4, 8].contains(i)) box('81', .12 + i * .075, .31, .05, .06),
  ],
  box(wrongTotal ? '91' : '90', .92, .41, .05, .06),
];

// Synthetic, anonymous image. Both stroke directions use the shipped font bank;
// no photographed name, image bytes or native OCR response is committed.
Future<Uint8List> italicBoard(double lean, {bool missingRoll = false}) async {
  final bank = jsonDecode(
    File('assets/recognition/glyphs.json').readAsStringSync(),
  ) as Map;
  final variants = (bank['variants'] as List).cast<Map>();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFF152030), ui.BlendMode.src);
  for (var frame = 0; frame < 10; frame++) {
    for (var roll = 0; roll < 2; roll++) {
      if (missingRoll && frame == 5 && roll == 1) continue;
      final glyph =
          variants.lastWhere(
                (v) => v['text'] == (roll == 0 ? '8' : '1'),
              )['mask']
              as String;
      canvas.save();
      canvas.translate((.12 + frame * .075) * 1000 + roll * 30, .31 * 600);
      canvas.skew(lean, 0);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 24; x++) {
          if (glyph[y * 24 + x] == '1') {
            canvas.drawRect(
              ui.Rect.fromLTWH(x * .65, y * 1.5, .65, 1.5),
              ui.Paint()..color = const ui.Color(0xFFFFFFFF),
            );
          }
        }
      }
      canvas.restore();
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

Future<ScoreRow?> recognize(
  Uint8List bytes,
  List<RecognizedLine> lines, {
  List<RecognizedLine> supplemental = const [],
}) async {
  final recovered = await FrameGlyphReader.read(
    bytes,
    lines,
    profile,
    supplemental: supplemental,
    recovery: true,
    deskew: true,
  );
  return ScoreSheetParser.automaticRow(
    ScoreSheetParser.rows([...lines, ...recovered], profile),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final lean in [-.2, -.1, .1, .2]) {
    test('italic $lean preserves exact observed deliveries', () async {
      final row = await recognize(await italicBoard(lean), observations());
      expect(row?.frames, List.filled(10, '81'));
      expect(row?.displayedTotal, 90);
    });
    test('italic $lean cannot fill a roll from the checkpoints', () async {
      expect(
        await recognize(
          await italicBoard(lean, missingRoll: true),
          observations(),
        ),
        isNull,
      );
    });
    test('italic $lean cannot fit a conflicting total', () async {
      expect(
        await recognize(
          await italicBoard(lean),
          observations(wrongTotal: true),
        ),
        isNull,
      );
    });
  }
  test('a secondary crop cannot replace the primary observation', () async {
    final lines = observations();
    // The primary word is 81; a crop misreads that same 1 as 6.
    final supplemental = [box('6', .15, .31, .02, .06)];
    final row = await recognize(
      await italicBoard(-.2),
      lines,
      supplemental: supplemental,
    );
    expect(row?.frames, List.filled(10, '81'));
    expect(row?.displayedTotal, 90);
  });
  test(
    'two compact headers support recovery beside inflated OCR boxes',
    () async {
      final lines = observations().where((w) => w.y != .2).toList();
      lines.addAll([
        for (final i in [0, 1, 3, 5, 7, 9])
          box(
            '${i + 1}',
            .14 + i * .075,
            i < 2 ? .2 : .175,
            .02,
            i < 2 ? .02 : .07,
          ),
      ]);
      final row = await recognize(await italicBoard(-.2), lines);
      expect(row?.frames, List.filled(10, '81'));
      expect(row?.displayedTotal, 90);
    },
  );
  test('one tiny header cannot establish a smaller header height', () async {
    final lines = observations().where((w) => w.y != .2).toList();
    lines.addAll([
      for (final i in [0, 1, 3, 5, 7, 9])
        box(
          '${i + 1}',
          .14 + i * .075,
          i == 0 ? .2 : .175,
          .02,
          i == 0 ? .02 : .07,
        ),
    ]);
    expect(await recognize(await italicBoard(-.2), lines), isNull);
  });
  test(
    'duplicate header symbols are not two independent small headers',
    () async {
      final lines = observations().where((w) => w.y != .2).toList();
      lines.addAll([
        RecognizedLine(
          text: '1',
          x: .14,
          y: .2,
          width: .02,
          height: .02,
          elements: [box('1', .14, .2, .02, .02)],
        ),
        for (final i in [1, 3, 5, 7, 9])
          box('${i + 1}', .14 + i * .075, .175, .02, .07),
      ]);
      expect(await recognize(await italicBoard(-.2), lines), isNull);
    },
  );
  test(
    'a legal primary frame cannot be replaced to match checkpoints',
    () async {
      final lines = observations();
      final primary = lines.indexWhere((w) => w.text == '81');
      lines[primary] = box('71', .12, .31, .05, .06);
      expect(await recognize(await italicBoard(-.2), lines), isNull);
    },
  );
  test(
    'photo service reaches italic recovery within four native calls',
    () async {
      final temporary = await Directory.systemTemp.createTemp('italic-photo-');
      addTearDown(() => temporary.delete(recursive: true));
      final file = File('${temporary.path}/anonymous.png');
      await file.writeAsBytes(await italicBoard(-.2));
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, (call) async {
            calls++;
            final args = call.arguments as Map;
            if (args['regions'] != null && args['context'] != true) return [];
            return [
              for (final word in observations())
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
      expect(row?.frames, List.filled(10, '81'));
      expect(row?.displayedTotal, 90);
      expect(calls, lessThanOrEqualTo(4));
    },
  );
  test('native name symbol fragments are not a different player', () async {
    final named = observations();
    final fragmented = [
      ...named.where((word) => word.text != 'Bowler'),
      for (var i = 0; i < 6; i++)
        box('Bowler'[i], .01 + i * .015, .31, .015, .06),
    ];
    final recovered = await FrameGlyphReader.read(
      await italicBoard(-.2),
      fragmented,
      profile,
      alternatives: [named],
      recovery: true,
      deskew: true,
    );
    final row = ScoreSheetParser.automaticRow(
      ScoreSheetParser.rows([...fragmented, ...recovered], profile),
    );
    expect(row?.frames, List.filled(10, '81'));
    expect(row?.displayedTotal, 90);
  });
}
