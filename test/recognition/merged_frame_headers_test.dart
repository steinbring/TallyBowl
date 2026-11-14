import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/recognition/merged_frame_headers.dart';
import 'package:tallybowl/src/recognition/recognized_text.dart';

const heading = RecognizedLine(
  text: '12345678910',
  x: .1,
  y: .1,
  width: .66,
  height: .08,
);

// Anonymous heading strip: eleven independently separated ink silhouettes,
// with the last two occupying the same cell. Thin rulings cross the crop.
Uint8List strip({bool missing = false, bool joined = false}) {
  final rgba = Uint8List(1000 * 500 * 4);
  void rect(int x, int y, int w, int h) {
    for (var py = y; py < y + h; py++) {
      for (var px = x; px < x + w; px++) {
        final p = (py * 1000 + px) * 4;
        rgba.setRange(p, p + 4, [245, 245, 245, 255]);
      }
    }
  }

  for (var i = 0; i < 10; i++) {
    if (!missing || i != 3) rect(110 + i * 60, 54, 16, 30);
    rect(146 + i * 60, 46, 3, 48);
  }
  rect(675, 54, 16, 30); // zero of frame ten.
  if (joined) rect(666, 54, 9, 30);
  return rgba;
}

void main() {
  test(
    'merged headings retain actual ink positions and ignore cell borders',
    () {
      final words = splitMergedFrameHeaders(heading, strip(), 1000, 500);
      expect(words.map((w) => w.text), List.generate(10, (i) => '${i + 1}'));
      expect(words.first.x, closeTo(.110, .001));
      expect(words[4].x, closeTo(.350, .001));
      expect(words.last.x, closeTo(.650, .001));
      expect(words.last.width, closeTo(.041, .001));
    },
  );
  test('a native run cannot invent a missing or joined ink position', () {
    expect(
      splitMergedFrameHeaders(heading, strip(missing: true), 1000, 500),
      isEmpty,
    );
    expect(
      splitMergedFrameHeaders(heading, strip(joined: true), 1000, 500),
      isEmpty,
    );
  });
  test('score strings and short header fragments are not expanded', () {
    for (final text in ['123456789', '12346678910', '78910', '1234567891O']) {
      expect(
        splitMergedFrameHeaders(
          RecognizedLine(text: text, x: .1, y: .1, width: .66, height: .08),
          strip(),
          1000,
          500,
        ),
        isEmpty,
      );
    }
  });
}
