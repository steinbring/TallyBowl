import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../domain/models.dart';
import 'recognized_text.dart';
import 'scoreboard_name.dart';

/// Photo problems that a retake can plausibly fix.
enum PhotoIssue {
  /// No scoreboard text was recognized at all.
  noText,

  /// The scoreboard text is too small in the photo (far away or low
  /// resolution).
  smallText,

  /// Character edges are spread by focus or motion blur.
  blurry,

  /// The brightest marks are too dim against the background.
  underexposed,

  /// None of the saved bowler names was found.
  nameMissing,
}

/// Pixel measurements of the photographed scoreboard area. Engine-neutral:
/// only native text boxes (both bridges supply them) locate the area.
class PhotoMeasurements {
  const PhotoMeasurements({
    required this.textHeight,
    required this.sharpness,
    required this.contrast,
  });

  /// Median native text height in original-image pixels (0 without text).
  final double textHeight;

  /// 99th-percentile luminance step at a standard 24-pixel text height,
  /// relative to the area's contrast. Blur spreads each edge and lowers it.
  final double sharpness;

  /// 5th–95th percentile spread of luminance in the area.
  final double contrast;
}

class PhotoQualityReport {
  const PhotoQualityReport(this.issues, this.measurements);
  final List<PhotoIssue> issues;
  final PhotoMeasurements? measurements;
  bool get suggestsRetake => issues.isNotEmpty;
}

/// Decides whether a photo that could not be imported automatically is likely
/// to read better if retaken. It never changes recognition or a score; it only
/// explains a likely cause, and the person can always keep the photo.
abstract final class PhotoQuality {
  // Calibrated on the private corpus (docs/PHOTO_QUALITY.md): every photo
  // that imports has text of at least 24 px, sharpness of at least .36 and
  // contrast of at least 100. Synthetic blur stopped every import between
  // .25 and .23 sharpness; darkening stopped them between 77 and 48 contrast.
  static const minTextHeight = 36.0;
  static const minSharpness = .24;
  static const minContrast = 80.0;

  static Future<PhotoQualityReport> assess(
    Uint8List bytes,
    List<RecognizedLine> lines,
    List<ScoreRow> rows,
    BowlerProfile profile,
  ) async {
    final issues = <PhotoIssue>[];
    final names = [
      profile.name,
      ...profile.aliases,
    ].map(normalizedBowlerName).where((n) => n.isNotEmpty);
    if (names.isNotEmpty && !rows.any((r) => r.suggested)) {
      issues.add(PhotoIssue.nameMissing);
    }
    PhotoMeasurements? measured;
    try {
      measured = await measure(bytes, lines);
    } catch (_) {
      // An unreadable image keeps the existing manual-review path.
    }
    if (measured != null) {
      final found = issuesFor(measured);
      // Without any text, a missing name is implied rather than a cause.
      if (found.contains(PhotoIssue.noText)) {
        issues.remove(PhotoIssue.nameMissing);
      }
      issues.insertAll(0, found);
    }
    return PhotoQualityReport(issues, measured);
  }

  static List<PhotoIssue> issuesFor(PhotoMeasurements m) {
    // Without text, whole-scene blur and contrast say little about the
    // scoreboard; heavy blur is one common cause of finding no text.
    if (m.textHeight == 0) return [PhotoIssue.noText];
    return [
      if (m.textHeight < minTextHeight) PhotoIssue.smallText,
      // Sharpness is normalized to text size; tiny text has its own advice.
      if (m.textHeight >= minTextHeight && m.sharpness < minSharpness)
        PhotoIssue.blurry,
      if (m.contrast < minContrast) PhotoIssue.underexposed,
    ];
  }

  static Future<PhotoMeasurements> measure(
    Uint8List bytes,
    List<RecognizedLine> lines,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      // Flutter's codec applies EXIF orientation, as in the glyph reader. Text
      // height is measured in the 4096-pixel space both native engines read.
      final longest = math.max(descriptor.width, descriptor.height);
      final cap = math.min(1.0, 4096 / longest);
      final width = descriptor.width * cap, height = descriptor.height * cap;
      final boxes = [
        for (final line in lines)
          if (line.frameRow == null &&
              line.width > 0 &&
              line.height > 0 &&
              RegExp(r'[0-9A-Za-z]').hasMatch(line.text))
            line,
      ];
      final heights = boxes.map((b) => b.height * height).toList()..sort();
      final textHeight = heights.isEmpty ? 0.0 : heights[heights.length ~/ 2];
      var left = 0.0, top = 0.0, right = 1.0, bottom = 1.0;
      if (boxes.length >= 3) {
        left = boxes.map((b) => b.x).reduce(math.min);
        top = boxes.map((b) => b.y).reduce(math.min);
        right = boxes.map((b) => b.x + b.width).reduce(math.max);
        bottom = boxes.map((b) => b.y + b.height).reduce(math.max);
      }
      // Measure at a standard 24-pixel text height (bounded to 4 megapixels),
      // so blur is judged relative to the characters rather than the camera.
      var scale = cap * (textHeight > 0 ? 24 / textHeight : 1024 / 4096);
      scale = math.min(cap, scale);
      scale = math.min(scale, cap * math.sqrt(4e6 / (width * height)));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      final image = (await codec.getNextFrame()).image;
      try {
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final w = image.width, h = image.height;
        final x0 = (left * w).floor().clamp(0, w - 1);
        final y0 = (top * h).floor().clamp(0, h - 1);
        final x1 = (right * w).ceil().clamp(x0 + 1, w);
        final y1 = (bottom * h).ceil().clamp(y0 + 1, h);
        return await Isolate.run(
          () => _measureArea(rgba, w, x0, y0, x1, y1, textHeight),
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static PhotoMeasurements _measureArea(
    Uint8List rgba,
    int w,
    int x0,
    int y0,
    int x1,
    int y1,
    double textHeight,
  ) {
    final aw = x1 - x0, ah = y1 - y0;
    final luminance = Uint8List(aw * ah);
    final histogram = List.filled(256, 0);
    for (var y = 0; y < ah; y++) {
      for (var x = 0; x < aw; x++) {
        final p = ((y + y0) * w + x + x0) * 4;
        final r = rgba[p], g = rgba[p + 1], b = rgba[p + 2];
        final v = (r * .299 + g * .587 + b * .114).round();
        luminance[y * aw + x] = v;
        histogram[v]++;
      }
    }
    int percentile(List<int> counts, int total, double q) {
      var seen = 0;
      for (var i = 0; i < counts.length; i++) {
        seen += counts[i];
        if (seen >= total * q) return i;
      }
      return counts.length - 1;
    }

    final total = aw * ah;
    final low = percentile(histogram, total, .05);
    final high = percentile(histogram, total, .95);
    final steps = List.filled(256, 0);
    var stepCount = 0;
    for (var y = 0; y + 1 < ah; y++) {
      for (var x = 0; x + 1 < aw; x++) {
        final v = luminance[y * aw + x];
        final step = math.max(
          (luminance[y * aw + x + 1] - v).abs(),
          (luminance[(y + 1) * aw + x] - v).abs(),
        );
        steps[step]++;
        stepCount++;
      }
    }
    final contrast = (high - low).toDouble();
    final edge = stepCount == 0
        ? 0
        : percentile(steps, stepCount, .99).toDouble();
    return PhotoMeasurements(
      textHeight: textHeight,
      sharpness: contrast <= 0 ? 0 : edge / contrast,
      contrast: contrast,
    );
  }
}
