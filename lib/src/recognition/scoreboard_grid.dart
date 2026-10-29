import 'dart:math' as math;

import '../domain/models.dart';
import '../domain/scoring.dart';
import 'recognized_text.dart';
import 'scoreboard_name.dart';

/// Associates the delivery band with the bowler's cumulative-score band.
/// Displayed checkpoints validate observed marks; they never generate rolls.
abstract final class ScoreboardGrid {
  static List<ScoreRow> rows(
    List<RecognizedLine> lines,
    BowlerProfile profile,
  ) => _read(lines, profile, null);

  static List<RecognitionRegion> regions(
    List<RecognizedLine> lines,
    BowlerProfile profile,
  ) {
    final proposals = <(ScoreRow, List<RecognitionRegion>)>[];
    _read(lines, profile, proposals);
    final matching = proposals.where((p) => p.$1.suggested).toList();
    return [
      for (final p in (matching.isNotEmpty ? matching : proposals))
        if (!p.$1.extracted || p.$1.hasScoreConflict) ...p.$2,
    ].take(20).toList();
  }

  static List<ScoreRow> _read(
    List<RecognizedLine> lines,
    BowlerProfile profile,
    List<(ScoreRow, List<RecognitionRegion>)>? proposals,
  ) {
    final words = [for (final line in lines) ..._words(line)];
    final numbers = words.where((w) => _number(w.text) != null).toList();
    final bands = <List<RecognizedLine>>[];
    for (final word
        in numbers..sort((a, b) => a.centerY.compareTo(b.centerY))) {
      final band = bands
          .where(
            (b) =>
                (b.first.centerY - word.centerY).abs() <
                math.min(b.first.height, word.height) * .7,
          )
          .firstOrNull;
      if (band == null) {
        bands.add([word]);
      } else {
        band.add(word);
      }
    }
    final results = <ScoreRow>[];
    for (final band in bands.where((b) => b.length >= 10)) {
      band.sort((a, b) => a.x.compareTo(b.x));
      final candidates = <ScoreRow>[];
      for (var start = 0; start <= band.length - 10; start++) {
        final cells = band.sublist(start, start + 10);
        final totals = cells.map((w) => _number(w.text)!).toList();
        if (totals.first > 30 ||
            List.generate(9, (i) => i).any(
              (i) =>
                  totals[i + 1] < totals[i] || totals[i + 1] - totals[i] > 30,
            )) {
          continue;
        }
        final pitch =
            (cells.last.x +
                cells.last.width -
                cells.first.x -
                cells.first.width) /
            9;
        if (pitch <= 0) continue;
        final right = cells.first.x + cells.first.width;
        if (List.generate(10, (i) => i).any(
          (i) =>
              (cells[i].x + cells[i].width - right - i * pitch).abs() >
              pitch * .24,
        )) {
          continue;
        }
        final heights = cells.map((c) => c.height).toList()..sort();
        final height = heights[5];
        final left = right - pitch * .86;
        final names = words
            .where(
              (w) =>
                  w.x + w.width < left &&
                  (w.centerY - cells.first.centerY).abs() < height * 1.2 &&
                  isBowlerNameCandidate(w.text),
            )
            .toList();
        if (names.isEmpty) continue;
        names.sort(
          (a, b) => (a.centerY - cells.first.centerY).abs().compareTo(
            (b.centerY - cells.first.centerY).abs(),
          ),
        );
        final nameAnchor = names.first;
        final nameWords =
            names
                .where(
                  (w) =>
                      (w.centerY - nameAnchor.centerY).abs() <
                      math.max(w.height, nameAnchor.height) * .6,
                )
                .toList()
              ..sort((a, b) => a.x.compareTo(b.x));
        final name = nameWords.map((w) => w.text).join(' ');
        final frames = List.filled(10, '');
        final markWords = words;
        for (var i = 0; i < 10; i++) {
          final end = right + i * pitch + pitch * .14;
          final begin = i == 0 ? left : right + (i - 1) * pitch + pitch * .14;
          final symbols = <RecognizedLine>[];
          for (final word in markWords) {
            for (final symbol in _symbols(word)) {
              if (!RegExp(
                r'^[0-9XF/×–—\-]$',
                caseSensitive: false,
              ).hasMatch(symbol.text)) {
                continue;
              }
              final above = cells[i].centerY - symbol.centerY;
              if (symbol.centerX >= begin &&
                  symbol.centerX < end &&
                  above > height * .55 &&
                  above < height * 1.9) {
                symbols.add(symbol);
              }
            }
          }
          symbols.sort((a, b) => a.x.compareTo(b.x));
          final marks = symbols
              .map((s) => s.text)
              .join()
              .toUpperCase()
              .replaceAll('×', 'X')
              .replaceAll('–', '-')
              .replaceAll('—', '-');
          final parsed = TenPinScorer.parseFrame(marks, tenth: i == 9);
          frames[i] = parsed.error == null ? parsed.notation : '';
        }
        final aliases = [
          profile.name,
          ...profile.aliases,
        ].map(_name).where((v) => v.isNotEmpty);
        final suggested = aliases.any(
          (a) =>
              _name(name) == a ||
              name.split(RegExp(r'\s+')).map(_name).contains(a),
        );
        final extraTotal = band
            .skip(start + 10)
            .where((w) => w.x > cells.last.x + cells.last.width)
            .firstOrNull;
        final top = math.min(nameAnchor.y, cells.first.y - height * 2.5);
        final bottom = cells.map((c) => c.y + c.height).reduce(math.max);
        final row = ScoreRow(
          text: '$name · ${totals.join(' ')}',
          frames: frames,
          suggested: suggested,
          y: top,
          height: bottom - top,
          displayedTotal: extraTotal == null
              ? totals.last
              : _number(extraTotal.text),
          cumulativeTotals: totals,
        );
        candidates.add(row);
        if (proposals != null) {
          final markBands = lines
              .where(
                (l) =>
                    l.width > pitch * 5 &&
                    RegExp(r'[X/\-]', caseSensitive: false).hasMatch(l.text) &&
                    cells.first.centerY - l.centerY > height * .55 &&
                    cells.first.centerY - l.centerY < height * 1.9,
              )
              .toList();
          final markBand = markBands.isEmpty ? null : markBands.first;
          final cropTop = markBand == null
              ? cells.first.y - height * 1.3
              : markBand.y - height * .1;
          final cropBottom = markBand == null
              ? cells.first.y
              : markBand.y + markBand.height + height * .1;
          var gridPitch = pitch;
          var gridRight = right;
          // Tall, narrow border glyphs are useful geometric anchors, but are
          // never accepted as bowling marks.
          final borders =
              [for (final w in words) ..._symbols(w)]
                  .where(
                    (w) =>
                        RegExp(r'^[\\|)]$').hasMatch(w.text) &&
                        w.width < pitch * .3 &&
                        w.centerY > cropTop &&
                        w.centerY < cropBottom &&
                        w.centerX >= right - pitch * .3 &&
                        w.centerX <= right + 9 * pitch,
                  )
                  .toList()
                ..sort((a, b) => a.x.compareTo(b.x));
          if (borders.length >= 2) {
            final first = borders.first, last = borders.last;
            final firstIndex = ((first.centerX - right) / pitch).round();
            final lastIndex = ((last.centerX - right) / pitch).round();
            if (lastIndex > firstIndex) {
              gridPitch =
                  (last.centerX - first.centerX) / (lastIndex - firstIndex);
              gridRight = first.centerX - firstIndex * gridPitch;
            }
          }
          final crops = <RecognitionRegion>[];
          final calculated = TenPinScorer.score(frames);
          for (var i = 0; i < 10; i++) {
            if (calculated.frames[i].complete &&
                !row.hasScoreConflict &&
                (calculated.cumulative[i] == null ||
                    calculated.cumulative[i] == totals[i])) {
              continue;
            }
            final x = (gridRight + (i - 1) * gridPitch - gridPitch * .025)
                .clamp(0.0, 1.0);
            final y = cropTop.clamp(0.0, 1.0);
            final width = math.min(gridPitch * 1.05, 1 - x);
            final cropHeight = math.min(cropBottom - y, 1 - y);
            if (width > 0 && cropHeight > 0) {
              crops.add(
                RecognitionRegion(x, y, width, cropHeight, tenth: i == 9),
              );
            }
          }
          proposals.add((row, crops));
        }
      }
      // Keep alternatives if geometry is ambiguous; auto-selection requires a
      // unique, complete, checkpoint-consistent name match at the caller.
      results.addAll(candidates);
    }
    return results;
  }

