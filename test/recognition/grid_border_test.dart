import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/recognition/recognized_text.dart';
import 'package:tallybowl/src/recognition/scoreboard_grid.dart';

void main() {
  test(
    'explicit vertical borders separate numbers with their native bounds',
    () {
      final symbols = [
        for (var i = 0; i < 5; i++)
          RecognizedLine(
            text: '17|35'[i],
            x: .1 + i * .02,
            y: .4,
            width: .015,
            height: .03,
          ),
      ];
      final words = ScoreboardGrid.words(
        RecognizedLine(
          text: '17|35',
          x: .1,
          y: .4,
          width: .1,
          height: .03,
          elements: [
            RecognizedLine(
              text: '17|35',
              x: .1,
              y: .4,
              width: .1,
              height: .03,
              elements: symbols,
            ),
          ],
        ),
      ).toList();
      expect(words.map((w) => w.text), ['17', '35']);
      expect(words.first.x, .1);
      expect(words.first.width, closeTo(.035, .00001));
      expect(words.last.x, closeTo(.16, .00001));
      expect(ScoreboardGrid.symbols(words.first).map((s) => s.text), [
        '1',
        '7',
      ]);
    },
  );
  test('border removal never repairs letters or removes delivery marks', () {
    const line = RecognizedLine(
      text: '107| 2B 7/-',
      x: .1,
      y: .4,
      width: .6,
      height: .03,
    );
    expect(ScoreboardGrid.words(line).map((w) => w.text), ['107', '2B', '7/-']);
  });
}
