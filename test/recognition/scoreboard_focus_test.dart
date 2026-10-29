import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/recognition/recognized_text.dart';
import 'package:tallybowl/src/recognition/scoreboard_focus.dart';

const profile = BowlerProfile(name: 'Bowler', aliases: ['Alias']);
RecognizedLine word(
  String text,
  double x,
  double y, {
  double width = .03,
  double height = .035,
}) => RecognizedLine(text: text, x: x, y: y, width: width, height: height);
List<RecognizedLine> row(double y, {String name = 'Bowler'}) => [
  word(name, .08, y, width: .09, height: .05),
  for (var i = 0; i < 10; i++) word('${(i + 1) * 9}', .2 + i * .04, y + .025),
];

void main() {
  test('focus keeps headers, all frames and space for separate totals', () {
    final region = ScoreboardFocus.region([row(.4)], profile)!;
    expect(region.x, lessThan(.08));
    expect(region.y, lessThan(.3));
    expect(region.x + region.width, greaterThan(.7));
    expect(region.y + region.height, greaterThan(.46));
    expect(region.x, greaterThanOrEqualTo(0));
    expect(region.x + region.width, lessThanOrEqualTo(1));
  });
  test('repeated passes and footer name do not create a second player', () {
    final input = [...row(.4), word('Bowler', .08, .49)];
    expect(ScoreboardFocus.region([input, input], profile), isNotNull);
  });
  test('distinct matching player rows preserve ambiguity', () {
    expect(
      ScoreboardFocus.region([
        [...row(.25), ...row(.6)],
      ], profile),
      isNull,
    );
  });
  test('aliases work but unrelated names and sparse numbers do not focus', () {
    expect(
      ScoreboardFocus.region([row(.4, name: 'Alias')], profile),
      isNotNull,
    );
    expect(ScoreboardFocus.region([row(.4, name: 'Other')], profile), isNull);
    expect(ScoreboardFocus.region([row(.4).take(5).toList()], profile), isNull);
  });
  test('footer below scores cannot anchor the scoreboard', () {
    expect(
      ScoreboardFocus.region([
        [
          word('Bowler', .08, .49),
          for (var i = 0; i < 10; i++) word('${i * 9}', .2 + i * .04, .42),
        ],
      ], profile),
      isNull,
    );
  });
}
