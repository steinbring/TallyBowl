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
  for (var number = 1; number <= 12; number++) {
    final name = 'case_${number.toString().padLeft(2, '0')}';
    for (final platform in ['apple', 'android']) {
      final fixture = jsonDecode(
        File('test/fixtures/corpus12/${name}_$platform.json')
            .readAsStringSync(),
      ) as Map;
      test(
        'permissioned photo corpus $name $platform fills only supported deliveries',
        () async {
          final frames = (fixture['frames'] as List).cast<String>();
          final cumulative = (fixture['cumulative'] as List).cast<int>();
          // Independently transcribed visible deliveries agree with the board's
          // resolved checkpoints, including spares awaiting a future bonus roll.
          final score = TenPinScorer.score([
            ...frames,
            ...List.filled(10 - frames.length, ''),
          ]);
          expect(score.cumulative.take(cumulative.length), cumulative);
          expect(score.complete, fixture['complete']);
          var calls = 0;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(PhotoService.channel, (call) async {
                calls++;
                final args = call.arguments as Map;
                final key = args['regions'] == null || args['context'] == true
                    ? 'a${args['aspect'] ?? 1}'
                    : 'regional';
                return (fixture['responses'] as Map)[key] ?? [];
              });
          addTearDown(
            () => TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .setMockMethodCallHandler(PhotoService.channel, null),
          );
          final lines = await PhotoService.recognize(
            'test/fixtures/corpus12/$name.png',
            profile: profile,
          );
          final row = ScoreSheetParser.automaticRow(
            ScoreSheetParser.rows(lines, profile),
          );
          if (fixture['complete'] == false ||
              (platform == 'apple' ? [12] : [4]).contains(number)) {
            expect(
              row,
              isNull,
              reason: 'Unplayed or unsupported rolls require review.',
            );
          } else {
            expect(row, isNotNull);
            expect(row!.frames, frames);
            expect(row.displayedTotal, cumulative.last);
          }
          expect(calls, lessThanOrEqualTo(4));
        },
      );
    }
  }
}
