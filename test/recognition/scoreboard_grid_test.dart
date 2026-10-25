import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/domain/scoring.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

const practiceFrames = [
  '53',
  '63',
  '9-',
  '7/',
  '16',
  '7-',
  '35',
  '6-',
  '42',
  'X9-',
];
const checkpoints = [8, 17, 26, 37, 44, 51, 59, 65, 71, 90];
RecognizedLine word(
  String text,
  double x,
  double y,
  double width,
  double height,
) => RecognizedLine(text: text, x: x, y: y, width: width, height: height);
List<RecognizedLine> board({
  String name = 'JOE',
  double y = 0,
  int? missingFrame,
  bool symbols = true,
  List<int> totals = checkpoints,
}) => [
  word(name, .03, .295 + y, .12, .10),
  word('Player JOE', .03, .46 + y, .15, .04),
  for (var i = 0; i < 10; i++) ...[
    word('${i + 1}', .25 + i * .06, .25 + y, .015, .02),
    word(
      '${totals[i]}',
      .26 + i * .06 - (totals[i] < 10 ? .01 : .022),
      .36 + y,
      totals[i] < 10 ? .01 : .022,
      .04,
    ),
    if (i != missingFrame)
      RecognizedLine(
        text: practiceFrames[i],
        x: .205 + i * .06,
        y: .30 + y,
        width: .05,
        height: .045,
        elements: symbols
            ? [
                for (var c = 0; c < practiceFrames[i].length; c++)
                  word(
                    practiceFrames[i][c],
                    .205 + i * .06 + c * .018,
                    .30 + y,
                    .012,
                    .045,
                  ),
              ]
            : [],
      ),
  ],
  word('90', .84, .31 + y, .04, .09),
];
void main() {
  const profile = BowlerProfile(name: 'Joe', aliases: ['JWS']);
  for (final symbols in [true, false]) {
    test(
      'reads separate mark/cumulative bands with ${symbols ? 'symbol' : 'word'} geometry',
      () {
        final rows = ScoreSheetParser.rows(board(symbols: symbols), profile);
        final row = rows.where((r) => r.suggested && r.extracted).single;
        expect(row.frames, practiceFrames);
        expect(row.cumulativeTotals, checkpoints);
        expect(row.displayedTotal, 90);
        expect(row.hasScoreConflict, isFalse);
        expect(row.canAutoSelect, isTrue);
        expect(TenPinScorer.score(row.frames).total, 90);
      },
    );
  }
  test('missing deliveries are never reconstructed from cumulative scores', () {
    final rows = ScoreSheetParser.rows(board(missingFrame: 1), profile);
    expect(rows.any((r) => r.canAutoSelect), isFalse);
    final row = rows.where((r) => r.cumulativeTotals != null).first;
    expect(row.frames[1], isEmpty);
    expect(row.frames[0], '53');
  });
  test('two bowlers retain separate marks and name matches', () {
    final rows = ScoreSheetParser.rows([
      ...board(name: 'OTHER'),
      ...board(name: 'JWS', y: .32),
    ], profile);
    final extracted = rows.where((r) => r.extracted).toList();
    expect(extracted.length, 2);
    expect(extracted.where((r) => r.suggested).single.text, startsWith('JWS'));
    expect(
      extracted.where((r) => !r.suggested).single.text,
      startsWith('OTHER'),
    );
  });
  test('a conflicting intermediate checkpoint blocks automatic selection', () {
    final totals = [...checkpoints]..[4] = 45;
    final row = ScoreSheetParser.rows(
      board(totals: totals),
      profile,
    ).where((r) => r.extracted).single;
    expect(row.frames, practiceFrames);
    expect(row.hasScoreConflict, isTrue);
    expect(row.canAutoSelect, isFalse);
  });
  test('cumulative scores without delivery marks never become frame marks', () {
    final lines = board()..removeWhere((l) => l.y == .30);
    expect(
      ScoreSheetParser.rows(lines, profile).any((r) => r.extracted),
      isFalse,
    );
  });
  test('two complete alias matches require choosing a row', () {
    final rows = ScoreSheetParser.rows([
      ...board(),
      ...board(name: 'JWS', y: .32),
    ], profile);
    expect(rows.where((r) => r.canAutoSelect), hasLength(2));
    expect(ScoreSheetParser.automaticRow(rows), isNull);
  });
  test('draft checkpoint validation rejects malformed backup values', () {
    final session = BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026),
    );
    for (final invalid in [
      <int>[90],
      [...checkpoints]..[2] = -1,
      [...checkpoints]..[2] = 301,
      '90',
    ]) {
      expect(
        () => BowlData(
          alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
          sessions: [session],
          draft: {
            'sessionId': 's',
            'frames': practiceFrames,
            'sourceCumulative': invalid,
          },
        ).validate(),
        throwsFormatException,
      );
    }
  });
  test('a second incomplete name match also blocks automatic selection', () {
    final rows = ScoreSheetParser.rows([
      ...board(),
      ...board(name: 'JWS', y: .32, missingFrame: 1),
    ], profile);
    expect(ScoreSheetParser.automaticRow(rows), isNull);
  });
}
