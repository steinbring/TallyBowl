import 'dart:math' as math;

import '../domain/models.dart';
import 'recognized_text.dart';
import 'scoreboard_name.dart';

/// A second, independently observed score band. Values validate deliveries;
/// they never determine which delivery glyph to read.
class RecoveryScoreBand {
  const RecoveryScoreBand(this.firstY, this.slope, this.height, this.markTop);
  final double firstY, slope, height, markTop;

  double y(double x, double first, double pitch) =>
      firstY + (x - first) / pitch * slope;

  static RecoveryScoreBand? fit(
    List<RecognizedLine> words, {
    required RecognizedLine name,
    required double first,
    required double pitch,
    required double headerY,
    required double headerSlope,
    required double headerHeight,
    bool allowCompactScores = false,
  }) {
    if (pitch <= 0 || headerHeight <= 0) return null;
    final numbers = <(int, RecognizedLine)>[];
    for (final word in words) {
      if (_number(word) == null) continue;
      final index = ((word.centerX - first) / pitch).round();
      if (index < 0 ||
          index > 9 ||
          (word.centerX - first - index * pitch).abs() > pitch * .48) {
        continue;
      }
      final projected = word.centerY - index * headerSlope;
      final atName = projected + (name.centerX - first) / pitch * headerSlope;
      // Footer labels cannot claim an earlier player's score band. A row name
      // may be beside the marks or cumulative scores, but must begin above it.
      if (atName < name.y + name.height * .15 ||
          atName > name.y + word.height * 1.8 + name.height * .5 ||
          atName > name.y + math.max(name.height * 2.5, headerHeight * 4) ||
          projected < headerY + headerHeight * 2 ||
          word.height < headerHeight * (allowCompactScores ? .75 : 1.15)) {
        continue;
      }
      numbers.add((index, word));
    }
    // A dense or ambiguous text field is not a bounded scoreboard row.
    if (numbers.length > 80) return null;
    final candidates = <(int, double, RecoveryScoreBand)>[];
    for (final a in numbers) {
      for (final b in numbers) {
        if (b.$1 - a.$1 < 5) continue;
        final slope = (b.$2.centerY - a.$2.centerY) / (b.$1 - a.$1);
        if ((slope - headerSlope).abs() > headerHeight * .3 ||
            (slope / pitch).abs() > .4) {
          continue;
        }
        final start = a.$2.centerY - a.$1 * slope;
        final bySlot = <int, List<RecognizedLine>>{};
        for (final entry in numbers) {
          if ((entry.$2.centerY - start - entry.$1 * slope).abs() <
              math.min(a.$2.height, b.$2.height) * .24) {
            bySlot.putIfAbsent(entry.$1, () => []).add(entry.$2);
          }
        }
        if (bySlot.length < 6 ||
            !bySlot.containsKey(9) ||
            bySlot.values.any((v) => v.length != 1)) {
          continue;
        }
        final checks = bySlot.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        // Only reject impossible observed score bands; never invent a value
        // or choose a band's geometry by a calculated game total.
        if (List.generate(checks.length - 1, (i) => i).any((i) {
          final left = checks[i], right = checks[i + 1];
          final delta =
              _number(right.value.single)! - _number(left.value.single)!;
          return delta < 0 || delta > 30 * (right.key - left.key);
        })) {
          continue;
        }
        final heights = checks.map((e) => e.value.single.height).toList()
          ..sort();
        final height = heights[heights.length ~/ 2];
        final positions =
            checks.map((e) => e.value.single.centerY - e.key * slope).toList()
              ..sort();
        final firstY = positions[positions.length ~/ 2];
        final marks = words.where((w) {
          if (!RegExp(
                r'^[0-9XF/×–—\-]+$',
                caseSensitive: false,
              ).hasMatch(w.text) ||
              w.centerX < first - pitch * .5 ||
              w.centerX > first + 9.7 * pitch ||
              w.width > pitch * 2.5) {
            return false;
          }
          final above =
              firstY + (w.centerX - first) / pitch * slope - w.centerY;
          return above > height * .65 &&
              above < height * (allowCompactScores ? 2.5 : 1.8) &&
              (!allowCompactScores ||
                  w.centerY > headerY + headerHeight * .5) &&
              w.height > height * .35 &&
              w.height < height * 1.4;
        }).toList();
        if (marks.length < 3) continue;
        final tops =
            marks.map((w) => w.y - (w.centerX - first) / pitch * slope).toList()
              ..sort();
        final markTop = tops[tops.length ~/ 2] - height * .2;
        final error = positions.fold(0.0, (v, p) => v + (p - firstY).abs());
        final band = RecoveryScoreBand(firstY, slope, height, markTop);
        if (candidates.any((c) => (c.$3.firstY - firstY).abs() < height * .3)) {
          continue;
        }
        candidates.add((bySlot.length, error, band));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => b.$1 != a.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2),
    );
    // Two separate plausible cumulative bands beside the same name are not a
    // license to pick the one that makes a recovered delivery sequence score.
    if (candidates.length > 1) return null;
    return candidates.first.$3;
  }

