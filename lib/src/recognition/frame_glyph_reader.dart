import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/scoring.dart';
import 'recognized_text.dart';
import 'scoreboard_grid.dart';

/// Conservative local fallback for separated delivery cells on monitor grids.
/// Templates classify photographed ink; score totals only validate the result.
abstract final class FrameGlyphReader {
  static Future<List<_Template>>? _templates;
  static String _name(String s) =>
      s.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static Future<List<RecognizedLine>> read(
    Uint8List bytes,
    List<RecognizedLine> lines,
    BowlerProfile profile,
  ) async {
    final words = lines.expand(ScoreboardGrid.words).toList();
    final aliases = [
      profile.name,
      ...profile.aliases,
    ].map(_name).where((s) => s.isNotEmpty).toSet();
    final names = words.where((w) => aliases.contains(_name(w.text))).toList();
    final tables = <_Table>[];
    for (final name in names) {
      final headers = words.where((w) {
        final n = int.tryParse(w.text);
        return n != null &&
            n >= 1 &&
            n <= 10 &&
            w.centerX > name.x + name.width &&
            name.centerY - w.centerY > name.height &&
            name.centerY - w.centerY < name.height * 6;
      }).toList();
      _Table? table;
      for (final a in headers) {
        for (final b in headers) {
          final ai = int.parse(a.text) - 1, bi = int.parse(b.text) - 1;
          if (bi - ai < 5) continue;
          final pitch = (b.centerX - a.centerX) / (bi - ai);
          if (pitch <= 0 || pitch > .1) continue;
          final first = a.centerX - ai * pitch;
          final matches = headers.where((w) {
            final i = int.parse(w.text) - 1;
            final y =
                a.centerY + (b.centerY - a.centerY) * (i - ai) / (bi - ai);
            return (w.centerX - first - i * pitch).abs() < pitch * .15 &&
                (w.centerY - y).abs() < math.max(a.height, b.height) * .7;
          }).toList();
          if (matches.map((w) => w.text).toSet().length < 6) continue;
          if (table == null || matches.length > table.headers) {
            final heights = matches.map((w) => w.height).toList()..sort();
            table = _Table(
              name,
              first,
              pitch,
              a.centerY - ai * (b.centerY - a.centerY) / (bi - ai),
              (b.centerY - a.centerY) / (bi - ai),
              heights[heights.length ~/ 2],
              matches.length,
            );
          }
        }
      }
      if (table != null) tables.add(table);
    }
    if (tables.isEmpty || tables.length > 2) return [];
    final templates = await (_templates ??= _loadTemplates());
    // Flutter's codec applies EXIF orientation, matching both native bridges.
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final longest = math.max(descriptor.width, descriptor.height);
      final scale = math.min(1.0, 4096 / longest);
      codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final output = <RecognizedLine>[];
      for (final table in tables) {
        final imageWidth = image.width, imageHeight = image.height;
        final frames = await Isolate.run(
          () => _readFrames(
            rgba,
            imageWidth,
            imageHeight,
            table,
            words,
            templates,
          ),
        );
        if (frames.length != 10 || !TenPinScorer.score(frames).complete) {
          continue;
        }
        final last = table.first + 9 * table.pitch;
        final totals = words
            .where(
              (w) =>
                  w.centerX > last + table.pitch * .55 &&
                  w.centerX < last + table.pitch * 2.5 &&
                  (w.centerY - table.name.centerY).abs() <
                      table.name.height * 1.8 &&
                  RegExp(r'^\d{1,3}$').hasMatch(w.text),
            )
            .toList();
        if (totals.length != 1) continue;
        final total = int.parse(totals.single.text);
        if (total > 300 || TenPinScorer.score(frames).total != total) continue;
        final checkpoints = ScoreboardGrid.rows(lines, profile)
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
        var checkpointConflict = false;
        final observedCheckpoints = <int?>[];
        for (var i = 0; i < 10; i++) {
          final center = table.first + i * table.pitch;
          final gap = table.name.centerY - (table.y + i * table.slope);
          final values = words
              .where(
                (w) =>
                    (w.centerX - center).abs() < table.pitch * .45 &&
                    w.centerY > table.name.centerY + gap * .15 &&
                    w.centerY < table.name.centerY + gap * 1.2 &&
                    RegExp(r'^\d{1,3}$').hasMatch(w.text),
              )
              .toList();
          if (values.length > 1) checkpointConflict = true;
          final value = values.length == 1
              ? int.parse(values.single.text)
              : null;
          observedCheckpoints.add(value);
          if (value != null && value != score.cumulative[i]) {
            checkpointConflict = true;
          }
        }
        if (checkpointConflict) continue;
        if (checkpoints != null &&
            List.generate(
              10,
              (i) => i,
            ).any((i) => score.cumulative[i] != checkpoints[i])) {
          continue;
        }
        final top = table.y + table.height;
        final bottom = words
            .where((w) => w.x > table.name.x && w.x < last + table.pitch)
            .where((w) => w.y > top && w.y < top + table.name.height * 5)
            .map((w) => w.y + w.height)
            .fold(table.name.y + table.name.height, math.max);
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
      return output;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static List<String> _readFrames(
    Uint8List rgba,
    int imageWidth,
    int imageHeight,
    _Table table,
    List<RecognizedLine> words,
    List<_Template> templates,
  ) {
    final frames = <String>[];
    for (var i = 0; i < 10; i++) {
      final center = table.first + i * table.pitch;
      final headerY = table.y + i * table.slope;
      final gap = table.name.centerY - headerY;
      final region = RecognitionRegion(
        center - table.pitch * .49,
        headerY + gap * .30,
        table.pitch * .98,
        gap * .55,
        tenth: i == 9,
      );
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
      final mask = Uint8List(w * h);
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final p = ((y + py) * imageWidth + x + px) * 4;
          final low = math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2]));
          final high = math.max(rgba[p], math.max(rgba[p + 1], rgba[p + 2]));
          if (rgba[p + 3] >= 165 && low >= 140 && high - low <= 110) {
            mask[py * w + px] = 1;
          }
        }
      }
      final observations = [
        for (final word in words) ...ScoreboardGrid.symbols(word),
      ].where(region.contains).toList();
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
      if (TenPinScorer.parseFrame(nativeFrame, tenth: i == 9).complete) {
        frames.add(nativeFrame);
        continue;
      }
      frames.add(
        _classify(
          mask,
          w,
          h,
          templates,
          observed: (l, t, r, b) => observations
              .where((o) {
                final ox = o.centerX * imageWidth - x,
                    oy = o.centerY * imageHeight - y;
                return ox >= l - 3 && ox <= r + 3 && oy >= t - 3 && oy <= b + 3;
              })
              .map((o) => o.text.toUpperCase())
              .toSet(),
        ),
      );
    }
    return frames;
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
    Set<String> Function(int, int, int, int)? observed,
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
    // A split ring encloses a separate digit. Remove only the enclosing ink,
    // retaining the observed digit, including both holes of an eight.
    final glyphs =
        components
            .where(
              (c) => !components.any(
                (d) =>
                    c.l <= d.l - 2 &&
                    c.t <= d.t - 2 &&
                    c.r >= d.r + 2 &&
                    c.b >= d.b + 2,
              ),
            )
            .toList()
          ..sort((a, b) => a.l.compareTo(b.l));
    final result = StringBuffer();
    for (final c in glyphs) {
      final gw = c.r - c.l, gh = c.b - c.t;
      if (gw < 3 || gh < 2 || c.pixels.length < math.max(5, w * h * .0003)) {
        continue;
      }
      final ratio = gw / gh;
      if (ratio >= 1.6 &&
          ratio <= 8 &&
          gh < h * .3 &&
          (c.t + c.b) / 2 > h * .2 &&
          (c.t + c.b) / 2 < h * .8) {
        result.write('-');
        continue;
      }
      if (gh < h * .22) continue;
      if (gh > h * .92 || gw > w * .65) return '';
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
}
