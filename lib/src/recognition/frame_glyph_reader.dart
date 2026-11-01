import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/scoring.dart';
import 'recognized_text.dart';
import 'scoreboard_name.dart';
import 'scoreboard_ink.dart';
import 'scoreboard_grid.dart';

/// Conservative local fallback for separated delivery cells on monitor grids.
/// Templates classify photographed ink; score totals only validate the result.
abstract final class FrameGlyphReader {
  static Future<List<_Template>>? _templates;
  static String _name(String s) => normalizedBowlerName(s);

  static Future<List<RecognizedLine>> read(
    Uint8List bytes,
    List<RecognizedLine> lines,
    BowlerProfile profile, {
    List<List<RecognizedLine>> alternatives = const [],
    List<RecognizedLine> supplemental = const [],
  }) async {
    final sources = [
      lines,
      ...alternatives.where((s) => !identical(s, lines)).take(3),
    ];
    final layouts = [for (final source in sources) ..._tables(source, profile)];
    if (layouts.isEmpty) return [];
    final supportingWords = _distinctWords([
      ...sources.expand((s) => s),
      ...supplemental,
    ]);
    final templates = await (_templates ??= _loadTemplates());
    // Flutter's codec applies EXIF orientation, matching both native bridges.
    final image = await _decode(bytes);
    try {
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final output = <RecognizedLine>[];
      final wordReadings = sources.map(_distinctWords).toList();
      final imageWidth = image.width, imageHeight = image.height;
      for (final table in layouts) {
        // Align once per observed layout and transfer the raster only once
        // for all text passes. At most sixteen layouts and four readings exist;
        // each layout can have two independently confirmed ruling polarities.
        final readings = await Isolate.run(() {
          final results = <(_Table, List<List<String>>)>[];
          for (final aligned in _columnAlignments(
            rgba,
            imageWidth,
            imageHeight,
            table,
          )) {
            if (table.headers < 6 && identical(aligned, table)) continue;
            final white = _inkWhitePoint(
              rgba,
              imageWidth,
              imageHeight,
              aligned,
            );
            results.add((
              aligned,
              [
                for (final words in wordReadings)
                  _readFrames(
                    rgba,
                    imageWidth,
                    imageHeight,
                    aligned,
                    words,
                    templates,
                    supportingWords,
                    white,
                  ),
              ],
            ));
            if (white != null) {
              // Keep the established neutral-ink row as an independent
              // candidate. A cast mask must not replace already readable ink;
              // each complete row is validated separately below.
              results.add((
                aligned,
                [
                  for (final words in wordReadings)
                    _readFrames(
                      rgba,
                      imageWidth,
                      imageHeight,
                      aligned,
                      words,
                      templates,
                      supportingWords,
                      null,
                    ),
                ],
              ));
            }
          }
          return results;
        });
        for (final reading in readings) {
          final aligned = reading.$1;
          for (
            var sourceIndex = 0;
            sourceIndex < sources.length;
            sourceIndex++
          ) {
            final source = sources[sourceIndex],
                words = wordReadings[sourceIndex];
            bool sameName(RecognizedLine w) =>
                _name(w.text) == _name(table.name.text) &&
                (w.centerX - table.name.centerX).abs() <
                    table.name.width * .5 &&
                (w.centerY - table.name.centerY).abs() <
                    table.name.height * .75;
            final hasName = words.any(sameName);
            final frames = reading.$2[sourceIndex];
            if (frames.length != 10 || !TenPinScorer.score(frames).complete) {
              continue;
            }
            final last = aligned.first + 9 * aligned.pitch;
            final directTotals = _scratchTotals(words, aligned);
            final checkpoints = ScoreboardGrid.rows(source, profile)
                .where(
                  (r) =>
                      r.suggested &&
                      r.cumulativeTotals != null &&
                      table.name.centerY >= r.y &&
                      table.name.centerY <= r.y + r.height,
                )
                .firstOrNull
                ?.cumulativeTotals;
            final score = TenPinScorer.score(frames);
            final observedCheckpoints = _checkpoints(words, aligned);
            if (observedCheckpoints == null ||
                List.generate(10, (i) => i).any(
                  (i) =>
                      observedCheckpoints[i] != null &&
                      observedCheckpoints[i] != score.cumulative[i],
                )) {
              continue;
            }
            // A native pass can omit the large player name while retaining
            // the complete score band. Bind it to another named pass only with
            // six agreeing checkpoints in each, including the tenth. An
            // explicit different name at this position remains a conflict.
            if (!hasName) {
              final conflictingName = words.any(
                (w) =>
                    RegExp(r'\p{L}', unicode: true).hasMatch(w.text) &&
                    (w.centerX - table.name.centerX).abs() <
                        table.name.width * .5 &&
                    (w.centerY - table.name.centerY).abs() <
                        table.name.height * .75,
              );
              if (conflictingName ||
                  observedCheckpoints.whereType<int>().length < 6 ||
                  observedCheckpoints.last != score.total) {
                continue;
              }
              final namedSupport = sources.any((other) {
                final otherWords = _distinctWords(other);
                if (!otherWords.any(sameName)) return false;
                final checks = _checkpoints(otherWords, aligned);
                return checks != null &&
                    checks.whereType<int>().length >= 6 &&
                    checks.last == score.total &&
                    List.generate(10, (i) => i).every(
                      (i) =>
                          checks[i] == null || checks[i] == score.cumulative[i],
                    );
              });
              if (!namedSupport) continue;
            }
            // A total-only observation cannot become a new primary reading
            // merely because another pass located a grid. Require its own
            // name/header fit or three agreeing checkpoints including frame ten.
            final ownsLayout = _tables(
              source,
              profile,
            ).any((candidate) => sameName(candidate.name));
            if (!ownsLayout &&
                (observedCheckpoints.whereType<int>().length < 3 ||
                    observedCheckpoints.last != score.total)) {
              continue;
            }
            if (checkpoints != null &&
                List.generate(
                  10,
                  (i) => i,
                ).any((i) => score.cumulative[i] != checkpoints[i])) {
              continue;
            }
            int? total = directTotals
                .where((v) => v == score.total)
                .firstOrNull;
            // Another pass may supply an actual total for the same named row.
            // Keep six independently observed checkpoints including frame ten.
            // If the delivery pass has fewer, require the validation pass to
            // supply six and share at least three of the primary observations.
            if (total == null &&
                observedCheckpoints.whereType<int>().length >= 3 &&
                observedCheckpoints.last == score.total) {
              for (final other in sources) {
                final otherWords = _distinctWords(other);
                final sameName = otherWords.any(
                  (w) =>
                      _name(w.text) == _name(table.name.text) &&
                      (w.centerX - table.name.centerX).abs() <
                          table.name.width * .5 &&
                      (w.centerY - table.name.centerY).abs() <
                          table.name.height * .75,
                );
                if (!sameName) continue;
                if (observedCheckpoints.whereType<int>().length < 6) {
                  final otherChecks = _checkpoints(otherWords, aligned);
                  if (otherChecks == null ||
                      List.generate(10, (i) => i).any(
                        (i) =>
                            otherChecks[i] != null &&
                            otherChecks[i] != score.cumulative[i],
                      )) {
                    continue;
                  }
                  final shared = List.generate(10, (i) => i)
                      .where(
                        (i) =>
                            observedCheckpoints[i] != null &&
                            otherChecks[i] == observedCheckpoints[i],
                      )
                      .length;
                  if (otherChecks.whereType<int>().length < 6 ||
                      shared < 3 ||
                      otherChecks.last != score.total) {
                    continue;
                  }
                }
                total = _scratchTotals(
                  otherWords,
                  aligned,
                ).where((v) => v == score.total).firstOrNull;
                if (total != null) break;
              }
            }
            if (total == null) continue;
            // Alternative OCR passes can recover different omissions, but must
            // agree on the observed deliveries. Retain conflicting valid readings
            // as separate candidates so automatic selection remains disabled.
            if (output.any(
              (r) =>
                  (r.x - table.name.x).abs() < table.pitch * .5 &&
                  (r.frameRow!.frames.join('|') == frames.join('|')) &&
                  (r.y -
                              math.min(
                                aligned.y,
                                aligned.y + 9 * aligned.slope,
                              ) -
                              table.height * .5)
                          .abs() <
                      table.name.height * .5,
            )) {
              continue;
            }
            final top =
                math.min(aligned.y, aligned.y + 9 * aligned.slope) +
                table.height * .5;
            final bottom =
                math.max(aligned.rowY(aligned.first), aligned.rowY(last)) +
                table.name.height * .65;
            output.add(
              RecognizedLine(
                text: table.name.text,
                x: table.name.x,
                y: top,
                width: last - table.name.x + table.pitch,
                height: bottom - top,
                frameRow: ScoreRow(
                  text: '${table.name.text} · $total',
                  frames: frames,
                  suggested: true,
                  y: top,
                  height: bottom - top,
                  displayedTotal: total,
                  cumulativeTotals: observedCheckpoints.every((v) => v != null)
                      ? observedCheckpoints.cast<int>()
                      : checkpoints,
                ),
              ),
            );
          }
        }
      }
      return output;
    } finally {
      image.dispose();
    }
  }

