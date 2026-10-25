import '../domain/models.dart';
import '../domain/scoring.dart';

import 'recognized_text.dart';
import 'scoreboard_grid.dart';

export 'recognized_text.dart';

/// Parse observed deliveries from text rows or scoreboard grid geometry.
/// Never solves missing rolls by guessing a combination that matches a total.
abstract final class ScoreSheetParser {
  static ScoreRow? automaticRow(List<ScoreRow> rows) {
    final candidates = rows
        .where(
          (row) =>
              row.suggested && (row.cumulativeTotals != null || row.extracted),
        )
        .toList();
    return candidates.length == 1 && candidates.single.canAutoSelect
        ? candidates.single
        : null;
  }

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
    final gridRows = ScoreboardGrid.rows(lines, profile);
    final result = <ScoreRow>[...gridRows];
    for (final group in groups) {
      group.sort((a, b) => a.x.compareTo(b.x));
      final text = group.map((l) => l.text).join(' ');
      if (text.trim().isEmpty) continue;
      // A grid row already associates this name with both mark/total bands.
      if (gridRows.any(
        (row) => group.any(
          (line) => line.centerY >= row.y && line.centerY <= row.y + row.height,
        ),
      )) {
        continue;
      }
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
      if (runTotal != null && (runTotal < 0 || runTotal > 300)) {
        return (null, null);
      }
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
