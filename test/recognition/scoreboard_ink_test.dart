import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/recognition/scoreboard_ink.dart';

void main() {
  test('bright connected grid edges leave interior delivery ink intact', () {
    const w = 60, h = 80;
    final mask = Uint8List(w * h);
    for (var x = 0; x < w; x++) {
      mask[x] = 1;
    }
    for (var y = 0; y < h; y++) {
      mask[y * w] = 1;
    }
    for (var y = 20; y < 60; y++) {
      mask[y * w + 20 + (y - 20) ~/ 2] = 1;
      mask[y * w + 39 - (y - 20) ~/ 2] = 1;
    }
    for (var x = 20; x < 40; x++) {
      mask[40 * w + x] = 1;
    }
    final result = withoutBoundaryRulings(mask, w, h);
    expect(result.take(w).every((v) => v == 0), isTrue);
    for (var y = 0; y < h; y++) {
      expect(result[y * w], 0);
    }
    for (var y = 20; y < 60; y++) {
      expect(result[y * w + 20 + (y - 20) ~/ 2], 1);
      expect(result[y * w + 39 - (y - 20) ~/ 2], 1);
    }
    expect(result.sublist(40 * w + 20, 40 * w + 40), List.filled(20, 1));
    expect(mask[0], 1, reason: 'The source raster must not be mutated.');
  });

  test('short misses and a narrow digit near an edge are not rulings', () {
    const w = 60, h = 80;
    final mask = Uint8List(w * h);
    for (var y = 15; y < 65; y++) {
      mask[y * w + 4] = 1;
    }
    for (var x = 20; x < 40; x++) {
      mask[40 * w + x] = 1;
    }
    expect(identical(withoutBoundaryRulings(mask, w, h), mask), isTrue);
  });

  test('grid outlines alone do not manufacture delivery ink', () {
    const w = 60, h = 80;
    final mask = Uint8List(w * h);
    for (var x = 0; x < w; x++) {
      mask[x] = 1;
      mask[(h - 1) * w + x] = 1;
    }
    for (var y = 0; y < h; y++) {
      mask[y * w] = 1;
      mask[y * w + w - 1] = 1;
    }
    expect(withoutBoundaryRulings(mask, w, h).every((v) => v == 0), isTrue);
  });

  test('a long interior stroke is not removed as a crop boundary', () {
    const w = 60, h = 80;
    final mask = Uint8List(w * h);
    for (var x = 0; x < w; x++) {
      mask[40 * w + x] = 1;
    }
    expect(identical(withoutBoundaryRulings(mask, w, h), mask), isTrue);
  });
}
