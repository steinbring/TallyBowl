import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/domain/scoring.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profile = BowlerProfile(name: 'Bowler');

  Future<ScoreRow?> recognize(
    int score,
    String engine, {
    bool wrongTotal = false,
    BowlerProfile bowler = profile,
  }) async {
    var data = File('test/fixtures/practice_oct31/score_${score}_$engine.json')
        .readAsStringSync();
    if (wrongTotal) {
      // Change every native observation of the total, including symbols.
      // The photographed delivery ink is unchanged and must not be adjusted
      // to fit this otherwise plausible score.
      data = data.replaceAll('"text":"$score"', '"text":"${score + 1}"');
    }
    final fixture = jsonDecode(data) as Map;
    final responses = fixture['responses'] as Map;
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PhotoService.channel, (call) async {
          calls++;
          final args = call.arguments as Map;
          final key = args['context'] == true
              ? 'focus${args['aspect'] ?? 1}'
              : args['regions'] == null
              ? 'a${args['aspect'] ?? 1}'
              : 'regional';
          return responses[key] ??
              (key == 'a1.5' ? responses['focus1.5'] : null) ??
              [];
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, null),
    );
    final lines = await PhotoService.recognize(
      'test/fixtures/practice_oct31/score_$score.png',
      profile: bowler,
    );
    expect(calls, lessThanOrEqualTo(4));
    return ScoreSheetParser.automaticRow(ScoreSheetParser.rows(lines, bowler));
  }

  for (final score in [116, 122, 74]) {
    for (final engine in ['apple', 'android']) {
      test('cartoon practice $score $engine reads all ten frames', () async {
        final fixture = jsonDecode(
          File('test/fixtures/practice_oct31/score_${score}_$engine.json')
              .readAsStringSync(),
        ) as Map;
        final frames = (fixture['frames'] as List).cast<String>();
        final cumulative = (fixture['cumulative'] as List).cast<int>();
        final computed = TenPinScorer.score(frames);
        expect(computed.complete, isTrue);
        expect(computed.cumulative, cumulative);
        final row = await recognize(score, engine);
        expect(row, isNotNull);
        expect(row!.frames, frames);
        expect(row.displayedTotal, score);
      });
    }
  }

  for (final engine in ['apple', 'android']) {
    test('cartoon $engine cannot fit deliveries to a wrong total', () async {
      expect(await recognize(116, engine, wrongTotal: true), isNull);
    });
    test('cartoon $engine does not import another bowler', () async {
      expect(
        await recognize(
          122,
          engine,
          bowler: const BowlerProfile(name: 'Someone else'),
        ),
        isNull,
      );
    });
  }
}
