import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

void main() {
  test('Vision lookalikes in whole score tokens read as X and 3', () {
    expect(normalizeScoreLookalikes('Х54'), 'X54'); // Cyrillic Ha.
    expect(normalizeScoreLookalikes('З9'), '39'); // Cyrillic Ze.
    expect(normalizeScoreLookalikes('9/х'), '9/X');
    expect(normalizeScoreLookalikes('Χ Χ'), 'X X'); // Greek Chi.
    expect(normalizeScoreLookalikes('G. З'), 'G. 3');
    expect(normalizeScoreLookalikes('ХХ9 -З'), 'XX9 -3');
  });

  test('names and other words keep their letters', () {
    expect(normalizeScoreLookalikes('ЗОЯ'), 'ЗОЯ');
    expect(normalizeScoreLookalikes('ХАН 3'), 'ХАН 3');
    expect(normalizeScoreLookalikes('Х.'), 'Х.');
    expect(normalizeScoreLookalikes('Bowler 9-'), 'Bowler 9-');
  });

  test('native lines, words and symbols are normalized alike', () {
    final line = RecognizedLine.fromJson({
      'text': 'Х9/ З',
      'x': .1,
      'y': .1,
      'width': .2,
      'height': .02,
      'elements': [
        {
          'text': 'Х9/',
          'x': .1,
          'y': .1,
          'width': .1,
          'height': .02,
          'elements': [
            {'text': 'Х', 'x': .1, 'y': .1, 'width': .03, 'height': .02},
          ],
        },
      ],
    });
    expect(line.text, 'X9/ 3');
    expect(line.elements.single.text, 'X9/');
    expect(line.elements.single.elements.single.text, 'X');
  });

  test('a Vision row with Cyrillic strikes extracts the same frames', () {
    RecognizedLine native(String text, double x) => RecognizedLine.fromJson({
      'text': text,
      'x': x,
      'y': .3,
      'width': .6,
      'height': .03,
    });
    const profile = BowlerProfile(name: 'Bowler');
    final latin = ScoreSheetParser.rows([
      native('Bowler', .02),
      native('X X X X X X X X X XXX 300', .2),
    ], profile).single;
    final vision = ScoreSheetParser.rows([
      native('Bowler', .02),
      native('Х X Х X X Х X X X ХХХ 300', .2),
    ], profile).single;
    expect(latin.frames, [...List.filled(9, 'X'), 'XXX']);
    expect(vision.frames, latin.frames);
    expect(vision.displayedTotal, 300);
  });
}
