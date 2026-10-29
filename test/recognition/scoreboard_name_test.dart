import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';
import 'package:tallybowl/src/recognition/scoreboard_name.dart';

void main() {
  test('mixed-script OCR lookalikes match a visible Latin bowler name', () {
    expect(normalizedBowlerName('KАT'), 'KAT'); // Cyrillic A.
    expect(normalizedBowlerName('JОЕ'), 'JOE'); // Cyrillic O/E.
    expect(normalizedBowlerName('Ρat'), 'PAT'); // Greek Rho.
    expect(isBowlerNameCandidate('КАT'), isTrue);
  });

  test('name normalization does not substitute digits or fuzzy spellings', () {
    expect(normalizedBowlerName('KA7'), isNot('KAT'));
    expect(normalizedBowlerName('J0E'), isNot('JOE'));
    expect(normalizedBowlerName('Kate'), isNot('KAT'));
  });

  RecognizedLine row(String name, double y) => RecognizedLine(
    text: '$name ${List.filled(10, '9-').join(' ')} 90',
    x: .1,
    y: y,
    width: .8,
    height: .03,
  );

  test('mixed-script name can select an independently complete score row', () {
    final selected = ScoreSheetParser.automaticRow(
      ScoreSheetParser.rows([row('KАT', .2)], const BowlerProfile(name: 'Kat')),
    );
    expect(selected?.frames, List.filled(10, '9-'));
    expect(selected?.displayedTotal, 90);
    expect(
      ScoreSheetParser.automaticRow(
        ScoreSheetParser.rows([
          row('KA7', .2),
        ], const BowlerProfile(name: 'Kat')),
      ),
      isNull,
    );
  });

  test('two visually matching rows still require bowler confirmation', () {
    expect(
      ScoreSheetParser.automaticRow(
        ScoreSheetParser.rows([
          row('KAT', .2),
          row('KАT', .5),
        ], const BowlerProfile(name: 'Kat')),
      ),
      isNull,
    );
  });
}
