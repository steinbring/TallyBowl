import 'models.dart';

/// Display labels for the whole bag, including retired balls. References and
/// selections remain ball IDs; editing a label never changes a game's tags.
class BallLabels {
  factory BallLabels(Iterable<BowlingBall> entries) {
    final balls = entries.toList();
    final bases = {for (final ball in balls) ball.id: base(ball)};
    final baseCounts = _counts(bases.values);
    final candidates = {
      for (final ball in balls)
        ball.id: baseCounts[_key(bases[ball.id]!)]! > 1 && ball.color != null
            ? '${ball.color!.label} · ${bases[ball.id]}'
            : bases[ball.id]!,
    };
    final counts = _counts(candidates.values);
    final reserved = candidates.values.map(_key).toSet();
    final used = <String>{};
    final numbers = <String, int>{};
    final labels = <String, String>{};
    for (final ball in balls) {
      final candidate = candidates[ball.id]!;
      final key = _key(candidate);
      var label = candidate;
      if (counts[key]! > 1) {
        var number = numbers[key] ?? 0;
        do {
          label = 'Ball ${++number} · $candidate';
        } while (reserved.contains(_key(label)) || used.contains(_key(label)));
        numbers[key] = number;
      }
      used.add(_key(label));
      labels[ball.id] = label;
    }
    return BallLabels._(Map.unmodifiable(labels));
  }

  const BallLabels._(this._labels);
  final Map<String, String> _labels;
  String operator [](String id) => _labels[id]!;

  static String base(BowlingBall ball) => [
    if (_text(ball.nickname).isNotEmpty) _text(ball.nickname),
    _text(ball.name),
    '${ball.weight == ball.weight.truncateToDouble() ? ball.weight.toStringAsFixed(0) : ball.weight.toString()} lb',
  ].join(' · ');

  static String _text(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
  static String _key(String value) => _text(value).toLowerCase();
  static Map<String, int> _counts(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final key = _key(value);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}