  /// Cumulative numerals are normally centered even when frame headers are
  /// right-aligned. Fit their observed centers; ignore the wider tenth cell.
  (double, double)? columns(
    List<RecognizedLine> words,
    double first,
    double pitch,
  ) {
    final points = <(int, double)>[];
    for (final word in words) {
      if (_number(word) == null ||
          (word.centerY - y(word.centerX, first, pitch)).abs() > height * .35) {
        continue;
      }
      final index = ((word.centerX - first) / pitch).round();
      if (index < 0 ||
          index > 8 ||
          (word.centerX - first - index * pitch).abs() > pitch * .48) {
        continue;
      }
      points.add((index, word.centerX));
    }
    if (points.length < 6 ||
        points.map((p) => p.$1).toSet().length != points.length) {
      return null;
    }
    final mx = points.fold(0.0, (v, p) => v + p.$1) / points.length;
    final my = points.fold(0.0, (v, p) => v + p.$2) / points.length;
    final variance = points.fold(0.0, (v, p) => v + (p.$1 - mx) * (p.$1 - mx));
    if (variance == 0) return null;
    final step =
        points.fold(0.0, (v, p) => v + (p.$1 - mx) * (p.$2 - my)) / variance;
    final start = my - step * mx;
    if ((step / pitch - 1).abs() > .15 ||
        (start - first).abs() > pitch * .35 ||
        points.any((p) => (p.$2 - start - p.$1 * step).abs() > pitch * .15)) {
      return null;
    }
    return (start, step);
  }

  /// The final crop retry also permits a right-aligned numeral whose native
  /// box overlaps its heading. The row bounds and first-column ambiguity
  /// checks still apply; no calculated score chooses a total's position.
  List<RecognizedLine> totals(
    List<RecognizedLine> words,
    double first,
    double pitch, {
    bool allowOffsetTotal = false,
  }) {
    if (allowOffsetTotal) {
      final stacked = _stackedTotals(words, first, pitch);
      if (stacked.isNotEmpty) return stacked;
    }
    final last = first + 9 * pitch;
    final outside = words.where(
      (w) =>
          _number(w) != null &&
          w.centerX > last + pitch * .55 &&
          w.centerX < last + pitch * 3,
    );
    final aligned = outside
        .where(
          (w) =>
              (w.centerY - y(w.centerX, first, pitch)).abs() <
              math.max(height, w.height) * .55,
        )
        .toList();
    final labeled = <RecognizedLine>[];
    for (final header in words.where(
      (w) =>
          RegExp(
            r'^(TOT(?:AL)?|TTL|CUMUL(?:ATIVE)?)$',
            caseSensitive: false,
          ).hasMatch(w.text.replaceAll(RegExp(r'[^a-zA-Z]'), '')) &&
          w.centerX > last + pitch * .55 &&
          w.y < firstY,
    )) {
      final column = outside
          .where(
            (w) =>
                ((w.centerX - header.centerX).abs() < pitch * .5 ||
                    (allowOffsetTotal &&
                        w.x < header.x + header.width &&
                        w.x + w.width > header.x)) &&
                w.centerY > y(w.centerX, first, pitch) - height * 1.8 &&
                w.centerY < y(w.centerX, first, pitch) + height * .6 &&
                w.y > header.y + header.height * .8,
          )
          .toList();
      if (column.length == 1) labeled.add(column.single);
    }
    final all = {...aligned, ...labeled}.toList()
      ..sort((a, b) => a.centerX.compareTo(b.centerX));
    if (all.isEmpty) return [];
    // The first numeric column is scratch; a later handicap column cannot be
    // selected by value. Competing values in that first column stay ambiguous.
    final firstColumn = all
        .where((w) => (w.centerX - all.first.centerX).abs() < pitch * .4)
        .toList();
    return firstColumn.length == 1 ? firstColumn : [];
  }

