import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

RecognizedLine line(String text, double x, double y) =>
    RecognizedLine(text: text, x: x, y: y, width: .8, height: .03);
void main() {
  const profile = BowlerProfile(name: 'Joe', aliases: ['JWS']);
  test(
    'merged runs require all twelve strike marks, independently of total',
    () {
      final row = ScoreSheetParser.rows([
        line('JWS X X XXXX X X X XXX 300', 0, .1),
      ], profile).single;
      expect(row.frames, [...List.filled(9, 'X'), 'XXX']);
      expect(
        ScoreSheetParser.rows([
          line('JWS X X XXX X X X XXX 300', 0, .1),
        ], profile).single.extracted,
        isFalse,
      );
      expect(
        ScoreSheetParser.rows([
          line('JOEL 174', 0, .1),
        ], const BowlerProfile(name: 'Joe')).single.suggested,
        isFalse,
      );
    },
  );
  test(
    'groups row geometry and suggests aliases without selecting a bowler',
    () {
      final rows = ScoreSheetParser.rows([
        line('Other', .03, .1),
        line('9- 9- 9- 9- 9- 9- 9- 9- 9- 9- 90', .2, .1),
        line('JWS', .03, .3),
        line('X X X X X X X X X XXX 300', .2, .3),
      ], profile);
      expect(rows.first.suggested, isTrue);
      expect(rows.first.extracted, isTrue);
      expect(rows.first.displayedTotal, 300);
      expect(rows.first.frames.last, 'XXX');
      expect(rows.last.suggested, isFalse);
    },
  );
  test('totals-only, missing and ambiguous marks never manufacture rolls', () {
    for (final text in [
      'Joe 174',
      'Joe X X 8 1 9 / 7 2',
      'Joe X X X X X X X X X',
    ]) {
      final rows = ScoreSheetParser.rows([line(text, 0, .1)], profile);
      expect(rows.single.extracted, isFalse, reason: text);
      expect(rows.single.frames, List.filled(10, ''));
    }
  });
  test('a displayed total is preserved for mismatch review', () {
    final row = ScoreSheetParser.rows([
      line('Joe 9- 9- 9- 9- 9- 9- 9- 9- 9- 9- 150', 0, .1),
    ], profile).single;
    expect(row.extracted, isTrue);
    expect(row.displayedTotal, 150);
  });
}
