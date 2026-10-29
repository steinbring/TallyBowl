import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/bounded_file.dart';
import '../domain/models.dart';
import '../domain/scoring.dart';
import 'scoreboard_grid.dart';
import 'frame_glyph_reader.dart';
import 'score_parser.dart';
import 'scoreboard_focus.dart';

abstract final class PhotoService {
  static const maxPhotoBytes = 40 * 1024 * 1024;
  static const channel = MethodChannel('app.jws.tallybowl/vision');
  static Future<Directory> _imports() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'imports'),
  ).create(recursive: true);
  static Future<String> retain(Uint8List bytes) async {
    if (bytes.length > maxPhotoBytes) {
      throw const FormatException('Choose a photo smaller than 40 MB.');
    }
    final digest = sha256.convert(bytes).toString();
    final file = File(p.join((await _imports()).path, '$digest.image'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Check before allocating, and cap the stream too in case a file changes
  /// after its size was checked. macOS files are not resized by image_picker.
  static Future<Uint8List> readPhoto(XFile file) => readBoundedFile(
    file,
    maxBytes: maxPhotoBytes,
    tooLargeMessage: 'Choose a photo smaller than 40 MB.',
  );

  static Future<String?> pick({required bool camera}) async {
    if (Platform.isMacOS && camera) {
      final bytes = await channel.invokeMethod<Uint8List>('capturePhoto');
      return bytes == null ? null : retain(bytes);
    }
    if (Platform.isMacOS) {
      const type = XTypeGroup(
        label: 'Scoreboard photos',
        extensions: ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'],
        uniformTypeIdentifiers: ['public.image'],
      );
      final file = await openFile(acceptedTypeGroups: [type]);
      return file == null ? null : retain(await readPhoto(file));
    }
    final image = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      requestFullMetadata: false,
    );
    return image == null ? null : retain(await readPhoto(image));
  }

  static Future<List<RecognizedLine>> recognize(
    String path, {
    BowlerProfile? profile,
  }) async {
    final bytes = await readPhoto(XFile(path));
    final fullReadings = <List<RecognizedLine>>[];
    var regionalReading = <RecognizedLine>[];
    Future<List<RecognizedLine>> read({
      List<RecognitionRegion>? regions,
      double aspect = 1,
      bool focus = false,
    }) async {
      final context = focus && profile != null
          ? ScoreboardFocus.region(fullReadings, profile)
          : null;
      final output = await channel.invokeMethod<List<dynamic>>(
        'recognizeText',
        {
          'bytes': bytes,
          if (aspect != 1) 'aspect': aspect,
          if (regions != null)
            'regions': regions.map((r) => r.toJson()).toList(),
          if (context != null) ...{
            'regions': [context.toJson()],
            'context': true,
          },
        },
      );
      final lines = (output ?? [])
          .map((v) => RecognizedLine.fromJson(v as Map))
          .toList();
      if (regions == null) fullReadings.add(lines);
      if (regions != null) regionalReading = lines;
      return lines;
    }

    final originalLines = await _recognizeText(
      profile,
      read,
      bytes,
      fullReadings,
    );
    if (profile == null ||
        ScoreSheetParser.automaticRow(
              ScoreSheetParser.rows(originalLines, profile),
            ) !=
            null) {
      return originalLines;
    }
    try {
      final glyphRows = await FrameGlyphReader.read(
        bytes,
        originalLines,
        profile,
        alternatives: fullReadings,
        supplemental: regionalReading,
      );
      return [...originalLines, ...glyphRows];
    } catch (_) {
      return originalLines;
    }
  }

  static Future<List<RecognizedLine>> _recognizeText(
    BowlerProfile? profile,
    Future<List<RecognizedLine>> Function({
      List<RecognitionRegion>? regions,
      double aspect,
      bool focus,
    })
    read,
    Uint8List bytes,
    List<List<RecognizedLine>> fullReadings,
  ) async {
    var lines = await read(aspect: 1);
    if (profile == null ||
        ScoreSheetParser.automaticRow(ScoreSheetParser.rows(lines, profile)) !=
            null) {
      return lines;
    }
    // Condensed, tall monitor fonts can lose narrow miss marks. Retry once
    // with a bounded aspect correction while retaining full-row context.
    try {
      final corrected = await read(aspect: 2);
      int quality(List<RecognizedLine> input) =>
          ScoreSheetParser.rows(input, profile)
              .where((row) => row.suggested)
              .fold(
                0,
                (best, row) =>
                    row.frames.where((f) => f.isNotEmpty).length > best
                    ? row.frames.where((f) => f.isNotEmpty).length
                    : best,
              );
      if (ScoreSheetParser.automaticRow(
                ScoreSheetParser.rows(corrected, profile),
              ) !=
              null ||
          quality(corrected) > quality(lines)) {
        lines = corrected;
      }
    } catch (_) {
      /* Regional reading can still use the original geometry. */
    }
    if (ScoreSheetParser.automaticRow(ScoreSheetParser.rows(lines, profile)) !=
        null) {
      return lines;
    }
    var regions = ScoreboardGrid.regions(lines, profile);
    if (regions.isNotEmpty) {
      try {
        final calibrated = await FrameGlyphReader.regions(
          bytes,
          fullReadings,
          profile,
        );
        if (calibrated.isNotEmpty) regions = calibrated;
      } catch (_) {
        /* Text-only regions remain useful when pixel calibration fails. */
      }
    }
    if (regions.isEmpty) {
      // A pass can omit the bowler name or several headers, so a missing grid
      // is also a reason to try the remaining bounded full-image aspect pass.
      try {
        final context = await read(aspect: 1.5, focus: true);
        if (ScoreSheetParser.automaticRow(
              ScoreSheetParser.rows(context, profile),
            ) !=
            null) {
          return context;
        }
      } catch (_) {
        /* Keep the earlier observations available for manual review. */
      }
      try {
        final cells = await FrameGlyphReader.regions(
          bytes,
          fullReadings,
          profile,
        );
        if (cells.isNotEmpty) {
          final refined = await read(regions: cells, aspect: 1);
          return [
            for (final line in lines)
              for (final word in ScoreboardGrid.words(line))
                if (!cells.any((r) => r.contains(word))) word,
            ...refined,
          ];
        }
      } catch (_) {
        /* The conservative glyph fallback and manual review remain available. */
      }
      return lines;
    }
    try {
      final refined = await read(regions: regions, aspect: 1);
      // Retain full-row context for sparse cells and omitted headers/totals.
      // Both native engines can miss context that a bounded aspect pass keeps.
      var contextLines = <RecognizedLine>[];
      try {
        contextLines = await read(
          aspect: 1.5,
          focus: regions.every((r) => r.width <= .05),
        );
      } catch (_) {
        /* Optional retry. */
      }
      final replacements = <RecognizedLine>[];
      final active = <RecognitionRegion>[];
      List<RecognizedLine> marks(
        List<RecognizedLine> input,
        RecognitionRegion region, {
        bool strokes = false,
      }) => [
        for (final line in input)
          for (final word in ScoreboardGrid.words(line))
            for (final symbol in ScoreboardGrid.symbols(word))
              if (region.contains(symbol) &&
                  symbol.isStroke == strokes &&
                  RegExp(
                    r'^[0-9XF/×–—\-]$',
                    caseSensitive: false,
                  ).hasMatch(symbol.text))
                symbol,
      ]..sort((a, b) => a.x.compareTo(b.x));
      for (final region in regions) {
        final original = marks(lines, region);
        final observed = marks(refined, region);
        final strokes = marks(refined, region, strokes: true);
        final contextual = marks(contextLines, region);
        String notation(List<RecognizedLine> input) => input
            .map((s) => s.text)
            .join()
            .toUpperCase()
            .replaceAll('×', 'X')
            .replaceAll('–', '-')
            .replaceAll('—', '-');
        bool containsOriginal(List<RecognizedLine> proposed) {
          var index = 0;
          for (final symbol in proposed) {
            if (index < original.length &&
                notation([original[index]]) == notation([symbol])) {
              index++;
            }
          }
          return index == original.length;
        }

        // An isolated stroke augments actual observed deliveries, never a
        // combination inferred from a cumulative or final score.
        bool isNewStroke(RecognizedLine stroke, List<RecognizedLine> base) {
          if (base.isEmpty) return false;
          if (stroke.centerX > base.last.centerX + stroke.width * .3) {
            return true;
          }
          // Interior or leading strokes must occupy a real gap; exclude
          // horizontal fragments within an already-recognized digit.
          return !base.any(
            (o) => stroke.x < o.x + o.width && stroke.x + stroke.width > o.x,
          );
        }

        List<RecognizedLine> withStrokes(List<RecognizedLine> base) =>
            [...base, ...strokes.where((s) => isNewStroke(s, base))]
              ..sort((a, b) => a.x.compareTo(b.x));
        List<RecognizedLine> complement(List<RecognizedLine> extra) => [
          ...original,
          ...extra.where(
            (s) => !original.any(
              (o) => s.x < o.x + o.width && s.x + s.width > o.x,
            ),
          ),
        ]..sort((a, b) => a.x.compareTo(b.x));
        final observedPlus = complement(observed);
        final contextualPlus = complement(contextual);
        // Prefer complete OCR over morphology. Combine only non-overlapping
        // observations, preserving every character already seen in the row.
        final choices = [
          observed,
          contextual,
          observedPlus,
          contextualPlus,
          withStrokes(original),
          withStrokes(observedPlus),
          withStrokes(contextualPlus),
        ];
        final choice = choices
            .where(
              (c) =>
                  c.isNotEmpty &&
                  containsOriginal(c) &&
                  TenPinScorer.parseFrame(
                    notation(c),
                    tenth: region.tenth,
                  ).complete,
            )
            .firstOrNull;
        if (choice == null) continue;
        active.add(region);
        for (final symbol in choice) {
          replacements.add(
            RecognizedLine(
              text: symbol.text,
              x: symbol.x,
              y: symbol.y,
              width: symbol.width,
              height: symbol.height,
              elements: [symbol],
            ),
          );
        }
      }
      // Retain original symbols outside each replaced cell, including words
      // which crossed a frame boundary in the first pass.
      final merged = <RecognizedLine>[];
      for (final line in lines) {
        for (final word in ScoreboardGrid.words(line)) {
          final original = ScoreboardGrid.symbols(word).toList();
          final kept = original
              .where((symbol) => !active.any((r) => r.contains(symbol)))
              .toList();
          if (kept.isEmpty) continue;
          final retained = kept.length == original.length
              ? word
              : RecognizedLine(
                  text: kept.map((s) => s.text).join(),
                  x: word.x,
                  y: word.y,
                  width: word.width,
                  height: word.height,
                  elements: kept,
                );
          merged.add(
            RecognizedLine(
              text: retained.text,
              x: retained.x,
              y: retained.y,
              width: retained.width,
              height: retained.height,
              elements: [retained],
            ),
          );
        }
      }
      return [...merged, ...replacements];
    } catch (_) {
      return lines; // A failed regional pass keeps the original/manual review.
    }
  }

  static Future<String?> recover() async {
    if (!Platform.isAndroid) return null;
    final response = await ImagePicker().retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final file = response.files?.firstOrNull;
    return file == null ? null : retain(await readPhoto(file));
  }

  static Future<void> remove(String? source) async {
    if (source == null) return;
    final directory = await _imports();
    if (!p.isWithin(directory.path, source)) return;
    final file = File(source);
    if (await file.exists()) await file.delete();
  }

  static Future<void> cleanOrphans(String? keepPath) async {
    final directory = await _imports();
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is File && entry.path != keepPath) await entry.delete();
    }
  }
}