  /// Some consoles stack scratch above handicap under one TOTAL heading.
  /// Require three separately observed row pairs whose upper entries repeat
  /// their frame-ten checkpoints. No calculated delivery score selects a row.
  List<RecognizedLine> _stackedTotals(
    List<RecognizedLine> words,
    double first,
    double pitch,
  ) {
    final last = first + 9 * pitch;
    final matches = <RecognizedLine>[];
    for (final label in words.where(
      (w) =>
          w.text.toUpperCase() == 'TOTAL' &&
          w.x > last + pitch * .55 &&
          w.x < last + pitch * 3 &&
          w.y < firstY,
    )) {
      if (!words.any(
        (w) =>
            w.text.toUpperCase() == 'PLAYER' &&
            w.x < first &&
            (w.centerY - label.centerY).abs() <
                math.max(w.height, label.height),
      )) {
        continue;
      }
      final column = words
          .where(
            (w) =>
                _number(w) != null &&
                (w.centerX - label.centerX).abs() < pitch * .5 &&
                w.y > label.y + label.height,
          )
          .toList();
      final pairs = <(RecognizedLine, RecognizedLine)>[];
      for (final check in words.where(
        (w) =>
            _number(w) != null &&
            (w.centerX - last).abs() < pitch * .48 &&
            w.y > label.y + label.height * 2 &&
            w.height > height * .65 &&
            w.height < height * 1.5,
      )) {
        final baseline =
            check.centerY + (label.centerX - check.centerX) / pitch * slope;
        final lower = column
            .where((w) => (w.centerY - baseline).abs() < height * .4)
            .toList();
        final upper = column
            .where(
              (w) =>
                  baseline - w.centerY > height * 1.15 &&
                  baseline - w.centerY < height * 2.5,
            )
            .toList();
        if (lower.length != 1 ||
            upper.length != 1 ||
            _number(upper.single) != _number(check)) {
          continue;
        }
        if (pairs.any((p) => (p.$1.centerY - check.centerY).abs() < height)) {
          continue;
        }
        pairs.add((check, upper.single));
      }
      if (pairs.length < 3 || pairs.length > 8) continue;
      final gaps = pairs.map((p) => p.$1.centerY - p.$2.centerY).toList()
        ..sort();
      if (gaps.last - gaps.first > height * .45) continue;
      matches.addAll(
        pairs
            .where(
              (p) =>
                  (p.$1.centerY - y(p.$1.centerX, first, pitch)).abs() <
                  height * .35,
            )
            .map((p) => p.$2),
      );
    }
    return matches.length == 1 ? matches : [];
  }

  static int? _number(RecognizedLine w) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(w.text)) return null;
    final value = int.parse(w.text);
    return value <= 300 ? value : null;
  }
}

