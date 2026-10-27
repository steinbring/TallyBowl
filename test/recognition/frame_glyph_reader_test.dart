import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const game89 = ['X', '8-', '53', '36', '6-', '8-', '11', '71', 'X', '33'];
const game109 = ['81', '9/', '9-', '63', '71', '7-', 'X', '7-', 'X', '7-'];
List<RecognizedLine> geometry(int score, String platform) => (jsonDecode(
  File('test/fixtures/practice_${score}_$platform.json').readAsStringSync(),
) as List).map((v) => RecognizedLine.fromJson(v as Map)).toList();
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final score in [89, 109]) {
    for (final platform in ['apple', 'android']) {
      test(
        'reads every delivery in game $score with $platform geometry',
        () async {
          final rows = await FrameGlyphReader.read(
            await File('test/fixtures/practice_$score.png').readAsBytes(),
            geometry(score, platform),
            const BowlerProfile(name: 'Bowler'),
          );
          final row = ScoreSheetParser.automaticRow(
            ScoreSheetParser.rows([
              ...geometry(score, platform),
              ...rows,
            ], const BowlerProfile(name: 'Bowler')),
          );
          expect(row, isNotNull);
          expect(row!.frames, score == 89 ? game89 : game109);
          expect(row.displayedTotal, score);
        },
      );
    }
  }
  test('wrong displayed total cannot validate observed glyphs', () async {
    final lines = geometry(89, 'android')
        .map(
          (l) => l.text == '89' && l.x > .9
              ? RecognizedLine(
                  text: '90',
                  x: l.x,
                  y: l.y,
                  width: l.width,
                  height: l.height,
                )
              : l,
        )
        .toList();
    expect(
      await FrameGlyphReader.read(
        await File('test/fixtures/practice_89.png').readAsBytes(),
        lines,
        const BowlerProfile(name: 'Bowler'),
      ),
      isEmpty,
    );
  });
  test('unknown name does not acquire a grid', () async {
    expect(
      await FrameGlyphReader.read(
        await File('test/fixtures/practice_89.png').readAsBytes(),
        geometry(89, 'android'),
        const BowlerProfile(name: 'Someone else'),
      ),
      isEmpty,
    );
  });
  test(
    'conflicting known strikes cannot be overwritten by templates',
    () async {
      RecognizedLine conflict(RecognizedLine l) => RecognizedLine(
        text: l.text == 'X' ? 'F' : l.text,
        x: l.x,
        y: l.y,
        width: l.width,
        height: l.height,
        elements: l.elements.map(conflict).toList(),
      );
      expect(
        await FrameGlyphReader.read(
          await File('test/fixtures/practice_89.png').readAsBytes(),
          geometry(89, 'android').map(conflict).toList(),
          const BowlerProfile(name: 'Bowler'),
        ),
        isEmpty,
      );
    },
  );
  test('matching final total cannot hide a wrong native checkpoint', () async {
    RecognizedLine conflict(RecognizedLine l) => RecognizedLine(
      text: l.text == '34' ? '35' : l.text,
      x: l.x,
      y: l.y,
      width: l.width,
      height: l.height,
      elements: l.elements.map(conflict).toList(),
    );
    expect(
      await FrameGlyphReader.read(
        await File('test/fixtures/practice_89.png').readAsBytes(),
        geometry(89, 'android').map(conflict).toList(),
        const BowlerProfile(name: 'Bowler'),
      ),
      isEmpty,
    );
  });
  test(
    'blank delivery ink is not reconstructed from cumulative numbers',
    () async {
      final codec = await ui.instantiateImageCodec(
        await File('test/fixtures/practice_89.png').readAsBytes(),
      );
      final image = (await codec.getNextFrame()).image;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawImage(image, ui.Offset.zero, ui.Paint());
      canvas.drawRect(
        const ui.Rect.fromLTWH(270, 120, 210, 170),
        ui.Paint()..color = const ui.Color(0xFF0A1428),
      );
      final picture = recorder.endRecording();
      final blank = await picture.toImage(image.width, image.height);
      RecognizedLine withoutFirstStrike(RecognizedLine l) => RecognizedLine(
        text: l.centerX < .3 ? l.text.replaceAll('X', '') : l.text,
        x: l.x,
        y: l.y,
        width: l.width,
        height: l.height,
        elements: l.elements.map(withoutFirstStrike).toList(),
      );
      final png = (await blank.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      expect(
        await FrameGlyphReader.read(
          png,
          geometry(89, 'android').map(withoutFirstStrike).toList(),
          const BowlerProfile(name: 'Bowler'),
        ),
        isEmpty,
      );
      blank.dispose();
      picture.dispose();
      image.dispose();
      codec.dispose();
    },
  );
}
