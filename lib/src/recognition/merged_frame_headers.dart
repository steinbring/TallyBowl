import 'dart:math' as math;
import 'dart:typed_data';

import 'recognized_text.dart';

/// Split six or more consecutive, explicitly recognized frame headings at
/// their actual ink columns. Missing or merged ink stays unresolved; character
/// positions are never interpolated and delivery digits are never substituted.
List<RecognizedLine> splitMergedFrameHeaders(
  RecognizedLine word,
  Uint8List rgba,
  int width,
  int height,
) {
  final run = word.text;
  final start = List.generate(5, (i) => i + 1)
      .where((i) => [for (var n = i; n <= 10; n++) '$n'].join() == run)
      .firstOrNull;
  if (start == null || word.width > .8 || word.height > .1) return [];
  final x = (word.x * width).floor(),
      y = ((word.y - word.height * .1) * height).floor();
  final w = (word.width * width).ceil(),
      h = (word.height * height * 1.2).ceil();
  if (x < 0 || y < 0 || x + w > width || y + h > height || w < 1 || h < 1) {
    return [];
  }
  final mask = Uint8List(w * h);
  for (var py = 0; py < h; py++) {
    var count = 0;
    for (var px = 0; px < w; px++) {
      final p = ((y + py) * width + x + px) * 4;
      final low = math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2]));
      final high = math.max(rgba[p], math.max(rgba[p + 1], rgba[p + 2]));
      if (low >= 140 && high - low <= 110) {
        mask[py * w + px] = 1;
        count++;
      }
    }
    if (count > w * .65) mask.fillRange(py * w, (py + 1) * w, 0);
  }
  final spans = <(int, int)>[];
  int? left;
  for (var px = 0; px <= w; px++) {
    var count = 0;
    if (px < w) {
      for (var py = 0; py < h; py++) {
        count += mask[py * w + px];
      }
    }
    if (count >= math.max(2, h * .12)) {
      left ??= px;
    } else if (left != null) {
      if (px - left >= 2) spans.add((left, px));
      left = null;
    }
  }
  // Long, narrow, edge-connected columns are photographed cell borders.
  spans.removeWhere((span) {
    var top = h, bottom = 0;
    for (var px = span.$1; px < span.$2; px++) {
      for (var py = 0; py < h; py++) {
        if (mask[py * w + px] != 0) {
          top = math.min(top, py);
          bottom = math.max(bottom, py + 1);
        }
      }
    }
    return bottom - top > h * .85 && span.$2 - span.$1 < h * .2;
  });
  if (spans.length != run.length) return [];
  final output = <RecognizedLine>[];
  var position = 0;
  for (var n = start; n <= 10; n++) {
    final first = spans[position++];
    final last = n == 10 ? spans[position++] : first;
    var top = h, bottom = 0;
    for (var px = first.$1; px < last.$2; px++) {
      for (var py = 0; py < h; py++) {
        if (mask[py * w + px] != 0) {
          top = math.min(top, py);
          bottom = math.max(bottom, py + 1);
        }
      }
    }
    if (bottom - top < h * .4) return [];
    output.add(
      RecognizedLine(
        text: '$n',
        x: (x + first.$1) / width,
        y: (y + top) / height,
        width: (last.$2 - first.$1) / width,
        height: (bottom - top) / height,
      ),
    );
  }
  return output;
}
