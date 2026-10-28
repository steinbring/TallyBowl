import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';
import 'package:tallybowl/src/recognition/scoreboard_grid.dart';

const league80 = ['-7', '-9', '-8', '8/', '--', '72', '17', '72', '7-', '8/3'];
const league104 = ['8-', '31', '9/', '1/', '18', '44', '54', '9/', '8/', '72'];
const leagueFixtures = [
  'league_80_soft',
  'league_104',
  'league_80_angled',
  'league_80_front',
];

List<List<RecognizedLine>> leagueReadings(String name, String platform) {
  final data = jsonDecode(
    File('test/fixtures/${name}_$platform.json').readAsStringSync(),
  ) as Map;
  return [
    for (final source in data['readings'] as List)
      [for (final word in source as List) RecognizedLine.fromJson(word as Map)],
  ];
}

Future<List<RecognizedLine>> readLeague(
  String name,
  List<List<RecognizedLine>> readings, {
  BowlerProfile profile = const BowlerProfile(name: 'Bowler'),
}) async => FrameGlyphReader.read(
  await File('test/fixtures/$name.png').readAsBytes(),
  readings.first,
  profile,
  alternatives: readings.skip(1).toList(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in leagueFixtures) {
    for (final platform in ['apple', 'android']) {
      test(
        'fills ten exact frames from $name $platform observations',
        () async {
          final readings = leagueReadings(name, platform);
          final recovered = await readLeague(name, readings);
          final row = ScoreSheetParser.automaticRow(
            ScoreSheetParser.rows([
              ...readings.first,
              ...recovered,
            ], const BowlerProfile(name: 'Bowler')),
          );
          expect(row, isNotNull);
          expect(row!.frames, name == 'league_104' ? league104 : league80);
          expect(row.displayedTotal, name == 'league_104' ? 104 : 80);
          expect(
            recovered,
            hasLength(1),
            reason: 'Repeated OCR passes identify the same row.',
          );
        },
      );
    }
  }
  test(
    'handicap score cannot substitute for a conflicting scratch total',
    () async {
      final readings = leagueReadings('league_80_front', 'apple');
      final changed = [
        for (final source in readings)
          [
            for (final w in source)
              if (w.text == '80' && w.x > .82)
                RecognizedLine(
                  text: '81',
                  x: w.x,
                  y: w.y,
                  width: w.width,
                  height: w.height,
                )
              else
                w,
          ],
      ];
      expect(await readLeague('league_80_front', changed), isEmpty);
    },
  );
  test(
    'two total columns without an identified handicap label require review',
    () async {
      final readings = leagueReadings('league_104', 'apple');
      final changed = [
        for (final source in readings)
          source
              .where(
                (w) => !RegExp(
                  'h[da][ce]p',
                  caseSensitive: false,
                ).hasMatch(w.text),
              )
              .toList(),
      ];
      expect(await readLeague('league_104', changed), isEmpty);
    },
  );
  test(
    'sloped cumulative checkpoints still reject a conflicting frame',
    () async {
      final readings = leagueReadings('league_80_angled', 'apple');
      final changed = [
        for (final source in readings)
          [
            for (final w in source)
              if (w.text == '34')
                RecognizedLine(
                  text: '35',
                  x: w.x,
                  y: w.y,
                  width: w.width,
                  height: w.height,
                )
              else
                w,
          ],
      ];
      expect(await readLeague('league_80_angled', changed), isEmpty);
    },
  );
  test('a different bowler cannot acquire the completed owner row', () async {
    expect(
      await readLeague(
        'league_104',
        leagueReadings('league_104', 'apple'),
        profile: const BowlerProfile(name: 'Someone else'),
      ),
      isEmpty,
    );
  });
  for (final mismatch in [false, true]) {
    test(
      'cross-pass total needs ${mismatch ? 'the same bowler' : 'six checkpoints'}',
      () async {
        final readings = leagueReadings('league_80_soft', 'android');
        final original = readings.first.expand(ScoreboardGrid.words).toList();
        final name = original.firstWhere((w) => w.text == 'Bowler');
        final donor = readings[1]
            .expand(ScoreboardGrid.words)
            .where((w) => w.text == 'Bowler' || w.x > .82)
            .map(
              (w) => w.text == 'Bowler' && mismatch
                  ? RecognizedLine(
                      text: 'Guest',
                      x: w.x,
                      y: w.y,
                      width: w.width,
                      height: w.height,
                    )
                  : w,
            )
            .toList();
        final sparse = original
            .where(
              (w) =>
                  mismatch ||
                  w.x > .82 ||
                  w.centerY < name.centerY - .05 ||
                  !RegExp(r'^\d+$').hasMatch(w.text) ||
                  w.text == '80',
            )
            .toList();
        RecognizedLine wrap(List<RecognizedLine> words) => RecognizedLine(
          text: 'Observations',
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          elements: words,
        );
        expect(
          await readLeague('league_80_soft', [
            [wrap(sparse)],
            [wrap(donor)],
          ]),
          isEmpty,
        );
      },
    );
  }
}
