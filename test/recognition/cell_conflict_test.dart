import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';
import 'package:tallybowl/src/recognition/scoreboard_grid.dart';

const frames = ['53', '63', '9-', '7/', '16', '7-', '35', '6-', '42', 'X9-'];
const totals = [8, 17, 26, 37, 44, 51, 59, 65, 71, 90];
const profile = BowlerProfile(name: 'Joe');

RecognizedLine word(String text, double x, double y, double w, double h) =>
    RecognizedLine(text: text, x: x, y: y, width: w, height: h);

/// One grid row. [first] replaces the symbols observed in frame 1's cell.
List<RecognizedLine> board(List<RecognizedLine> first) => [
  word('JOE', .03, .295, .12, .10),
  for (var i = 0; i < 10; i++) ...[
    word('${i + 1}', .25 + i * .06, .25, .015, .02),
    word(
      '${totals[i]}',
      .26 + i * .06 - (totals[i] < 10 ? .01 : .022),
      .36,
      totals[i] < 10 ? .01 : .022,
      .04,
    ),
    if (i == 0)
      ...first
    else
      for (var c = 0; c < frames[i].length; c++)
        word(frames[i][c], .205 + i * .06 + c * .018, .30, .012, .045),
  ],
  word('90', .84, .31, .04, .09),
];

RecognizedLine mark(String text, double x) => word(text, x, .30, .012, .045);

void main() {
  test('separate deliveries side by side still form a frame', () {
    final rows = ScoreboardGrid.rows(
      board([mark('5', .205), mark('3', .223)]),
      profile,
    );
    expect(rows.single.frames, frames);
    expect(ScoreSheetParser.automaticRow(rows), isNotNull);
  });

  test('F08-1: two different readings of one glyph are a conflict', () {
    // The engine reported the first ball twice, as 5 and as 3, in nearly the
    // same box, and missed the second ball. Joined they spell the true 53.
    final rows = ScoreboardGrid.rows(
      board([mark('5', .205), mark('3', .2052)]),
      profile,
    );
    expect(rows.single.frames.first, isEmpty);
    expect(ScoreSheetParser.automaticRow(rows), isNull);
  });

  test('the same ink reported twice counts once', () {
    // ML Kit can return one word in two overlapping blocks.
    final rows = ScoreboardGrid.rows(
      board([
        mark('5', .205),
        mark('5', .2052),
        mark('3', .223),
        mark('3', .2231),
      ]),
      profile,
    );
    expect(rows.single.frames, frames);
  });

  test('cellMarks ignores stroke detections when comparing ink', () {
    const stroke = RecognizedLine(
      text: '-',
      x: .207,
      y: .32,
      width: .008,
      height: .004,
      isStroke: true,
    );
    expect(ScoreboardGrid.cellMarks([mark('5', .205), stroke]), '5-');
    expect(ScoreboardGrid.cellMarks([mark('5', .205), mark('3', .206)]), null);
    expect(ScoreboardGrid.cellMarks([mark('×', .205), mark('X', .206)]), 'X');
  });
}
