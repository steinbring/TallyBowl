import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/scoring.dart';
import 'recognized_text.dart';
import 'scoreboard_name.dart';
import 'scoreboard_ink.dart';
import 'scoreboard_grid.dart';
import 'recovery_layout.dart';
import 'merged_frame_headers.dart';

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
    bool recovery = false,
    bool deskew = false,
    bool extendDeliveryBand = false,
  }) async {
    var sources = [
      lines,
      ...alternatives.where((s) => !identical(s, lines)).take(3),
    ];
    // Native OCR can merge an entire heading strip. Only the final retry
    // separates a verified consecutive run at its photographed ink columns.
    if (extendDeliveryBand) sources = await _mergedHeaders(bytes, sources);
    final headerSupport = extendDeliveryBand
        ? _distinctWords(sources.expand((s) => s).toList())
        : const <RecognizedLine>[];
    final sourceLayouts = [
      for (final source in sources)
        _tables(
          source,
          profile,
          recovery: recovery,
          deskew: deskew,
          compact: extendDeliveryBand,
          headerSupport: headerSupport,
        ),
    ];
    final layouts = sourceLayouts
        .expand((s) => s)
        .take(recovery ? 8 : 16)
        .toList();
    if (layouts.isEmpty) return [];
    final supportingWords = _distinctWords([
      ...sources.expand((s) => s),
      ...supplemental,
    ]);
    final templates = await (_templates ??= _loadTemplates());
    final raster = await _raster(bytes);
    final rgba = raster.rgba;
    final output = <RecognizedLine>[];
    List<RecognizedLine> wordsFor(List<RecognizedLine> source) =>
        nameAnchorWords(_distinctWords(source), profile);
    final wordReadings = sources.map(wordsFor).toList();
    final aliases = [profile.name, ...profile.aliases].map(_name).toSet();
    final imageWidth = raster.width, imageHeight = raster.height;
    bool vetoed(_Table table) =>
        deskew &&
        wordReadings
            .expand((reading) => reading)
            .any(
              (word) =>
                  isBowlerNameCandidate(word.text) &&
                  !aliases.contains(_name(word.text)) &&
                  !(extendDeliveryBand &&
                      scoreAttachedAlias(word.text, aliases)) &&
                  !_partOfName(word, table.name) &&
                  (word.centerX - table.name.centerX).abs() <
                      table.name.width * .5 &&
                  (word.centerY - table.name.centerY).abs() <
                      table.name.height * .75,
            );
    // A clearer pixel shape cannot resolve an explicit disagreement about
    // who owns a row, even if another pass sees a saved alias.
    final tables = layouts.where((table) => !vetoed(table)).toList();
    // Align every observed layout in one worker so the raster is copied
    // once per pass rather than once per layout. At most sixteen layouts and
    // four readings exist; each layout can have two confirmed ruling
    // polarities. Layout order and every validation below are unchanged.
    final tableReadings = await Isolate.run(
      () => [
        for (final table in tables)
          _layoutReadings(
            rgba,
            imageWidth,
            imageHeight,
            table,
            wordReadings,
            templates,
            supportingWords,
            deskew,
            extendDeliveryBand,
          ),
      ],
    );
    for (var t = 0; t < tables.length; t++) {
      final table = tables[t];
      final readings = tableReadings[t];
      for (final reading in readings) {
        final aligned = reading.$1;
        for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
          final source = sources[sourceIndex],
              words = wordReadings[sourceIndex];
          bool sameName(RecognizedLine w) =>
              _name(w.text) == _name(table.name.text) &&
              (w.centerX - table.name.centerX).abs() < table.name.width * .5 &&
              (w.centerY - table.name.centerY).abs() < table.name.height * .75;
          final hasName = words.any(sameName);
          final frames = reading.$2[sourceIndex];
          if (frames.length != 10 || !TenPinScorer.score(frames).complete) {
            continue;
          }
          final last = aligned.first + 9 * aligned.pitch;
          Future<List<int>> totalsFor(List<RecognizedLine> input) async {
            final totals = _scratchTotals(
              input,
              aligned,
              allowOffsetTotal: extendDeliveryBand,
            );
            if (!deskew || aligned.band == null || totals.isNotEmpty) {
              return totals;
            }
            final resolved = await Isolate.run(
              () => _resolveScratchFragments(
                input,
                aligned,
                rgba,
                imageWidth,
                imageHeight,
                templates,
              ),
            );
            return _scratchTotals(
              resolved,
              aligned,
              allowOffsetTotal: extendDeliveryBand,
            );
          }

          final directTotals = await totalsFor(words);
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
          if (recovery &&
              (observedCheckpoints.whereType<int>().length < 6 ||
                  observedCheckpoints.last != score.total)) {
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
              final otherWords = wordsFor(other);
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
          final ownsLayout = sourceLayouts[sourceIndex].any(
            (candidate) => sameName(candidate.name),
          );
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
          int? total = directTotals.where((v) => v == score.total).firstOrNull;
          // Another pass may supply an actual total for the same named row.
          // Keep six independently observed checkpoints including frame ten.
          // If the delivery pass has fewer, require the validation pass to
          // supply six and share at least three of the primary observations.
          if (total == null &&
              observedCheckpoints.whereType<int>().length >= 3 &&
              observedCheckpoints.last == score.total) {
            for (final other in sources) {
              final otherWords = wordsFor(other);
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
              total = (await totalsFor(otherWords))
                  .where((v) => v == score.total)
                  .firstOrNull;
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
                            math.min(aligned.y, aligned.y + 9 * aligned.slope) -
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
  }

  static List<(_Table, List<List<String>>)> _layoutReadings(
    Uint8List rgba,
    int imageWidth,
    int imageHeight,
    _Table table,
    List<List<RecognizedLine>> wordReadings,
    List<_Template> templates,
    List<RecognizedLine> supportingWords,
    bool deskew,
    bool extendDeliveryBand,
  ) {
    final results = <(_Table, List<List<String>>)>[];
    for (final aligned in _columnAlignments(
      rgba,
      imageWidth,
      imageHeight,
      table,
    )) {
      if (table.headers < 6 && identical(aligned, table)) continue;
      final white = _inkWhitePoint(rgba, imageWidth, imageHeight, aligned);
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
              deskew,
              extendDeliveryBand: extendDeliveryBand,
            ),
        ],
      ));
      if (white != null) {
        // Keep the established neutral-ink row as an independent
        // candidate. A cast mask must not replace already readable ink;
        // the caller validates each complete row separately.
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
                deskew,
                extendDeliveryBand: extendDeliveryBand,
              ),
          ],
        ));
      }
    }
    return results;
  }

  /// A word of a joined name anchor ("JOE" in "JOE S"), or the native word
  /// that glued the alias to following score marks, is the anchor itself and
  /// cannot be a conflicting bowler name at that position.
  static bool _partOfName(RecognizedLine word, RecognizedLine name) {
    final text = _name(word.text), anchor = _name(name.text);
    if (text == anchor ||
        word.x < name.x - name.height * .5 ||
        (word.centerY - name.centerY).abs() > name.height * .5) {
      return false;
    }
    if (word.x + word.width <= name.x + name.width + name.height * .5 &&
        anchor.contains(text)) {
      return true;
    }
    return (word.x - name.x).abs() < name.height * .5 &&
        text.startsWith(anchor) &&
        RegExp(r'^[0-9X]+$').hasMatch(text.substring(anchor.length));
  }

  /// Last bounded native retry when text alone cannot locate delivery cells.
  static Future<List<RecognitionRegion>> regions(
    Uint8List bytes,
    List<List<RecognizedLine>> readings,
    BowlerProfile profile, {
    bool recovery = false,
  }) async {
    final tables = [
      for (final source in readings)
        ..._tables(source, profile, recovery: recovery),
    ];
    if (tables.isEmpty) return [];
    final ordered = tables.indexed.toList()
      ..sort((a, b) {
        final support = b.$2.headers.compareTo(a.$2.headers);
        return support != 0 ? support : a.$1.compareTo(b.$1);
      });
    final raster = await _raster(bytes);
    final rgba = raster.rgba;
    final width = raster.width, height = raster.height;
    return await Isolate.run(() {
      // A repeated name in a footer can have more readable headers than
      // the player row. Rank only layouts whose rulings actually align;
      // an unsupported footer must not hide a supported row in another pass.
      for (final candidate in ordered) {
        final table = candidate.$2;
        final aligned = _alignColumns(rgba, width, height, table);
        if (identical(aligned, table) && (!recovery || table.headers < 6)) {
          continue;
        }
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
  }

  /// One recognition decodes its photo once. Every fallback pass for the same
  /// bytes shares the read-only RGBA raster, which is released with them.
  static final _rasters = Expando<Future<_Raster>>();

  static Future<_Raster> _raster(Uint8List bytes) =>
      _rasters[bytes] ??= _decodeRaster(bytes)
          .catchError((Object error, StackTrace stack) {
            _rasters[bytes] = null;
            Error.throwWithStackTrace(error, stack);
          });

  static Future<_Raster> _decodeRaster(Uint8List bytes) async {
    // Flutter's codec applies EXIF orientation, matching both native bridges.
    final image = await _decode(bytes);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Raster(data!.buffer.asUint8List(), image.width, image.height);
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

  static RecognitionRegion _region(
    _Table table,
    int i, {
    bool extendDeliveryBand = false,
  }) {
    final center = table.first + i * table.pitch;
    final headerY = table.y + i * table.slope;
    final gap = table.rowY(center) - headerY;
    if (table.band != null) {
      final left = center - table.pitch * .56;
      final right = i == 9
          ? math.max(center + table.pitch * .47, table.tenthRight!)
          : center + table.pitch * .47;
      final top = headerY + table.height * .55;
      // Tall slashes and split digits can reach the cumulative numeral's
      // upper margin. The final fallback leaves room for that photographed
      // ink; edge-connected fragments of cumulative text are still removed.
      final bottom =
          table.rowY(center) -
          table.band!.height * (extendDeliveryBand ? .3 : .6);
      return RecognitionRegion(
        left,
        top,
        right - left,
        bottom - top,
        tenth: i == 9,
      );
    }
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
    BowlerProfile profile, {
    bool recovery = false,
    bool deskew = false,
    bool compact = false,
    List<RecognizedLine> headerSupport = const [],
  }) {
    final words = nameAnchorWords(_distinctWords(lines), profile);
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
        if (recovery)
          for (final word in words)
            if (word.elements.isNotEmpty) ...observedHeaderSymbols(word),
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
            name.centerY - w.centerY <
                (recovery ? math.max(name.height * 6, .7) : name.height * 6);
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
          if (distinctHeaders < 3 ||
              (recovery &&
                  name.centerY - a.centerY > name.height * 6 &&
                  distinctHeaders < 6)) {
            continue;
          }
          if (table == null ||
              distinctHeaders > table.headers ||
              (distinctHeaders == table.headers && bi - ai > longestSpan)) {
            longestSpan = bi - ai;
            table = _Table(
              name,
              first,
              pitch,
              a.centerY - ai * (b.centerY - a.centerY) / (bi - ai),
              (b.centerY - a.centerY) / (bi - ai),
              _headerHeight(matches, deskew),
              distinctHeaders,
            );
          }
          // Keep the first broadly supported fit for native cell crops. Small
          // endpoint changes can affect OCR even when both fits locate the same
          // rulings. The longest-span alternative remains available to pixels.
          if (bi - ai >= 5 &&
              (firstFit == null || distinctHeaders > firstFit.headers)) {
            firstFit = _Table(
              name,
              first,
              pitch,
              a.centerY - ai * (b.centerY - a.centerY) / (bi - ai),
              (b.centerY - a.centerY) / (bi - ai),
              _headerHeight(matches, deskew),
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
    if (compact) {
      for (final name in names) {
        tables.addAll(_anchoredTables(headerSupport, name));
      }
    }
    if (!recovery) return tables;
    return [
      for (final table in tables)
        ..._recoverTable(table, words, compact: compact),
    ];
  }

  /// Split a long, explicitly recognized consecutive header run using its
  /// photographed ink columns. Character positions are never interpolated.
  static Future<List<List<RecognizedLine>>> _mergedHeaders(
    Uint8List bytes,
    List<List<RecognizedLine>> sources,
  ) async {
    final raster = await _raster(bytes);
    final rgba = raster.rgba;
    final width = raster.width, height = raster.height;
    return await Isolate.run(() {
      return [
        for (final source in sources)
          [
            ...source,
            for (final word in _distinctWords(source))
              ...splitMergedFrameHeaders(word, rgba, width, height),
          ],
      ];
    });
  }

  // Two widely separated frame-number boxes can locate a small console grid
  // only when PLAYER and TOTAL independently identify the heading strip.
  // Recovery still requires six checkpoints and photographed cell rulings.
  static List<_Table> _anchoredTables(
    List<RecognizedLine> support,
    RecognizedLine name,
  ) {
    final output = <_Table>[];
    for (final label in support.where(
      (w) =>
          RegExp(r'^TOTAL$', caseSensitive: false).hasMatch(w.text) &&
          w.x > name.x + name.width &&
          w.centerY < name.y,
    )) {
      if (!support.any(
        (w) =>
            w.text.toUpperCase() == 'PLAYER' &&
            w.x < label.x &&
            (w.centerY - label.centerY).abs() < label.height,
      )) {
        continue;
      }
      final headers = support.where((w) {
        final n = int.tryParse(w.text);
        return n != null &&
            n >= 1 &&
            n <= 10 &&
            w.centerX > name.x + name.width &&
            w.x + w.width < label.x &&
            (w.centerY - label.centerY).abs() < label.height * .75;
      }).toList();
      for (final a in headers) {
        for (final b in headers) {
          final ai = int.parse(a.text) - 1, bi = int.parse(b.text) - 1;
          if (bi != 9 || bi - ai < 5) continue;
          final pitch = (b.centerX - a.centerX) / (bi - ai);
          final slope = (b.centerY - a.centerY) / (bi - ai);
          final first = a.centerX - ai * pitch;
          if (pitch <= 0 ||
              pitch > .1 ||
              first < name.x + name.width ||
              (slope / pitch).abs() > .4) {
            continue;
          }
          if (output.any(
            (t) =>
                (t.first - first).abs() < pitch * .1 &&
                (t.pitch - pitch).abs() < pitch * .05,
          )) {
            continue;
          }
          output.add(
            _Table(
              name,
              first,
              pitch,
              a.centerY - ai * slope,
              slope,
              math.min(a.height, b.height),
              2,
            ),
          );
        }
      }
    }
    return output.take(4).toList();
  }

  static double _headerHeight(List<RecognizedLine> matches, bool deskew) {
    final heights = matches.map((w) => w.height).toList()..sort();
    if (deskew) {
      // OCR can include a ruling or illustration in a few header boxes. Two
      // independently sized numerals must support the smaller height; a lone
      // tiny observation cannot shrink the delivery band. The recovery fit
      // still requires six actual cumulative observations, including frame ten.
      final compact = matches
          .where((word) => word.height <= heights.first * 1.5)
          .toList();
      if (compact.map((word) => word.text).toSet().length >= 2) {
        final supported = compact.map((word) => word.height).toList()..sort();
        return supported[supported.length ~/ 2];
      }
    }
    return heights[heights.length ~/ 2];
  }

  static List<_Table> _recoverTable(
    _Table table,
    List<RecognizedLine> words, {
    bool compact = false,
  }) {
    var band = RecoveryScoreBand.fit(
      words,
      name: table.name,
      first: table.first,
      pitch: table.pitch,
      headerY: table.y,
      headerSlope: table.slope,
      headerHeight: table.height,
      allowCompactScores: compact,
    );
    if (band == null) return [];
    final columns = band.columns(words, table.first, table.pitch);
    final first = columns?.$1 ?? table.first;
    final pitch = columns?.$2 ?? table.pitch;
    final shift = (first - table.first) / table.pitch * band.slope;
    band = RecoveryScoreBand(
      band.firstY + shift,
      band.slope * pitch / table.pitch,
      band.height,
      band.markTop + shift,
    );
    final totals = band.totals(words, first, pitch);
    final tenthRight = totals.length == 1
        ? math.min(totals.single.x - pitch * .1, first + pitch * 10.4)
        : first + pitch * 10;
    return [
      _Table(
        table.name,
        first,
        pitch,
        band.markTop - table.height * .55,
        band.slope,
        table.height,
        table.headers,
        band: band,
        tenthRight: tenthRight,
      ),
    ];
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
                (w.centerX - center).abs() <
                    table.pitch * (table.band != null ? .5 : .45) &&
                w.centerY >
                    rowY -
                        (table.band?.height == null
                            ? gap * .2
                            : table.band!.height * .35) &&
                w.centerY <
                    rowY +
                        (table.band?.height == null
                            ? gap * .65
                            : table.band!.height * .35) &&
                RegExp(r'^\d{1,3}$').hasMatch(w.text),
          )
          .toList();
      if (values.length > 1) return null;
      result.add(values.isEmpty ? null : int.parse(values.single.text));
    }
    return result;
  }

  static List<int> _scratchTotals(
    List<RecognizedLine> words,
    _Table table, {
    bool allowOffsetTotal = false,
  }) {
    if (table.band != null) {
      return table.band!
          .totals(
            words,
            table.first,
            table.pitch,
            allowOffsetTotal: allowOffsetTotal,
          )
          .map((w) => int.parse(w.text))
          .toList();
    }
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

  /// A native block may repeat the last digit over the same large total, e.g.
  /// "5" over "115". Resolve only proper text fragments beneath an observed
  /// total label, and only when independent pixels read the entire longer word.
  /// No calculated score participates; competing full numbers stay ambiguous.
  static List<RecognizedLine> _resolveScratchFragments(
    List<RecognizedLine> words,
    _Table table,
    Uint8List rgba,
    int imageWidth,
    int imageHeight,
    List<_Template> templates,
  ) {
    final last = table.first + 9 * table.pitch;
    final labels = words.where(
      (w) =>
          RegExp(
            r'^(TOT(?:AL)?|TTL)$',
            caseSensitive: false,
          ).hasMatch(w.text.replaceAll(RegExp(r'[^a-zA-Z]'), '')) &&
          w.centerX > last + table.pitch * .55 &&
          w.centerX < last + table.pitch * 3 &&
          w.y < table.rowY(w.centerX),
    );
    for (final label in labels) {
      final candidates =
          words
              .where(
                (w) =>
                    RegExp(r'^\d{1,3}$').hasMatch(w.text) &&
                    int.parse(w.text) <= 300 &&
                    (w.centerX - label.centerX).abs() < table.pitch * .5 &&
                    w.y > label.y + label.height * .8 &&
                    (w.centerY - table.rowY(w.centerX)).abs() <
                        math.max(w.height, table.band!.height) * .55,
              )
              .toList()
            ..sort((a, b) => b.text.length.compareTo(a.text.length));
      if (candidates.length < 2) continue;
      final whole = candidates.first;
      if (whole.text.length < 2 ||
          candidates.skip(1).any((part) {
            final overlapX = math.max(
              0.0,
              math.min(part.x + part.width, whole.x + whole.width) -
                  math.max(part.x, whole.x),
            );
            final overlapY = math.max(
              0.0,
              math.min(part.y + part.height, whole.y + whole.height) -
                  math.max(part.y, whole.y),
            );
            return part.text.length >= whole.text.length ||
                !whole.text.contains(part.text) ||
                overlapX * overlapY <
                    math.min(
                          part.width * part.height,
                          whole.width * whole.height,
                        ) *
                        .8;
          })) {
        continue;
      }
      final left = candidates.map((w) => w.x).reduce(math.min);
      final right = candidates.map((w) => w.x + w.width).reduce(math.max);
      final top = candidates.map((w) => w.y).reduce(math.min);
      final bottom = candidates.map((w) => w.y + w.height).reduce(math.max);
      final x = (left * imageWidth).floor() - 2;
      final y = (top * imageHeight).floor() - 2;
      final w = ((right - left) * imageWidth).ceil() + 4;
      final h = ((bottom - top) * imageHeight).ceil() + 4;
      if (x < 0 || y < 0 || x + w > imageWidth || y + h > imageHeight) continue;
      final neutral = Uint8List(w * h);
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final p = ((y + py) * imageWidth + x + px) * 4;
          final low = math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2]));
          final high = math.max(rgba[p], math.max(rgba[p + 1], rgba[p + 2]));
          if (rgba[p + 3] >= 165 && low >= 140 && high - low <= 110) {
            neutral[py * w + px] = 1;
          }
        }
      }
      final white = _inkWhitePoint(rgba, imageWidth, imageHeight, table);
      final physical = _recoverInk(
        rgba,
        imageWidth,
        x,
        y,
        w,
        h,
        true,
        '',
        neutral,
        (mask) =>
            _classify(mask, w, h, templates, outlined: true, deskew: true),
        numeric: true,
        calibratedMasks: white == null
            ? const []
            : _castMasks(rgba, imageWidth, x, y, w, h, white),
      );
      if (physical == whole.text) {
        return words
            .where((word) => !candidates.skip(1).contains(word))
            .toList();
      }
    }
    return words;
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
    bool deskew, {
    bool extendDeliveryBand = false,
  }) {
    final frames = <String>[];
    for (var i = 0; i < 10; i++) {
      final region = _region(table, i, extendDeliveryBand: extendDeliveryBand);
      if (region.width <= 0 ||
          region.height <= 0 ||
          region.x < 0 ||
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
      if (table.band != null) {
        final primary = [
          for (final word in words)
            if (word.x >= region.x &&
                word.x + word.width <= region.x + region.width &&
                region.contains(word))
              ...ScoreboardGrid.symbols(word).where(
                (s) => RegExp(
                  r'^[0-9XF/×–—\-]$',
                  caseSensitive: false,
                ).hasMatch(s.text),
              ),
        ]..sort((a, b) => a.x.compareTo(b.x));
        final confirmed = primary
            .map((s) => s.text)
            .join()
            .toUpperCase()
            .replaceAll('×', 'X')
            .replaceAll('–', '-')
            .replaceAll('—', '-');
        String readInk(Uint8List pixels) => _classify(
          pixels,
          w,
          h,
          templates,
          outlined: true,
          deskew: deskew,
          maxGlyphWidth: .85,
          observed: (l, t, r, b) => _inside(
            (deskew ? words : supportingWords)
                .where(
                  (w) => RegExp(
                    r'^[0-9XF/×]$',
                    caseSensitive: false,
                  ).hasMatch(w.text),
                )
                .toList(),
            imageWidth,
            imageHeight,
            x,
            y,
            l,
            t,
            r,
            b,
          ),
          supporting: (l, t, r, b) =>
              _inside(supporting, imageWidth, imageHeight, x, y, l, t, r, b),
        );
        frames.add(
          _recoverInk(
            rgba,
            imageWidth,
            x,
            y,
            w,
            h,
            i == 9,
            confirmed,
            mask,
            readInk,
            ignoreInvalidNative: deskew,
            calibratedMasks: deskew && white != null
                ? _castMasks(rgba, imageWidth, x, y, w, h, white)
                : const [],
          ),
        );
        continue;
      }
      // Determine delivery order from photographed components. Word-level
      // OCR can spread a merged token across frame boundaries and reverse a
      // miss and digit while preserving the same cumulative and final score.
      String classify(Uint8List pixels) => _classify(
        pixels,
        w,
        h,
        templates,
        deskew: deskew,
        observed: (l, t, r, b) =>
            _inside(observations, imageWidth, imageHeight, x, y, l, t, r, b),
        supporting: (l, t, r, b) =>
            _inside(supporting, imageWidth, imageHeight, x, y, l, t, r, b),
      );
      String? corrected;
      if (white != null) {
        // The row's measured light ink can carry a strong monitor/camera cast.
        // Progressively retain more of that ink, never choosing by a score.
        for (final pixels in _castMasks(rgba, imageWidth, x, y, w, h, white)) {
          // Outlined lettering is separated from the illustration behind it.
          // Edge-connected decoration cannot be an intact photographed glyph.
          String readCorrected(Uint8List input) => _classify(
            input,
            w,
            h,
            templates,
            outlined: true,
            deskew: deskew,
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

  static Iterable<Uint8List> _castMasks(
    Uint8List rgba,
    int imageWidth,
    int x,
    int y,
    int w,
    int h,
    List<int> white,
  ) sync* {
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
      yield pixels;
    }
  }

  static String _recoverInk(
    Uint8List rgba,
    int imageWidth,
    int x,
    int y,
    int w,
    int h,
    bool tenth,
    String native,
    Uint8List neutral,
    String Function(Uint8List) classify, {
    bool ignoreInvalidNative = false,
    Iterable<Uint8List> calibratedMasks = const [],
    bool numeric = false,
  }) {
    final luminance = Uint8List(w * h);
    final histogram = List.filled(256, 0);
    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        final p = ((y + py) * imageWidth + x + px) * 4;
        final value = (rgba[p] * .299 + rgba[p + 1] * .587 + rgba[p + 2] * .114)
            .round();
        luminance[py * w + px] = value;
        histogram[value]++;
      }
    }
    int percentile(double q) {
      var seen = 0;
      for (var value = 0; value < 256; value++) {
        seen += histogram[value];
        if (seen >= w * h * q) return value;
      }
      return 255;
    }

    final low = percentile(.05), high = percentile(.95);
    final readings = <String>{};
    bool agrees(String candidate) {
      // A malformed OCR token can include a piece of background illustration.
      // It cannot constrain the ordering of a fully classified pixel reading.
      // Legal complete or partial observations still have to remain present.
      if (ignoreInvalidNative &&
          TenPinScorer.parseFrame(native, tenth: tenth).error != null) {
        return true;
      }
      // Only native words wholly within this frame constrain delivery order;
      // synthesized character boxes from a cross-frame word are not primary.
      var index = 0;
      for (final c in candidate.split('')) {
        if (index < native.length && native[index] == c) index++;
      }
      return index == native.length;
    }

    final neutralInk = withoutEdgeConnectedInk(neutral, w, h);
    bool valid(String value) {
      if (numeric) {
        return RegExp(r'^\d{1,3}$').hasMatch(value) && int.parse(value) <= 300;
      }
      final parsed = TenPinScorer.parseFrame(value, tenth: tenth);
      return parsed.complete && parsed.error == null;
    }

    void consider(Uint8List mask) {
      final value = classify(mask);
      if (valid(value) && agrees(value)) {
        readings.add(value);
      }
    }

    consider(neutralInk);
    // A cast-calibrated row can separate pale delivery ink from colored
    // illustration fragments with similar luminance. Keep the same complete
    // glyph, primary-observation and ambiguity checks as every other mask.
    for (final mask in calibratedMasks) {
      consider(withoutEdgeConnectedInk(mask, w, h));
    }
    if (high - low >= 50) {
      for (final fraction in [.35, .5]) {
        final dark = Uint8List(w * h), light = Uint8List(w * h);
        for (var p = 0; p < luminance.length; p++) {
          if (luminance[p] < low + (high - low) * fraction) dark[p] = 1;
          if (luminance[p] > high - (high - low) * fraction) light[p] = 1;
        }
        final darkInk = withoutSolidPanels(
          withoutEdgeConnectedInk(dark, w, h),
          w,
          h,
        );
        final lightInk = withoutSolidPanels(
          withoutEdgeConnectedInk(light, w, h),
          w,
          h,
        );
        final combined = Uint8List.fromList([
          for (var p = 0; p < darkInk.length; p++) darkInk[p] | lightInk[p],
        ]);
        final mixed = Uint8List.fromList([
          for (var p = 0; p < darkInk.length; p++) darkInk[p] | neutralInk[p],
        ]);
        for (final mask in [darkInk, lightInk, combined, mixed]) {
          consider(mask);
        }
      }
    }
    if (readings.length == 1) return readings.single;
    if (readings.length > 1) return '';
    return valid(native) ? native : '';
  }

  /// Per-isolate memo for [_rankGlyph]; bounded and keyed by exact pixels.
  static final _glyphRanks = <_GlyphKey, List<MapEntry<String, double>>>{};

  static List<MapEntry<String, double>> _rankGlyph(
    _Component c,
    int w,
    int h,
    List<_Template> templates, {
    bool deskew = false,
  }) {
    if (deskew) {
      final upright = _rankGlyph(c, w, h, templates);
      // Extra normalizations must not turn a confident existing shape into
      // an ambiguity. Only unresolved glyphs need an italic correction.
      if (upright.first.value >= .68 &&
          upright.first.value - upright[1].value >= .06) {
        return upright;
      }
      final scores = <String, double>{};
      void collect(List<MapEntry<String, double>> ranked) {
        for (final entry in ranked) {
          scores[entry.key] = math.max(scores[entry.key] ?? 0, entry.value);
        }
      }

      collect(upright);
      final gh = c.b - c.t, gw = c.r - c.l;
      final padding = (gh * .2).ceil() + 1;
      final width = gw + padding * 2;
      // Correct a bounded italic lean before normalizing the component. No
      // templates, scores, or native characters determine the transformation.
      for (final shear in [-.2, -.1, .1, .2]) {
        final pixels = <int>[];
        var left = width, right = 0;
        for (final p in c.pixels) {
          final y = p ~/ w - c.t;
          final x = p % w - c.l + padding + (y * shear).round();
          left = math.min(left, x);
          right = math.max(right, x + 1);
          pixels.add(y * width + x);
        }
        collect(
          _rankGlyph(
            _Component(left, 0, right, gh, pixels),
            width,
            gh,
            templates,
          ),
        );
      }
      return scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }
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
          band: table.band == null
              ? null
              : RecoveryScoreBand(
                  table.band!.y(
                    table.first + (winner.$1 - winner.$3 * .5) * table.pitch,
                    table.first,
                    table.pitch,
                  ),
                  table.band!.slope * winner.$3,
                  table.band!.height,
                  table.band!.markTop +
                      (winner.$1 - winner.$3 * .5) * table.band!.slope,
                ),
          tenthRight: table.tenthRight,
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

  /// Template classification of one binary cell mask with optional native
  /// characters observed inside it, for deterministic glyph tests.
  @visibleForTesting
  static Future<String> classifyMaskForTesting(
    Uint8List mask,
    int width,
    int height, {
    Set<String> observed = const {},
  }) async => _classify(
    mask,
    width,
    height,
    await (_templates ??= _loadTemplates()),
    observed: observed.isEmpty ? null : (_, _, _, _) => observed,
  );

  /// Exposed for deterministic raster regression tests. Unknown ink stays blank.
  static String _classify(
    Uint8List mask,
    int w,
    int h,
    List<_Template> templates, {
    bool outlined = false,
    bool deskew = false,
    double maxGlyphWidth = .65,
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
        rankings.putIfAbsent(c, () {
          // Every OCR reading and ink mask of a cell re-reads the same
          // photographed components. A template ranking depends only on the
          // exact pixels, so reuse it; the key compares every pixel.
          final key = _GlyphKey(w, h, deskew, templates, c.pixels);
          final cached = _glyphRanks[key];
          if (cached != null) return cached;
          if (_glyphRanks.length >= 4096) _glyphRanks.clear();
          return _glyphRanks[key] = _rankGlyph(
            c,
            w,
            h,
            templates,
            deskew: deskew,
          );
        });
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
      if (gh > h * .92 || gw > w * maxGlyphWidth) {
        return '';
      }
      final ranked = ranking(c);
      final best = ranked.first;
      final native = observed?.call(c.l, c.t, c.r, c.b) ?? <String>{};
      final known = native
          .where((s) => RegExp(r'^[0-9XF/]$').hasMatch(s))
          .toSet();
      // Fill omissions; keep an independently observed native character in
      // this component even when thresholding has broken its photographed ink.
      // It cannot overwrite a confident, different pixel winner: artwork over
      // a digit can fool a crop's OCR (an 8 read as 3 in a spare frame keeps
      // every checkpoint), so two disagreeing readings leave the frame blank.
      if (known.length == 1) {
        if (known.single != best.key &&
            best.value >= .68 &&
            best.value - ranked[1].value >= .06) {
          return '';
        }
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

class _GlyphKey {
  _GlyphKey(this.w, this.h, this.deskew, this.templates, List<int> pixels)
    : pixels = Int32List.fromList(pixels),
      hashCode = Object.hash(
        w,
        h,
        deskew,
        identityHashCode(templates),
        Object.hashAll(pixels),
      );
  final int w, h;
  final bool deskew;
  final List<_Template> templates;
  final Int32List pixels;
  @override
  final int hashCode;
  @override
  bool operator ==(Object other) {
    if (other is! _GlyphKey ||
        other.hashCode != hashCode ||
        other.w != w ||
        other.h != h ||
        other.deskew != deskew ||
        !identical(other.templates, templates) ||
        other.pixels.length != pixels.length) {
      return false;
    }
    for (var i = 0; i < pixels.length; i++) {
      if (other.pixels[i] != pixels[i]) return false;
    }
    return true;
  }
}

class _Raster {
  const _Raster(this.rgba, this.width, this.height);
  final Uint8List rgba;
  final int width, height;
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
    this.headers, {
    this.band,
    this.tenthRight,
  });
  final RecognizedLine name;
  final double first, pitch, y, slope, height;
  final int headers;
  final RecoveryScoreBand? band;
  final double? tenthRight;
  double rowY(double x) =>
      band?.y(x, first, pitch) ??
      name.centerY + (x - name.centerX) * slope / pitch;
}
