import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/recognized_text.dart';
import 'package:tallybowl/src/recognition/recovery_layout.dart';

RecognizedLine word(
  String text,
  double x,
  double y, [
  double width = .02,
  double height = .04,
]) => RecognizedLine(text: text, x: x, y: y, width: width, height: height);
final player = word('Bowler', .01, .25, .1);
List<RecognizedLine> observed() => [
  for (var i = 0; i < 10; i++) ...[
    word('${9 * (i + 1)}', .19 + .06 * i, .32),
    word('9-', .18 + .06 * i, .26, .04),
  ],
];
RecoveryScoreBand? fit(
  List<RecognizedLine> words, {
  RecognizedLine? name,
  double first = .2,
}) => RecoveryScoreBand.fit(
  words,
  name: name ?? player,
  first: first,
  pitch: .06,
  headerY: .18,
  headerSlope: 0,
  headerHeight: .02,
);

void main() {
  test('observed cumulative centers correct right-aligned headers', () {
    final words = observed();
    final band = fit(words, first: .21)!;
    final columns = band.columns(words, .21, .06)!;
    expect(columns.$1, closeTo(.2, .00001));
    expect(columns.$2, closeTo(.06, .00001));
  });
  test('current total is selected by baseline, before handicap column', () {
    final words = observed();
    final band = fit(words)!;
    final totals = band.totals(
      [
        ...words,
        word('TOTAL', .81, .19, .04, .02),
        word('122', .81, .26, .04), // Previous game, same column.
        word('90', .81, .32, .04),
        word('162', .9, .32, .04), // Handicap is a later column.
      ],
      .2,
      .06,
    );
    expect(totals.map((w) => w.text), ['90']);
  });
  test('a labeled total can sit above the cumulative baseline', () {
    final band = fit(observed())!;
    final totals = band.totals(
      [word('Cumul', .81, .22, .04, .02), word('90', .81, .27, .04, .02)],
      .2,
      .06,
    );
    expect(totals.map((w) => w.text), ['90']);
  });
  test('competing totals in the first column remain ambiguous', () {
    final band = fit(observed())!;
    expect(
      band.totals(
        [word('90', .81, .32, .04), word('91', .82, .325, .04)],
        .2,
        .06,
      ),
      isEmpty,
    );
  });
  test('footer identity cannot claim an earlier score band', () {
    expect(fit(observed(), name: word('Bowler', .01, .50, .1)), isNull);
  });
  test('six checkpoints and the tenth must be independently observed', () {
    final words = observed();
    expect(fit(words.where((w) => w.x < .7).toList()), isNull);
    expect(
      fit(
        words
            .where(
              (w) =>
                  !RegExp(r'^\d+$').hasMatch(w.text) ||
                  ['9', '27', '45', '63', '90'].contains(w.text),
            )
            .toList(),
      ),
      isNull,
    );
  });
  test('impossible observed cumulative progression rejects a band', () {
    final words = observed().where((w) => w.text != '90').toList()
      ..add(word('300', .73, .32));
    expect(fit(words), isNull);
  });
  test('a later player score band does not bind to a small name above it', () {
    final words = [
      ...observed(),
      for (var i = 0; i < 10; i++) ...[
        word('${8 * (i + 1)}', .19 + .06 * i, .48),
        word('8-', .18 + .06 * i, .42, .04),
      ],
    ];
    expect(fit(words)?.firstY, closeTo(.34, .00001));
  });
  test('only an exact adjacent observed alias joins stacked name words', () {
    final first = word('Sunny', .01, .25, .09);
    final last = word('Delight', .01, .295, .1);
    const profile = BowlerProfile(name: 'Sunny Delight');
    expect(
      recoveryNameWords([first, last], profile).last.text,
      'Sunny Delight',
    );
    expect(
      recoveryNameWords([first, word('Different', .01, .295, .1)], profile),
      hasLength(2),
    );
    expect(
      recoveryNameWords([first, word('Delight', .01, .5, .1)], profile),
      hasLength(2),
    );
  });
  test(
    'merged headers use native character boxes and keep header ten intact',
    () {
      final merged = RecognizedLine(
        text: 'B910',
        x: .5,
        y: .18,
        width: .2,
        height: .02,
        elements: [
          word('B', .5, .18, .02, .02),
          word('9', .56, .18, .02, .02),
          word('1', .62, .18, .01, .02),
          word('0', .635, .18, .02, .02),
        ],
      );
      final recovered = observedHeaderSymbols(merged);
      expect(recovered.map((w) => w.text), ['9', '1', '10']);
      expect(recovered.last.x, .62);
      expect(
        observedHeaderSymbols(word('8910', .5, .18, .2, .02)),
        isEmpty,
        reason: 'A word box alone cannot supply native character positions.',
      );
    },
  );
}
