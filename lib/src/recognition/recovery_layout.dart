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
          word.height < headerHeight * 1.15) {
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
              above < height * 1.8 &&
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

  List<RecognizedLine> totals(
    List<RecognizedLine> words,
    double first,
    double pitch,
  ) {
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
                (w.centerX - header.centerX).abs() < pitch * .5 &&
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

  static int? _number(RecognizedLine w) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(w.text)) return null;
    final value = int.parse(w.text);
    return value <= 300 ? value : null;
  }
}

/// Join only observed adjacent name words that exactly spell a saved alias.
/// This never changes delivery text or guesses a missing letter.
List<RecognizedLine> recoveryNameWords(
  List<RecognizedLine> words,
  BowlerProfile profile,
) {
  final aliases = [
    profile.name,
    ...profile.aliases,
  ].map(normalizedBowlerName).where((n) => n.isNotEmpty).toSet();
  final output = [...words];
  final text = words
      .where((w) => RegExp(r'^[\p{L} ]+$', unicode: true).hasMatch(w.text))
      .toList();
  for (final a in text) {
    for (final b in text) {
      if (identical(a, b)) continue;
      final vertical =
          (a.x - b.x).abs() < math.max(a.width, b.width) * .3 &&
          b.y >= a.y + a.height * .7 &&
          b.y - a.y - a.height < math.max(a.height, b.height) * .7;
      final horizontal =
          (a.centerY - b.centerY).abs() < math.min(a.height, b.height) * .5 &&
          b.x >= a.x + a.width * .8 &&
          b.x - a.x - a.width < math.max(a.height, b.height);
      if ((!vertical && !horizontal) ||
          !aliases.contains(normalizedBowlerName('${a.text} ${b.text}'))) {
        continue;
      }
      final left = math.min(a.x, b.x), top = math.min(a.y, b.y);
      if (output.any(
        (w) =>
            normalizedBowlerName(w.text) ==
                normalizedBowlerName('${a.text} ${b.text}') &&
            (w.x - left).abs() < .001 &&
            (w.y - top).abs() < .001,
      )) {
        continue;
      }
      output.add(
        RecognizedLine(
          text: '${a.text} ${b.text}',
          x: left,
          y: top,
          width: math.max(a.x + a.width, b.x + b.width) - left,
          height: math.max(a.y + a.height, b.y + b.height) - top,
        ),
      );
    }
  }
  return output;
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
