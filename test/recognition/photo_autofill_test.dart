import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

import 'scoreboard_grid_test.dart' show practiceFrames, checkpoints;

List<dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as List;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profile = BowlerProfile(name: 'Bowler');
  for (final apple in [false, true]) {
    test(
      '${apple ? 'Apple' : 'Android'} geometry fills deliveries without using totals to invent marks',
      () async {
        final source = File('test/goldens/recap.png');
        final calls = <Map>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PhotoService.channel, (call) async {
              final args = call.arguments as Map;
              calls.add(args);
              if (args['regions'] != null) {
                return fixture(apple ? 'apple_cells' : 'monitor_cells');
              }
              if (args['aspect'] == 1.5) return fixture('apple_context');
              if (args['aspect'] == 2) {
                return fixture(apple ? 'apple_corrected' : 'monitor_geometry');
              }
              return fixture(apple ? 'apple_initial' : 'monitor_geometry');
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(PhotoService.channel, null),
        );
        final lines = await PhotoService.recognize(
          source.path,
          profile: profile,
        );
        final rows = ScoreSheetParser.rows(lines, profile);
        final row = rows.where((r) => r.cumulativeTotals != null).single;
        expect(row.frames, practiceFrames);
        expect(row.cumulativeTotals, checkpoints);
        expect(ScoreSheetParser.automaticRow(rows), same(row));
        expect(
          calls.where((c) => c['regions'] != null).single['regions'],
          hasLength(apple ? 7 : 2),
        );
      },
    );
  }
  test('disagreeing crop cannot replace a known nine with a six', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PhotoService.channel, (call) async {
          final args = call.arguments as Map;
          if (args['regions'] != null) {
            return fixture('monitor_cells')
                .where((v) => v['stroke'] != true)
                .toList();
          }
          return fixture('monitor_geometry');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, null),
    );
    final lines = await PhotoService.recognize(
      'test/goldens/recap.png',
      profile: profile,
    );
    final rows = ScoreSheetParser.rows(lines, profile);
    expect(rows.first.frames[9], 'X9');
    expect(ScoreSheetParser.automaticRow(rows), isNull);
  });
  test('failed regional reading preserves original marks for review', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PhotoService.channel, (call) async {
          if ((call.arguments as Map)['regions'] != null) {
            throw PlatformException(code: 'recognition');
          }
          return fixture('monitor_geometry');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, null),
    );
    final lines = await PhotoService.recognize(
      'test/goldens/recap.png',
      profile: profile,
    );
    final row = ScoreSheetParser.rows(lines, profile).first;
    final expected = [...practiceFrames];
    expected[2] = '9';
    expected[9] = 'X9';
    expect(row.frames, expected);
    expect(row.canAutoSelect, isFalse);
  });
}
