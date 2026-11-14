import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/recognition/scoreboard_ink.dart';

void main() {
  test(
    'cast mask removes connected illustration but retains separate marks',
    () {
      const w = 60, h = 80;
      final mask = Uint8List(w * h);
      // Illustration reaches the crop edge and curves into the delivery band.
      for (var y = 0; y < 65; y++) {
        mask[y * w + y ~/ 3] = 1;
        mask[y * w + y ~/ 3 + 1] = 1;
      }
      // A disconnected digit stem and a miss remain real delivery candidates.
      for (var y = 15; y < 65; y++) {
        mask[y * w + 35] = 1;
      }
      for (var x = 42; x < 55; x++) {
        mask[40 * w + x] = 1;
      }
      final cleaned = withoutEdgeConnectedInk(mask, w, h);
      for (var y = 0; y < 65; y++) {
        expect(cleaned[y * w + y ~/ 3], 0);
      }
      for (var y = 15; y < 65; y++) {
        expect(cleaned[y * w + 35], 1);
      }
      expect(cleaned.sublist(40 * w + 42, 40 * w + 55), List.filled(13, 1));
      expect(mask[0], 1);
    },
  );

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
  test('solid delivery panels disappear without erasing digits or misses', () {
    const w = 120, h = 60;
    final mask = Uint8List(w * h);
    for (var y = 8; y < 53; y++) {
      for (var x = 60; x < 110; x++) {
        mask[y * w + x] = 1;
      }
      // A separate narrow digit stroke.
      for (var x = 20; x < 27; x++) {
        mask[y * w + x] = 1;
      }
    }
    for (var x = 32; x < 50; x++) {
      mask[30 * w + x] = 1;
    }
    final cleaned = withoutSolidPanels(mask, w, h);
    expect(cleaned[30 * w + 80], 0);
    expect(cleaned[30 * w + 23], 1);
    expect(cleaned[30 * w + 40], 1);
    expect(mask[30 * w + 80], 1);
  });
  test('a large sparse glyph is not mistaken for a filled panel', () {
    const w = 120, h = 60;
    final mask = Uint8List(w * h);
    for (var y = 8; y < 53; y++) {
      mask[y * w + 45 + y] = 1;
      mask[y * w + 105 - y] = 1;
    }
    expect(withoutSolidPanels(mask, w, h), mask);
  });
}