/// Name anchors built only from observed words: a single word, two or three
/// horizontally adjacent words (or a two-line pair) whose letters exactly
/// spell a saved alias such as "JOE S", or an alias a native engine joined to
/// following score marks across a measured gap between its character boxes.
/// Delivery text is never changed and no missing letter is guessed.
List<RecognizedLine> nameAnchorWords(
  List<RecognizedLine> words,
  BowlerProfile profile,
) {
  final aliases = [
    profile.name,
    ...profile.aliases,
  ].map(normalizedBowlerName).where((n) => n.isNotEmpty).toSet();
  final output = [...words];
  void add(List<RecognizedLine> parts, {List<RecognizedLine>? symbols}) {
    final text = parts.map((p) => p.text).join(symbols == null ? ' ' : '');
    final left = parts.map((p) => p.x).reduce(math.min);
    final top = parts.map((p) => p.y).reduce(math.min);
    if (output.any(
      (w) =>
          normalizedBowlerName(w.text) == normalizedBowlerName(text) &&
          (w.x - left).abs() < .001 &&
          (w.y - top).abs() < .001,
    )) {
      return;
    }
    output.add(
      RecognizedLine(
        text: text,
        x: left,
        y: top,
        width: parts.map((p) => p.x + p.width).reduce(math.max) - left,
        height: parts.map((p) => p.y + p.height).reduce(math.max) - top,
        elements: symbols ?? const [],
      ),
    );
  }

  bool spells(List<RecognizedLine> parts) => aliases.contains(
    normalizedBowlerName(parts.map((p) => p.text).join(' ')),
  );
  bool beside(RecognizedLine a, RecognizedLine b) =>
      (a.centerY - b.centerY).abs() < math.min(a.height, b.height) * .5 &&
      b.x >= a.x + a.width * .8 &&
      b.x - a.x - a.width < math.max(a.height, b.height);
  bool below(RecognizedLine a, RecognizedLine b) =>
      (a.x - b.x).abs() < math.max(a.width, b.width) * .3 &&
      b.y >= a.y + a.height * .7 &&
      b.y - a.y - a.height < math.max(a.height, b.height) * .7;
  final text = words
      .where(
        (w) =>
            RegExp(r"^[\p{L} .'’\-]+$", unicode: true).hasMatch(w.text) &&
            RegExp(r'\p{L}', unicode: true).hasMatch(w.text),
      )
      .toList();
  for (final a in text) {
    for (final b in text) {
      if (identical(a, b)) continue;
      if ((below(a, b) || beside(a, b)) && spells([a, b])) add([a, b]);
      if (!beside(a, b)) continue;
      for (final c in text) {
        if (identical(c, a) || identical(c, b)) continue;
        if (beside(b, c) && spells([a, b, c])) add([a, b, c]);
      }
    }
  }
  for (final word in words) {
    final symbols = aliasBeforeMarks(word, aliases);
    if (symbols != null) add(symbols, symbols: symbols);
  }
  return output;
}

/// ML Kit can return a name and the first frame's marks as one word, such as
/// "AX" for alias "A" and a strike. Separate the alias only from real native
/// character boxes: every following character must be a score mark, and the
/// boundary must be a visible gap of at least .3 of the median character
/// height. Synthesized boxes, letters and fuzzy spellings never qualify.
List<RecognizedLine>? aliasBeforeMarks(
  RecognizedLine word,
  Set<String> aliases,
) {
  final symbols = word.elements;
  if (symbols.length < 2 || symbols.any((s) => s.text.length != 1)) {
    return null;
  }
  final mark = RegExp(r'^[0-9XF/\-]$', caseSensitive: false);
  final heights = symbols.map((s) => s.height).toList()..sort();
  final median = heights[heights.length ~/ 2];
  var spelled = '';
  for (var i = 0; i + 1 < symbols.length; i++) {
    spelled += normalizedBowlerName(symbols[i].text);
    if (!aliases.contains(spelled) ||
        !symbols.skip(i + 1).every((s) => mark.hasMatch(s.text)) ||
        symbols[i + 1].x - symbols[i].x - symbols[i].width < median * .3) {
      continue;
    }
    return symbols.take(i + 1).toList();
  }
  return null;
}

/// Recover merged numbered headers only from actual native character boxes.
/// A trailing 1 and 0 can form header 10; no lookalike letters are substituted.
List<RecognizedLine> observedHeaderSymbols(RecognizedLine word) {
  final symbols = word.elements;
  final output = <RecognizedLine>[
    for (final symbol in symbols)
      if (RegExp(r'^[1-9]$').hasMatch(symbol.text)) symbol,
  ];
  for (var i = 0; i + 1 < symbols.length; i++) {
    final a = symbols[i], b = symbols[i + 1];
    if (a.text != '1' ||
        b.text != '0' ||
        b.x < a.x + a.width * .7 ||
        b.x - a.x - a.width > math.max(a.width, b.width) ||
        (a.centerY - b.centerY).abs() > math.min(a.height, b.height) * .35) {
      continue;
    }
    output.add(
      RecognizedLine(
        text: '10',
        x: a.x,
        y: math.min(a.y, b.y),
        width: b.x + b.width - a.x,
        height: math.max(a.y + a.height, b.y + b.height) - math.min(a.y, b.y),
      ),
    );
  }
  return output;
}
