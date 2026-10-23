import '../domain/models.dart';
import '../domain/scoring.dart';

class RecognizedLine {
  const RecognizedLine({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence,
  });
  final String text;
  final double x, y, width, height;
  final double? confidence;
  factory RecognizedLine.fromJson(Map<dynamic, dynamic> j) => RecognizedLine(
    text: j['text'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
    confidence: (j['confidence'] as num?)?.toDouble(),
  );
}

class ScoreRow {
  const ScoreRow({
    required this.text,
    required this.frames,
    required this.suggested,
    required this.y,
    required this.height,
    this.displayedTotal,
  });
  final String text;
  final List<String> frames;
  final bool suggested;
  final double y, height;
  final int? displayedTotal;
  bool get extracted => TenPinScorer.score(frames).complete;
}

/// Conservative first parser for clearly separated, horizontally aligned rows.
/// Never solves missing rolls by guessing a combination that matches a total.
abstract final class ScoreSheetParser {
  static List<ScoreRow> rows(
    List<RecognizedLine> lines,
    BowlerProfile profile,
  ) {
    final groups = <List<RecognizedLine>>[];
    for (final line in [...lines]..sort((a, b) => a.y.compareTo(b.y))) {
      final center = line.y + line.height / 2;
      final group = groups.where((g) {
        final anchor = g.first;
        final tolerance =
            (anchor.height < line.height ? anchor.height : line.height) * .7;
        return (anchor.y + anchor.height / 2 - center).abs() <
            (tolerance < .008 ? .008 : tolerance);
      }).firstOrNull;
      if (group == null) {
        groups.add([line]);
      } else {
        group.add(line);
      }
    }
    final aliases = [
      profile.name,
      ...profile.aliases,
    ].map(_normalized).where((v) => v.isNotEmpty).toList();
    final result = <ScoreRow>[];
    for (final group in groups) {
      group.sort((a, b) => a.x.compareTo(b.x));
      final text = group.map((l) => l.text).join(' ');
      if (text.trim().isEmpty) continue;
      final extraction = _extract(text);
      // Include name-like rows and complete mark rows, excluding numeric totals.
      final hasName = RegExp(
        r'[A-EG-WYZ]{2,}',
        caseSensitive: false,
      ).hasMatch(text);
      if (!hasName && extraction.$1 == null) continue;
      final words = text.split(RegExp(r'\s+')).map(_normalized).toList();
      final suggested = aliases.any(
        (alias) =>
            words.contains(alias) ||
            (alias.length > 2 &&
                List.generate(
                  words.length,
                  (i) => words.take(i + 1).join(),
                ).contains(alias)),
      );
      result.add(
        ScoreRow(
          text: text,
          frames: extraction.$1 ?? List.filled(10, ''),
          suggested: suggested,
          y: group.map((l) => l.y).reduce((a, b) => a < b ? a : b),
          height:
              group.map((l) => l.y + l.height).reduce((a, b) => a > b ? a : b) -
              group.map((l) => l.y).reduce((a, b) => a < b ? a : b),
          displayedTotal: extraction.$2,
        ),
      );
    }
    result.sort(
      (a, b) => a.suggested == b.suggested
          ? a.y.compareTo(b.y)
          : (a.suggested ? -1 : 1),
    );
    return result;
  }

  static String _normalized(String text) =>
      text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  static (List<String>?, int?) _extract(String source) {
    final text = source
        .toUpperCase()
        .replaceAll('×', 'X')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    // Vision can merge spaced strikes across frame boundaries. Twelve actual
    // strike marks have exactly one legal frame partition; a displayed 300
    // without all twelve marks is never enough to infer this sequence.
    final runs = RegExp(r'(?<![A-Z0-9])[XF0-9/\-]+(?![A-Z0-9])')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    int? runTotal;
    if (runs.isNotEmpty && RegExp(r'^\d+$').hasMatch(runs.last)) {
      runTotal = int.tryParse(runs.removeLast());
    }
    if (runs.isNotEmpty &&
        runs.every((r) => RegExp(r'^X+$').hasMatch(r)) &&
        runs.join().length == 12) {
      return ([...List.filled(9, 'X'), 'XXX'], runTotal);
    }
    final tokens = RegExp(r'(?<![A-Z0-9])[XF0-9/\-]{1,3}(?![A-Z0-9])')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    int? displayed;
    if (tokens.length == 11) {
      displayed = int.tryParse(tokens.removeLast());
      if (displayed == null || displayed < 0 || displayed > 300) {
        return (null, null);
      }
    }
    if (tokens.length != 10) return (null, null);
    final score = TenPinScorer.score(tokens);
    if (!score.complete) return (null, displayed);
    return (tokens, displayed);
  }
}