  /// Last bounded native retry when text alone cannot locate delivery cells.
  static Future<List<RecognitionRegion>> regions(
    Uint8List bytes,
    List<List<RecognizedLine>> readings,
    BowlerProfile profile,
  ) async {
    final tables = [for (final source in readings) ..._tables(source, profile)];
    if (tables.isEmpty) return [];
    final ordered = tables.indexed.toList()
      ..sort((a, b) {
        final support = b.$2.headers.compareTo(a.$2.headers);
        return support != 0 ? support : a.$1.compareTo(b.$1);
      });
    final image = await _decode(bytes);
    try {
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final width = image.width, height = image.height;
      return await Isolate.run(() {
        // A repeated name in a footer can have more readable headers than
        // the player row. Rank only layouts whose rulings actually align;
        // an unsupported footer must not hide a supported row in another pass.
        for (final candidate in ordered) {
          final table = candidate.$2;
          final aligned = _alignColumns(rgba, width, height, table);
          if (identical(aligned, table)) continue;
          final regions = [for (var i = 0; i < 10; i++) _region(aligned, i)];
          if (regions.every(
            (r) =>
                r.width > 0 &&
                r.height > 0 &&
                r.x >= 0 &&
                r.y >= 0 &&
                r.x + r.width <= 1 &&
                r.y + r.height <= 1,
          )) {
            return regions;
          }
        }
        return <RecognitionRegion>[];
      });
    } finally {
      image.dispose();
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale = math.min(
        1.0,
        4096 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      return (await codec.getNextFrame()).image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static RecognitionRegion _region(_Table table, int i) {
    final center = table.first + i * table.pitch;
    final headerY = table.y + i * table.slope;
    final gap = table.rowY(center) - headerY;
    // Native header boxes can include extra vertical whitespace. Keep them
    // from cutting the top off a delivery immediately beneath the header.
    final inset = math.min(table.height * .55, gap * .2);
    return RecognitionRegion(
      center - table.pitch * .47,
      headerY + inset,
      table.pitch * .94,
      gap * .9 - inset,
      tenth: i == 9,
    );
  }

  static List<_Table> _tables(
    List<RecognizedLine> lines,
    BowlerProfile profile,
  ) {
    final words = _distinctWords(lines);
    final aliases = [
      profile.name,
      ...profile.aliases,
    ].map(_name).where((s) => s.isNotEmpty).toSet();
    final names = words.where((w) => aliases.contains(_name(w.text))).toList();
    if (names.length > 2) return [];
    final tables = <_Table>[];
    for (final name in names) {
      final headerWords = [
        ...words,
        // ML Kit can merge several numbered cells and their vertical borders.
        // Real symbol boxes retain the header positions even in that word.
        for (final line in lines)
          for (final word in line.elements)
            if ('|'.allMatches(word.text).length >= 2 &&
                word.elements.isNotEmpty)
              ...ScoreboardGrid.symbols(word),
      ];
      final headers = headerWords.where((w) {
        final n = int.tryParse(w.text);
        return n != null &&
            n >= 1 &&
            n <= 10 &&
            w.centerX > name.x + name.width &&
            name.centerY - w.centerY > name.height * .35 &&
            name.centerY - w.centerY < name.height * 6;
      }).toList();
      _Table? table;
      _Table? firstFit;
      var longestSpan = 0;
      for (final a in headers) {
        for (final b in headers) {
          final ai = int.parse(a.text) - 1, bi = int.parse(b.text) - 1;
          if (bi - ai < 3) continue;
          final pitch = (b.centerX - a.centerX) / (bi - ai);
          if (pitch <= 0 ||
              pitch > .1 ||
              ((b.centerY - a.centerY) / (b.centerX - a.centerX)).abs() > .5) {
            continue;
          }
          final first = a.centerX - ai * pitch;
          final matches = headers.where((w) {
            final i = int.parse(w.text) - 1;
            final y =
                a.centerY + (b.centerY - a.centerY) * (i - ai) / (bi - ai);
            return (w.centerX - first - i * pitch).abs() < pitch * .15 &&
                (w.centerY - y).abs() < math.max(a.height, b.height) * .7;
          }).toList();
          final distinctHeaders = matches.map((w) => w.text).toSet().length;
          if (distinctHeaders < 3) continue;
          if (table == null ||
              distinctHeaders > table.headers ||
              (distinctHeaders == table.headers && bi - ai > longestSpan)) {
            longestSpan = bi - ai;
            final heights = matches.map((w) => w.height).toList()..sort();
            table = _Table(
              name,
              first,
              pitch,
              a.centerY - ai * (b.centerY - a.centerY) / (bi - ai),
              (b.centerY - a.centerY) / (bi - ai),
              heights[heights.length ~/ 2],
              distinctHeaders,
            );
          }
          // Keep the first broadly supported fit for native cell crops. Small
          // endpoint changes can affect OCR even when both fits locate the same
          // rulings. The longest-span alternative remains available to pixels.
          if (bi - ai >= 5 &&
              (firstFit == null || distinctHeaders > firstFit.headers)) {
            final heights = matches.map((w) => w.height).toList()..sort();
            firstFit = _Table(
              name,
              first,
              pitch,
              a.centerY - ai * (b.centerY - a.centerY) / (bi - ai),
              (b.centerY - a.centerY) / (bi - ai),
              heights[heights.length ~/ 2],
              distinctHeaders,
            );
          }
        }
      }
      if (firstFit != null) tables.add(firstFit);
      if (table != null &&
          (firstFit == null ||
              firstFit.first != table.first ||
              firstFit.pitch != table.pitch ||
              firstFit.y != table.y ||
              firstFit.slope != table.slope)) {
        tables.add(table);
      }
    }
    return tables;
  }

  static List<int?>? _checkpoints(List<RecognizedLine> words, _Table table) {
    final result = <int?>[];
    for (var i = 0; i < 10; i++) {
      final center = table.first + i * table.pitch;
      final rowY = table.rowY(center);
      final gap = rowY - (table.y + i * table.slope);
      final values = words
          .where(
            (w) =>
                (w.centerX - center).abs() < table.pitch * .45 &&
                w.centerY > rowY - gap * .2 &&
                w.centerY < rowY + gap * .65 &&
                RegExp(r'^\d{1,3}$').hasMatch(w.text),
          )
          .toList();
      if (values.length > 1) return null;
      result.add(values.isEmpty ? null : int.parse(values.single.text));
    }
    return result;
  }

  static List<int> _scratchTotals(List<RecognizedLine> words, _Table table) {
    final last = table.first + 9 * table.pitch;
    final totals = words
        .where(
          (w) =>
              w.centerX > last + table.pitch * .55 &&
              w.centerX < last + table.pitch * 3 &&
              (w.centerY - table.rowY(w.centerX)).abs() <
                  table.name.height * .8 &&
              RegExp(r'^\d{1,3}$').hasMatch(w.text),
        )
        .toList();
    // A labeled handicap column is separate from the first, scratch column.
    // Permit the common OCR c/e confusion in the label, never in score digits.
    final handicapHeader = words.any(
      (w) =>
          w.x > last &&
          RegExp(
            r'h(?:[da][ce]p|andicap)$',
            caseSensitive: false,
          ).hasMatch(w.text) &&
          (w.centerY - table.y - 9 * table.slope).abs() < table.height,
    );
    if (totals.length > 1 && !handicapHeader) return [];
    final scratch = totals
        .where((w) => w.centerX < last + table.pitch * 2.3)
        .toList();
    if (scratch.length != 1) return [];
    final value = int.parse(scratch.single.text);
    return value <= 300 ? [value] : [];
  }

  // ML Kit can report the same ink twice in overlapping text blocks. Collapse
  // only matching words whose boxes substantially overlap; distinct values
  // in a score cell must still trigger a conflict.
  static List<RecognizedLine> _distinctWords(List<RecognizedLine> lines) {
    final result = <RecognizedLine>[];
    final byText = <String, List<RecognizedLine>>{};
    for (final word in lines.expand(ScoreboardGrid.words)) {
      final previous = byText.putIfAbsent(word.text, () => []);
      if (previous.any((other) {
        final w = math.max(
          0.0,
          math.min(word.x + word.width, other.x + other.width) -
              math.max(word.x, other.x),
        );
        final h = math.max(
          0.0,
          math.min(word.y + word.height, other.y + other.height) -
              math.max(word.y, other.y),
        );
        return w * h >
            math.min(word.width * word.height, other.width * other.height) *
                .65;
      })) {
        continue;
      }
      previous.add(word);
      result.add(word);
    }
    return result;
  }

  /// A shared reference keeps a bright background patch in one cell from
  /// redefining the foreground color for that delivery. Never uses OCR values.
  static List<int>? _inkWhitePoint(
    Uint8List rgba,
    int width,
    int height,
    _Table table,
  ) {
    final histogram = List.generate(3, (_) => List.filled(256, 0));
    var count = 0;
    for (var i = 0; i < 10; i++) {
      final region = _region(table, i);
      final x = (region.x * width).round(), y = (region.y * height).round();
      final w = (region.width * width).round(),
          h = (region.height * height).round();
      if (x < 0 || y < 0 || x + w > width || y + h > height) return null;
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final p = ((y + py) * width + x + px) * 4;
          if (rgba[p + 3] < 165) continue;
          for (var channel = 0; channel < 3; channel++) {
            histogram[channel][rgba[p + channel]]++;
          }
          count++;
        }
      }
    }
    if (count == 0) return null;
    final white = <int>[];
    for (final channel in histogram) {
      var seen = 0;
      for (var value = 0; value < 256; value++) {
        seen += channel[value];
        if (seen >= count * .95) {
          white.add(value);
          break;
        }
      }
    }
    final low = white.reduce(math.min), high = white.reduce(math.max);
    return low >= 140 && high - low >= 45 ? white : null;
  }

  static List<String> _readFrames(
    Uint8List rgba,
    int imageWidth,
    int imageHeight,
    _Table table,
    List<RecognizedLine> words,
    List<_Template> templates,
    List<RecognizedLine> supportingWords,
    List<int>? white,
  ) {
    final frames = <String>[];
    for (var i = 0; i < 10; i++) {
      final region = _region(table, i);
      if (region.x < 0 ||
          region.y < 0 ||
          region.x + region.width > 1 ||
          region.y + region.height > 1) {
        break;
      }
      final x = (region.x * imageWidth).round(),
          y = (region.y * imageHeight).round();
      final w = (region.width * imageWidth).round(),
          h = (region.height * imageHeight).round();
      final mask = Uint8List(w * h),
          neutralMask = Uint8List(w * h),
          strictMask = Uint8List(w * h);
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final p = ((y + py) * imageWidth + x + px) * 4;
          final low = math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2]));
          final high = math.max(rgba[p], math.max(rgba[p + 1], rgba[p + 2]));
          final greenInk =
              rgba[p + 1] >= 140 &&
              rgba[p + 1] - rgba[p] >= 60 &&
              rgba[p + 1] - rgba[p + 2] >= 40;
          if (rgba[p + 3] >= 165 &&
              ((low >= 140 && high - low <= 110) || greenInk)) {
            mask[py * w + px] = 1;
            if (high - low <= 50 || greenInk) neutralMask[py * w + px] = 1;
            if (high - low <= 25 || greenInk) strictMask[py * w + px] = 1;
          }
        }
      }
      final observations = [
        for (final word in words) ...ScoreboardGrid.symbols(word),
      ].where(region.contains).toList();
      final supporting = [
        for (final word in supportingWords) ...ScoreboardGrid.symbols(word),
      ].where((s) => !s.isStroke && region.contains(s)).toList();
      final nativeMarks =
          observations
              .where(
                (s) =>
                    !s.isStroke &&
                    RegExp(
                      r'^[0-9XF/×–—\-]$',
                      caseSensitive: false,
                    ).hasMatch(s.text),
              )
              .toList()
            ..sort((a, b) => a.x.compareTo(b.x));
      final nativeFrame = nativeMarks
          .map((s) => s.text)
          .join()
          .toUpperCase()
          .replaceAll('×', 'X')
          .replaceAll('–', '-')
          .replaceAll('—', '-');
      // Determine delivery order from photographed components. Word-level
      // OCR can spread a merged token across frame boundaries and reverse a
      // miss and digit while preserving the same cumulative and final score.
      String classify(Uint8List pixels) => _classify(
        pixels,
        w,
        h,
        templates,
        observed: (l, t, r, b) =>
            _inside(observations, imageWidth, imageHeight, x, y, l, t, r, b),
        supporting: (l, t, r, b) =>
            _inside(supporting, imageWidth, imageHeight, x, y, l, t, r, b),
      );
      String? corrected;
      if (white != null) {
        // The row's measured light ink can carry a strong monitor/camera cast.
        // Progressively retain more of that ink, never choosing by a score.
        for (final levels in [(.85, .12), (.75, .3), (.65, .5)]) {
          final pixels = Uint8List(w * h);
          for (var py = 0; py < h; py++) {
            for (var px = 0; px < w; px++) {
              final p = ((y + py) * imageWidth + x + px) * 4;
              final r = rgba[p] / white[0],
                  g = rgba[p + 1] / white[1],
                  b = rgba[p + 2] / white[2];
              final low = math.min(r, math.min(g, b));
              final high = math.max(r, math.max(g, b));
              if (rgba[p + 3] >= 165 &&
                  low >= levels.$1 &&
                  high - low < levels.$2) {
                pixels[py * w + px] = 1;
              }
            }
          }
          // Outlined lettering is separated from the illustration behind it.
          // Edge-connected decoration cannot be an intact photographed glyph.
          String readCorrected(Uint8List input) => _classify(
            input,
            w,
            h,
            templates,
            outlined: true,
            supporting: (l, t, r, b) =>
                _inside(supporting, imageWidth, imageHeight, x, y, l, t, r, b),
          );
          final cleaned = withoutEdgeConnectedInk(pixels, w, h);
          var candidate = readCorrected(cleaned);
          if (!TenPinScorer.parseFrame(candidate, tenth: i == 9).complete) {
            continue;
          }
          // A legal primary observation, even a partial frame, must remain
          // present. Pixel ordering can repair merged-word order, but cannot
          // replace its delivery values. Invalid merged tokens do not validate
          // a frame; the corrected ink still needs full template confidence.
          if (TenPinScorer.parseFrame(nativeFrame, tenth: i == 9).error ==
              null) {
            final remaining = candidate.split('');
            var agrees = true;
            for (final mark in nativeFrame.split('')) {
              if (!remaining.remove(mark)) agrees = false;
            }
            if (!agrees) continue;
          }
          corrected = candidate;
          break;
        }
      }
      var physical = corrected ?? classify(mask);
      // Do not discard readable ink. Only when the broad mask is incomplete,
      // progressively exclude colored decoration; each attempt still reads
      // the photographed components and preserves primary native characters.
      for (final pixels in [neutralMask, strictMask]) {
        if (TenPinScorer.parseFrame(physical, tenth: i == 9).complete) break;
        final candidate = classify(pixels);
        if (TenPinScorer.parseFrame(candidate, tenth: i == 9).complete) {
          physical = candidate;
        }
      }
      // Bright grid edges can connect into an oversized component. Preserve
      // every previously complete physical or native reading; only retry an
      // otherwise incomplete cell after measuring/removing boundary rulings.
      if (!TenPinScorer.parseFrame(physical, tenth: i == 9).complete &&
          !TenPinScorer.parseFrame(nativeFrame, tenth: i == 9).complete) {
        for (final pixels in [mask, neutralMask, strictMask]) {
          final cleaned = withoutBoundaryRulings(pixels, w, h);
          if (identical(cleaned, pixels)) continue;
          final candidate = classify(cleaned);
          if (TenPinScorer.parseFrame(candidate, tenth: i == 9).complete) {
            physical = candidate;
            break;
          }
        }
      }
      // Prefer a complete physical ordering when available. A complete native
      // reading can still preserve ink obscured by a monitor graphic when the
      // raster classifier cannot complete the cell.
      frames.add(
        TenPinScorer.parseFrame(physical, tenth: i == 9).complete ||
                !TenPinScorer.parseFrame(nativeFrame, tenth: i == 9).complete
            ? physical
            : nativeFrame,
      );
    }
    return frames;
  }

  static List<MapEntry<String, double>> _rankGlyph(
    _Component c,
    int w,
    int h,
    List<_Template> templates,
  ) {
    final gw = c.r - c.l, gh = c.b - c.t;
    final componentMask = Uint8List(w * h);
    for (final p in c.pixels) {
      componentMask[p] = 1;
    }
    final normalized = Uint8List(24 * 32);
    for (var yy = 0; yy < 32; yy++) {
      for (var xx = 0; xx < 24; xx++) {
        final sx = (c.l + (xx + .5) * gw / 24 - .5).clamp(
          c.l.toDouble(),
          (c.r - 1).toDouble(),
        );
        final sy = (c.t + (yy + .5) * gh / 32 - .5).clamp(
          c.t.toDouble(),
          (c.b - 1).toDouble(),
        );
        final x0 = sx.floor(),
            y0 = sy.floor(),
            x1 = math.min(c.r - 1, x0 + 1),
            y1 = math.min(c.b - 1, y0 + 1);
        final dx = sx - x0, dy = sy - y0;
        final value =
            componentMask[y0 * w + x0] * (1 - dx) * (1 - dy) +
            componentMask[y0 * w + x1] * dx * (1 - dy) +
            componentMask[y1 * w + x0] * (1 - dx) * dy +
            componentMask[y1 * w + x1] * dx * dy;
        if (value > .5) normalized[yy * 24 + xx] = 1;
      }
    }
    final scores = <String, double>{};
    for (final template in templates) {
      var intersection = 0, union = 0;
      for (var p = 0; p < normalized.length; p++) {
        if (normalized[p] != 0 || template.mask[p] != 0) union++;
        if (normalized[p] != 0 && template.mask[p] != 0) intersection++;
      }
      final score = intersection / union;
      scores[template.text] = math.max(scores[template.text] ?? 0, score);
    }
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked;
  }

  static Set<String> _inside(
    List<RecognizedLine> input,
    int imageWidth,
    int imageHeight,
    int x,
    int y,
    int l,
    int t,
    int r,
    int b,
  ) => input
      .where((o) {
        final ox = o.centerX * imageWidth - x, oy = o.centerY * imageHeight - y;
        return ox >= l - 3 && ox <= r + 3 && oy >= t - 3 && oy <= b + 3;
      })
      .map((o) => o.text.toUpperCase())
      .toSet();

  /// Header numerals may be right-aligned rather than centered in their cells.
  /// Locate repeated dark rulings in the photographed row before reading ink.
  /// An 85th percentile rejects isolated character outlines and short misses;
  /// a ruling must stay dark over nearly the entire header/player band.
  static _Table _alignColumns(
    Uint8List rgba,
    int width,
    int height,
    _Table table,
  ) => _columnAlignments(rgba, width, height, table).first;

  static List<_Table> _columnAlignments(
    Uint8List rgba,
    int width,
    int height,
    _Table table,
  ) {
    final darkPhases = <(double, int, int)>[],
        lightPhases = <(double, int, int)>[];
    for (var i = 0; i < 9; i++) {
      final center = table.first + i * table.pitch;
      final headerY = table.y + i * table.slope;
      final gap = table.rowY(center) - headerY;
      final left = ((center + table.pitch * .05) * width).round();
      final right = ((center + table.pitch * .9) * width).round();
      final top = ((headerY + table.height * .65) * height).round();
      final bottom = ((headerY + gap * 1.3) * height).round();
      if (left < 0 ||
          right >= width ||
          top < 0 ||
          bottom > height ||
          bottom <= top) {
        continue;
      }
      // A photographed vertical ruling can lean. Score a bounded family of
      // straight lines, anchored at the delivery band's middle, rather than
      // requiring every ruling to remain in one image column.
      final anchor = headerY * height + gap * height * .5;
      final values = <int>[], lightValues = <int>[];
      for (var x = left; x < right; x++) {
        var darkest = 255, brightest = 0;
        for (final shear in [-.15, -.1, -.05, 0.0, .05, .1, .15]) {
          final samples = <int>[], lightSamples = <int>[];
          for (var sample = 0; sample < 32; sample++) {
            final y = top + ((bottom - top - 1) * sample / 31).round();
            final xx = (x + (y - anchor) * shear).round();
            if (xx < 0 || xx >= width) {
              samples.add(255);
              lightSamples.add(0);
              continue;
            }
            final p = (y * width + xx) * 4;
            samples.add(math.max(rgba[p], math.max(rgba[p + 1], rgba[p + 2])));
            lightSamples.add(
              math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2])),
            );
          }
          samples.sort();
          darkest = math.min(darkest, samples[27]);
          lightSamples.sort();
          brightest = math.max(brightest, lightSamples[4]);
        }
        values.add(darkest);
        lightValues.add(brightest);
      }
      if (values.isEmpty) continue;
      final sorted = [...values]..sort();
      final dark = sorted.first, background = sorted[sorted.length ~/ 2];
      if (background - dark >= math.max(8, background * .08)) {
        final x = left + values.indexOf(dark);
        darkPhases.add((
          (x / width - center) / table.pitch,
          background - dark,
          i,
        ));
      }
      final lightSorted = [...lightValues]..sort();
      final bright = lightSorted.last,
          lightBackground = lightSorted[lightSorted.length ~/ 2];
      if (bright >= 90 &&
          bright - lightBackground >= math.max(12, bright * .08)) {
        final x = left + lightValues.indexOf(bright);
        lightPhases.add((
          (x / width - center) / table.pitch,
          bright - lightBackground,
          i,
        ));
      }
    }
    final winners = <(double, int, double)>[];
    for (final family in [darkPhases, lightPhases]) {
      if (family.length < 6) continue;
      family.sort((a, b) => a.$1.compareTo(b.$1));
      // Dense native headers already establish the pitch. Preserve those
      // readings; only sparse-header layouts need ruling-derived spacing.
      final spacing = table.headers < 6 ? _rulingSpacing(family) : null;
      final phase = spacing?.$1 ?? family[family.length ~/ 2].$1;
      final drift = spacing?.$2 ?? 0.0;
      final agreeing = family
          .where(
            (p) =>
                (p.$1 - phase - drift * p.$3).abs() <
                (spacing == null ? .1 : .035),
          )
          .toList();
      if (agreeing.length < 6) continue;
      final contrasts = agreeing.map((p) => p.$2).toList()..sort();
      final contrast = contrasts[contrasts.length ~/ 2];
      winners.add((phase, contrast, 1 + drift));
    }
    if (winners.isEmpty) return [table];
    winners.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final winner in winners)
        _Table(
          table.name,
          table.first + (winner.$1 - winner.$3 * .5) * table.pitch,
          table.pitch * winner.$3,
          table.y + (winner.$1 - winner.$3 * .5) * table.slope,
          table.slope * winner.$3,
          table.height,
          table.headers,
        ),
    ];
  }

  /// Sparse OCR headers can slightly compress the column pitch. Accept a
  /// spacing correction only when six photographed rulings independently show
  /// the same small linear drift across at least five column intervals.
  static (double, double)? _rulingSpacing(List<(double, int, int)> family) {
    List<(double, int, int)> best = [];
    var bestError = double.infinity;
    for (final a in family) {
      for (final b in family) {
        if (b.$3 - a.$3 < 5) continue;
        final drift = (b.$1 - a.$1) / (b.$3 - a.$3);
        if (drift.abs() < .005 || drift.abs() > .05) continue;
        final first = a.$1 - a.$3 * drift;
        final matches = family
            .where((p) => (p.$1 - first - p.$3 * drift).abs() < .035)
            .toList();
        if (matches.length < 6) continue;
        final error = matches.fold(
          0.0,
          (v, p) => v + (p.$1 - first - p.$3 * drift).abs(),
        );
        if (matches.length > best.length ||
            (matches.length == best.length && error < bestError)) {
          best = matches;
          bestError = error;
        }
      }
    }
    if (best.length < 6) return null;
    final meanX = best.fold(0.0, (v, p) => v + p.$3) / best.length;
    final meanY = best.fold(0.0, (v, p) => v + p.$1) / best.length;
    var covariance = 0.0, variance = 0.0;
    for (final p in best) {
      covariance += (p.$3 - meanX) * (p.$1 - meanY);
      variance += (p.$3 - meanX) * (p.$3 - meanX);
    }
    final drift = covariance / variance;
    if (drift.abs() < .005 || drift.abs() > .05) return null;
    return (meanY - drift * meanX, drift);
  }

  static Future<List<_Template>> _loadTemplates() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/recognition/glyphs.json'),
    ) as Map;
    return [
      for (final v in data['variants'] as List)
        _Template(
          v['text'] as String,
          Uint8List.fromList(
            (v['mask'] as String).codeUnits
                .map((c) => c == 49 ? 1 : 0)
                .toList(),
          ),
        ),
    ];
  }

  /// Exposed for deterministic raster regression tests. Unknown ink stays blank.
  static String _classify(
    Uint8List mask,
    int w,
    int h,
    List<_Template> templates, {
    bool outlined = false,
    Set<String> Function(int, int, int, int)? observed,
    Set<String> Function(int, int, int, int)? supporting,
  }) {
    final seen = Uint8List(mask.length), components = <_Component>[];
    for (var seed = 0; seed < mask.length; seed++) {
      if (mask[seed] == 0 || seen[seed] != 0) continue;
      final pixels = <int>[seed];
      seen[seed] = 1;
      var l = seed % w, r = l, t = seed ~/ w, b = t;
      for (var q = 0; q < pixels.length; q++) {
        final p = pixels[q], x = p % w, y = p ~/ w;
        l = math.min(l, x);
        r = math.max(r, x);
        t = math.min(t, y);
        b = math.max(b, y);
        for (final n in [
          if (x > 0) p - 1,
          if (x + 1 < w) p + 1,
          if (y > 0) p - w,
          if (y + 1 < h) p + w,
        ]) {
          if (mask[n] != 0 && seen[n] == 0) {
            seen[n] = 1;
            pixels.add(n);
          }
        }
      }
      if (pixels.length >= 5) {
        components.add(_Component(l, t, r + 1, b + 1, pixels));
      }
    }
    final rankings = <_Component, List<MapEntry<String, double>>>{};
    List<MapEntry<String, double>> ranking(_Component c) =>
        rankings.putIfAbsent(c, () => _rankGlyph(c, w, h, templates));
    bool encloses(_Component outer, _Component inner) =>
        outer.l <= inner.l - 2 &&
        outer.t <= inner.t - 2 &&
        outer.r >= inner.r + 2 &&
        outer.b >= inner.b + 2;
    final List<_Component> glyphs;
    if (!outlined) {
      // Retain the established behavior for neutral-ink readings.
      glyphs = components
          .where((c) => !components.any((d) => encloses(c, d)))
          .toList();
    } else {
      final rings = <_Component>{};
      for (final outer in components) {
        for (final inner in components) {
          if (!encloses(outer, inner) ||
              inner.b - inner.t < (outer.b - outer.t) * .45 ||
              inner.r - inner.l < (outer.r - outer.l) * .25) {
            continue;
          }
          final gh = inner.b - inner.t, gw = inner.r - inner.l;
          if (gh < h * .22 || gh > h * .92 || gw > w * .65) continue;
          final ranked = ranking(inner);
          // A real split ring encloses a readable digit. A bright island inside
          // an outlined 0/8/9 (or decoration inside a 2) is a background counter,
          // not another digit. Keep the same uncorroborated glyph thresholds.
          if (RegExp(r'^[0-9]$').hasMatch(ranked.first.key) &&
              ranked.first.value >= .68 &&
              ranked.first.value - ranked[1].value >= .06) {
            rings.add(outer);
          }
        }
      }
      glyphs =
          components
              .where(
                (c) =>
                    !rings.contains(c) &&
                    !components.any(
                      (parent) =>
                          !rings.contains(parent) && encloses(parent, c),
                    ),
              )
              .toList()
            ..sort((a, b) => a.l.compareTo(b.l));
    }
    glyphs.sort((a, b) => a.l.compareTo(b.l));
    final result = StringBuffer();
    for (final c in glyphs) {
      final gw = c.r - c.l, gh = c.b - c.t;
      if (gw < 3 || gh < 2 || c.pixels.length < math.max(5, w * h * .0003)) {
        continue;
      }
      final ratio = gw / gh;
      if (ratio >= 1.2 &&
          ratio <= 8 &&
          gh < h * .3 &&
          (ratio >= 1.6 || c.pixels.length / (gw * gh) >= .7) &&
          (c.t + c.b) / 2 > h * .2 &&
          (c.t + c.b) / 2 < h * .8) {
        result.write('-');
        continue;
      }
      if (gh < h * .22) continue;
      if (gh > h * .92 || gw > w * .65) return '';
      final ranked = ranking(c);
      final best = ranked.first;
      final native = observed?.call(c.l, c.t, c.r, c.b) ?? <String>{};
      final known = native
          .where((s) => RegExp(r'^[0-9XF/]$').hasMatch(s))
          .toSet();
      // Fill omissions; keep an independently observed native character in
      // this component even when thresholding has broken its photographed ink.
      if (known.length == 1) {
        result.write(known.single);
        continue;
      }
      // Native OCR occasionally emits lookalike Cyrillic letters in a numeric
      // cell. Use this only as independent corroboration of the pixel winner,
      // never as a global name/text substitution or a score-derived guess.
      final corroborated = native
          .map((s) => const {'З': '3', 'Х': 'X'}[s])
          .whereType<String>()
          .toSet();
      if (known.isEmpty &&
          corroborated.length == 1 &&
          corroborated.single == best.key &&
          best.value >= .68) {
        result.write(best.key);
        continue;
      }
      final support = (supporting?.call(c.l, c.t, c.r, c.b) ?? <String>{})
          .map((s) => const {'З': '3', 'Х': 'X'}[s] ?? s)
          .where((s) => RegExp(r'^[0-9XF/]$').hasMatch(s))
          .toSet();
      // A secondary pass can corroborate the pixel winner, but cannot replace
      // a different pixel winner or any character in the primary reading.
      if (known.isEmpty &&
          support.length == 1 &&
          support.single == best.key &&
          best.value >= .6) {
        result.write(best.key);
        continue;
      }
      if (known.length > 1 ||
          best.value < .68 ||
          best.value - ranked[1].value < .06) {
        return '';
      }
      result.write(best.key);
      if (result.length > 3) return '';
    }
    return result.toString();
  }
}

class _Template {
  const _Template(this.text, this.mask);
  final String text;
  final Uint8List mask;
}

class _Component {
  const _Component(this.l, this.t, this.r, this.b, this.pixels);
  final int l, t, r, b;
  final List<int> pixels;
}

class _Table {
  const _Table(
    this.name,
    this.first,
    this.pitch,
    this.y,
    this.slope,
    this.height,
    this.headers,
  );
  final RecognizedLine name;
  final double first, pitch, y, slope, height;
  final int headers;
  double rowY(double x) => name.centerY + (x - name.centerX) * slope / pitch;
}
