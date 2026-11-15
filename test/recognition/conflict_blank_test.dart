import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/domain/scoring.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const profile = BowlerProfile(name: 'Bowler');

/// Frame 1 is a spare, so reading its first ball as 3 instead of 8 keeps every
/// cumulative checkpoint and the total: only the pixels can tell them apart.
const frames = ['8/', '72', '9-', '81', 'X', '9/', '7-', '63', '8-', '81'];

RecognizedLine box(String text, double x, double y, double w, double h) =>
    RecognizedLine(text: text, x: x, y: y, width: w, height: h);

/// The delivery word an engine would report for [frame] at column [i].
RecognizedLine marks(String frame, int i) =>
    box(frame, .12 + i * .075, .235, frame.length == 1 ? .02 : .05, .065);

/// Name, ten headers, ten checkpoints and the total: no delivery marks.
List<RecognizedLine> layout() {
  final checks = TenPinScorer.score(frames).cumulative;
  return [
    box('Bowler', .01, .28, .09, .12),
    for (var i = 0; i < 10; i++) ...[
      box('${i + 1}', .14 + i * .075, .2, .02, .02),
      box('${checks[i]}', .135 + i * .075, .34, .03, .06),
    ],
    box('${checks.last}', .9, .34, .04, .06),
  ];
}

/// An anonymous white-on-dark score row drawn from the bundled templates.
Future<Uint8List> board(List<String> ink) async {
  final bank = jsonDecode(
    File('assets/recognition/glyphs.json').readAsStringSync(),
  ) as Map;
  final variants = (bank['variants'] as List).cast<Map>();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFF101418), ui.BlendMode.src);
  final white = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  for (var i = 0; i < 10; i++) {
    final left = (.12 + i * .075) * 1000;
    const top = 141.0;
    for (var roll = 0; roll < ink[i].length; roll++) {
      final mark = ink[i][roll];
      final x = left + roll * 30;
      if (mark == '-') {
        canvas.drawRect(ui.Rect.fromLTWH(x + 3, top + 15, 12, 8), white);
        continue;
      }
      if (mark == '#') {
        // Digit-sized ink that matches no template.
        canvas.drawRect(ui.Rect.fromLTWH(x, top, 19, 38), white);
        continue;
      }
      final glyph =
          variants.lastWhere((v) => v['text'] == mark)['mask'] as String;
      for (var y = 0; y < 32; y++) {
        for (var xx = 0; xx < 24; xx++) {
          if (glyph[y * 24 + xx] == '1') {
            canvas.drawRect(
              ui.Rect.fromLTWH(x + xx * .8, top + y * 1.2, .8, 1.2),
              white,
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

Future<List<ScoreRow>> read(
  Uint8List bytes,
  List<RecognizedLine> lines, {
  List<RecognizedLine> supplemental = const [],
  bool recovery = false,
}) async => [
  for (final line in await FrameGlyphReader.read(
    bytes,
    lines,
    profile,
    supplemental: supplemental,
    recovery: recovery,
  ))
    if (line.frameRow != null) line.frameRow!,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the synthetic row reads exactly from pixels alone', () async {
    final rows = await read(await board(frames), layout());
    expect(rows.single.frames, frames);
    expect(rows.single.displayedTotal, 114);
  });

  test('agreeing native marks leave the pixel reading unchanged', () async {
    final rows = await read(await board(frames), [...layout(), marks('8/', 0)]);
    expect(rows.single.frames, frames);
  });

  group('recovery (band) pass', () {
    // The band fit needs three observed delivery words; these agree with ink.
    List<RecognizedLine> agreeing() => [
      ...layout(),
      for (final i in [1, 2, 3]) marks(frames[i], i),
    ];

    test('reads the row when native marks agree', () async {
      final rows = await read(await board(frames), agreeing(), recovery: true);
      expect(rows.single.frames, frames);
    });

    test(
      'F09-2: native cannot win over a complete, different pixel reading',
      () async {
        final rows = await read(await board(frames), [
          ...agreeing(),
          marks('3/', 0),
        ], recovery: true);
        expect(rows, isEmpty);
      },
    );

    test(
      'F09-3: a cell-crop character is never written as a delivery',
      () async {
        // '#' is ink no template can read. A secondary per-cell OCR crop says 3
        // there; it must not become the delivery, even though 3/ fits the row.
        final unreadable = ['#/', ...frames.skip(1)];
        final crop = [box('3', .12, .235, .02, .065)];
        expect(
          await read(
            await board(unreadable),
            agreeing(),
            supplemental: crop,
            recovery: true,
          ),
          isEmpty,
        );
        // The same character observed by this pass itself is primary and fills
        // ink the templates cannot read, as documented.
        final rows = await read(await board(unreadable), [
          ...agreeing(),
          ...crop,
        ], recovery: true);
        expect(rows.single.frames, ['3/', ...frames.skip(1)]);
      },
    );

    test(
      'a cell-crop character can still blank a glyph it contradicts',
      () async {
        final rows = await read(
          await board(frames),
          agreeing(),
          supplemental: [box('3', .12, .235, .02, .065)],
          recovery: true,
        );
        expect(rows, isEmpty);
      },
    );
  });

  test(
    'F09-1: a complete native frame cannot replace a conflict-blanked cell',
    () async {
      // Pixels show 8/ while the same pass's OCR says 3/. Both score 17 in
      // frame 1, so the checkpoints and total cannot expose the difference.
      final rows = await read(await board(frames), [
        ...layout(),
        marks('3/', 0),
      ]);
      expect(rows, isEmpty);
    },
  );
}
