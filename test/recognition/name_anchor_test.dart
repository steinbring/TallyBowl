import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/recovery_layout.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';
import 'package:tallybowl/src/recognition/scoreboard_grid.dart';
import 'package:tallybowl/src/recognition/scoreboard_name.dart';

const frames = ['53', '63', '9-', '7/', '16', '7-', '35', '6-', '42', 'X9-'];
const totals = [8, 17, 26, 37, 44, 51, 59, 65, 71, 90];

RecognizedLine word(
  String text,
  double x,
  double y,
  double width,
  double height, {
  List<RecognizedLine> elements = const [],
}) => RecognizedLine(
  text: text,
  x: x,
  y: y,
  width: width,
  height: height,
  elements: elements,
);

/// One grid row whose bowler label is given as separate native words.
List<RecognizedLine> board(List<RecognizedLine> name) => [
  ...name,
  for (var i = 0; i < 10; i++) ...[
    word('${i + 1}', .25 + i * .06, .25, .015, .02),
    word(
      '${totals[i]}',
      .26 + i * .06 - (totals[i] < 10 ? .01 : .022),
      .36,
      totals[i] < 10 ? .01 : .022,
      .04,
    ),
    word(
      frames[i],
      .205 + i * .06,
      .30,
      .05,
      .045,
      elements: [
        for (var c = 0; c < frames[i].length; c++)
          word(frames[i][c], .205 + i * .06 + c * .018, .30, .012, .045),
      ],
    ),
  ],
  word('90', .84, .31, .04, .09),
];

void main() {
  test('accented saved names match unaccented scoreboard text', () {
    expect(normalizedBowlerName('José'), normalizedBowlerName('JOSE'));
    expect(normalizedBowlerName('Zoë'), 'ZOE');
    expect(normalizedBowlerName('Müller'), 'MULLER');
    expect(normalizedBowlerName('Øyvind'), 'OYVIND');
    expect(normalizedBowlerName('Straße'), 'STRASSE');
    expect(normalizedBowlerName('Łukasz'), 'LUKASZ');
    // Folding never turns a different letter or digit into a match.
    expect(normalizedBowlerName('Jose'), isNot(normalizedBowlerName('Josie')));
    expect(normalizedBowlerName('J0SÉ'), isNot('JOSE'));
  });

  test('a two-word scoreboard alias identifies its grid row', () {
    const profile = BowlerProfile(name: 'Joe Steinbring', aliases: ['JOE S']);
    final rows = ScoreboardGrid.rows(
      board([word('JOE', .03, .295, .07, .10), word('S', .11, .295, .03, .10)]),
      profile,
    );
    final row = rows.singleWhere((r) => r.suggested);
    expect(row.frames, frames);
    expect(row.cumulativeTotals, totals);
    expect(ScoreSheetParser.automaticRow(rows), isNotNull);
  });

  test('part of a two-word alias does not identify the row', () {
    final rows = ScoreboardGrid.rows(
      board([word('JOE', .03, .295, .07, .10), word('T', .11, .295, .03, .10)]),
      const BowlerProfile(name: 'Joe', aliases: ['JOE S']),
    );
    expect(rows.where((r) => r.suggested && r.text.contains('JOE S')), isEmpty);
    expect(
      ScoreboardGrid.rows(
        board([word('JOE', .03, .295, .07, .10)]),
        const BowlerProfile(name: 'Someone', aliases: ['JOE S']),
      ).where((r) => r.suggested),
      isEmpty,
    );
  });

  test('three adjacent words spell an alias; distant words do not', () {
    const profile = BowlerProfile(name: 'Mary Jo K');
    final mary = word('MARY', .03, .3, .08, .04);
    final jo = word('JO', .12, .3, .04, .04);
    final k = word('K', .17, .3, .02, .04);
    expect(
      nameAnchorWords([mary, jo, k], profile).map((w) => w.text),
      contains('MARY JO K'),
    );
    final far = word('K', .6, .3, .02, .04);
    expect(nameAnchorWords([mary, jo, far], profile), hasLength(3));
  });

  test('a text row matches a split alias after a lane number', () {
    const profile = BowlerProfile(name: 'Joe', aliases: ['JOE S']);
    final rows = ScoreSheetParser.rows([
      RecognizedLine(
        text: 'LN JOE S ${List.filled(10, '9-').join(' ')} 90',
        x: .05,
        y: .2,
        width: .9,
        height: .03,
      ),
    ], profile);
    expect(ScoreSheetParser.automaticRow(rows)?.displayedTotal, 90);
  });

  group('alias glued to score marks', () {
    RecognizedLine glued(String text, double gap, {int split = 1}) {
      var x = .03;
      final symbols = <RecognizedLine>[];
      for (var i = 0; i < text.length; i++) {
        symbols.add(word(text[i], x, .34, .03, .04));
        x += .03 + (i == split - 1 ? gap * .04 : .002);
      }
      return word(text, .03, .34, x - .03, .04, elements: symbols);
    }

    // Native results nest line -> word -> character boxes.
    RecognizedLine line(RecognizedLine word) => RecognizedLine(
      text: word.text,
      x: word.x,
      y: word.y,
      width: word.width,
      height: word.height,
      elements: [word],
    );

    test('splits only across a measured gap before marks', () {
      expect(aliasBeforeMarks(glued('BX', .53), {'B'})?.map((s) => s.text), [
        'B',
      ]);
      expect(aliasBeforeMarks(glued('BX', .1), {'B'}), isNull);
      expect(aliasBeforeMarks(glued('BXE', .53), {'B'}), isNull);
      expect(aliasBeforeMarks(glued('B9', .53), {'C'}), isNull);
      // Without real character boxes nothing can be separated.
      expect(aliasBeforeMarks(word('BX', .03, .3, .1, .04), {'B'}), isNull);
    });

    test('the split alias anchors the grid row', () {
      final rows = ScoreboardGrid.rows(
        board([line(glued('BOX', .6, split: 2))]),
        const BowlerProfile(name: 'Bo'),
      );
      expect(rows.where((r) => r.suggested).single.frames, frames);
      expect(
        ScoreboardGrid.rows(
          board([line(glued('BOX', .1, split: 2))]),
          const BowlerProfile(name: 'Bo'),
        ).where((r) => r.suggested),
        isEmpty,
      );
    });
  });
}
