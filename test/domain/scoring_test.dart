import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/scoring.dart';

void main() {
  test('perfect game includes exactly two fill balls', () {
    final result = TenPinScorer.score([...List.filled(9, 'X'), 'XXX']);
    expect(result.total, 300);
    expect(result.cumulative, List.generate(10, (i) => (i + 1) * 30));
    expect(result.strikes, 10); // Bonus balls excluded from frame strike rate.
  });
  test('all misses, all spares, and all nines', () {
    expect(TenPinScorer.score(List.filled(10, '--')).total, 0);
    expect(TenPinScorer.score([...List.filled(9, '5/'), '5/5']).total, 150);
    expect(TenPinScorer.score(List.filled(10, '9-')).total, 90);
  });
  test('USBC mixed scoring walkthrough', () {
    final result = TenPinScorer.score([
      '8-',
      '8/',
      '35',
      '53',
      '81',
      'X',
      '9/',
      'X',
      'X',
      '8/6',
    ]);
    expect(result.cumulative, [8, 21, 29, 37, 46, 66, 86, 114, 134, 150]);
    expect(result.total, 150);
  });
  test('fouls count as zero and can precede a spare', () {
    expect(TenPinScorer.score([...List.filled(9, 'F/'), 'F/F']).total, 100);
    expect(TenPinScorer.parseFrame('F9').pins, [0, 9]);
  });
  test('tenth frame rack resets and limits', () {
    for (final frame in ['X7/', 'XX9', '9/X', 'X--', 'F/X', '--']) {
      expect(
        TenPinScorer.parseFrame(frame, tenth: true).complete,
        isTrue,
        reason: frame,
      );
    }
    for (final frame in [
      'X/9',
      'XX/',
      '9//',
      '993',
      'X88',
      '5/55',
      '99',
      '55',
    ]) {
      expect(
        TenPinScorer.parseFrame(frame, tenth: true).error,
        isNotNull,
        reason: frame,
      );
    }
    expect(TenPinScorer.parseFrame('X7', tenth: true).complete, isFalse);
    expect(TenPinScorer.parseFrame('9/', tenth: true).complete, isFalse);
  });
  test('unfinished strike bonus does not fabricate a cumulative score', () {
    final result = TenPinScorer.score(['X', '5', ...List.filled(8, '')]);
    expect(result.total, isNull);
    expect(result.cumulative, everyElement(isNull));
    expect(result.complete, isFalse);
  });
  test('a blank frame cannot be skipped to invent a later running score', () {
    final result = TenPinScorer.score(['9-', '', ...List.filled(8, '9-')]);
    expect(result.runningTotal, 9);
    expect(result.cumulative.skip(1), everyElement(isNull));
  });
  test('invalid ordinary frames and lengths are rejected', () {
    for (final frame in ['XX', '/9', '88', '5X', '?', '123', '55']) {
      expect(TenPinScorer.parseFrame(frame).error, isNotNull, reason: frame);
    }
    expect(() => TenPinScorer.score(['X']), throwsArgumentError);
  });
}
