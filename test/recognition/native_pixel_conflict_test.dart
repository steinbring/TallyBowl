import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/recognition/frame_glyph_reader.dart';

/// A bundled template glyph drawn three times larger, centered in a cell.
(Uint8List, int, int) cell(String text) {
  final variants =
      (jsonDecode(File('assets/recognition/glyphs.json').readAsStringSync())
              as Map)['variants']
          as List;
  final mask =
      (variants.firstWhere((v) => (v as Map)['text'] == text) as Map)['mask']
          as String;
  const w = 120, h = 140;
  final pixels = Uint8List(w * h);
  for (var y = 0; y < 96; y++) {
    for (var x = 0; x < 72; x++) {
      if (mask.codeUnitAt((y ~/ 3) * 24 + x ~/ 3) == 49) {
        pixels[(y + 22) * w + x + 24] = 1;
      }
    }
  }
  return (pixels, w, h);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a native character cannot overwrite a confident pixel winner',
    () async {
      final (eight, w, h) = cell('8');
      // Artwork over a photographed 8 made one OCR crop read 3 in a spare
      // frame, where every checkpoint and the total still agreed.
      expect(
        await FrameGlyphReader.classifyMaskForTesting(
          eight,
          w,
          h,
          observed: {'3'},
        ),
        isEmpty,
      );
      expect(
        await FrameGlyphReader.classifyMaskForTesting(
          eight,
          w,
          h,
          observed: {'8'},
        ),
        '8',
      );
      expect(await FrameGlyphReader.classifyMaskForTesting(eight, w, h), '8');
    },
  );

  test(
    'a native character still fills ink the templates cannot read',
    () async {
      // A solid block matches no template confidently.
      const w = 120, h = 140;
      final block = Uint8List(w * h);
      for (var y = 22; y < 118; y++) {
        for (var x = 24; x < 96; x++) {
          block[y * w + x] = 1;
        }
      }
      expect(
        await FrameGlyphReader.classifyMaskForTesting(block, w, h),
        isEmpty,
      );
      expect(
        await FrameGlyphReader.classifyMaskForTesting(
          block,
          w,
          h,
          observed: {'3'},
        ),
        '3',
      );
    },
  );
}