  static int? _number(String text) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(text)) return null;
    final value = int.parse(text);
    return value <= 300 ? value : null;
  }

  static String _name(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static Iterable<RecognizedLine> words(RecognizedLine line) => _words(line);

  static Iterable<RecognizedLine> _words(RecognizedLine line) {
    if (line.elements.isNotEmpty) return line.elements.expand(_gridWords);
    final matches = RegExp(r'\S+').allMatches(line.text);
    return [
      for (final m in matches)
        ..._gridWords(
          RecognizedLine(
            text: m.group(0)!,
            x: line.x + line.width * m.start / line.text.length,
            y: line.y,
            width: line.width * (m.end - m.start) / line.text.length,
            height: line.height,
          ),
        ),
    ];
  }

  // A vertical cell border is sometimes attached to a number, or joins two
  // neighboring cells into one OCR word. Preserve the observed symbols and
  // their bounds while separating only that explicit delimiter.
  static Iterable<RecognizedLine> _gridWords(RecognizedLine word) sync* {
    if (!word.text.contains('|')) {
      yield word;
      return;
    }
    var group = <RecognizedLine>[];
    RecognizedLine combined(List<RecognizedLine> symbols) {
      final left = symbols.map((s) => s.x).reduce(math.min);
      final top = symbols.map((s) => s.y).reduce(math.min);
      return RecognizedLine(
        text: symbols.map((s) => s.text).join(),
        x: left,
        y: top,
        width: symbols.map((s) => s.x + s.width).reduce(math.max) - left,
        height: symbols.map((s) => s.y + s.height).reduce(math.max) - top,
        elements: List.unmodifiable(symbols),
        confidence: word.confidence,
        isStroke: word.isStroke,
      );
    }

    for (final symbol in _symbols(word)) {
      if (symbol.text == '|') {
        if (group.isNotEmpty) yield combined(group);
        group = [];
      } else {
        group.add(symbol);
      }
    }
    if (group.isNotEmpty) yield combined(group);
  }

  static Iterable<RecognizedLine> symbols(RecognizedLine word) =>
      _symbols(word);

  static Iterable<RecognizedLine> _symbols(RecognizedLine word) {
    if (word.elements.isNotEmpty) return word.elements;
    if (word.text.length == 1) return [word];
    return [
      for (var i = 0; i < word.text.length; i++)
        RecognizedLine(
          text: word.text[i],
          x: word.x + word.width * i / word.text.length,
          y: word.y,
          width: word.width / word.text.length,
          height: word.height,
        ),
    ];
  }
}
