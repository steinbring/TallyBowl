import 'dart:typed_data';

/// Discard cropped, edge-connected foreground from an optional cast-corrected
/// mask. Complete outlined glyphs remain isolated from the monitor illustration.
Uint8List withoutEdgeConnectedInk(Uint8List mask, int width, int height) {
  if (width < 1 || height < 1 || mask.length != width * height) return mask;
  final cleaned = Uint8List.fromList(mask);
  final queue = <int>[];
  void add(int position) {
    if (cleaned[position] == 0) return;
    cleaned[position] = 0;
    queue.add(position);
  }

  for (var x = 0; x < width; x++) {
    add(x);
    add((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    add(y * width);
    add(y * width + width - 1);
  }
  for (var i = 0; i < queue.length; i++) {
    final p = queue[i], x = p % width, y = p ~/ width;
    if (x > 0) add(p - 1);
    if (x + 1 < width) add(p + 1);
    if (y > 0) add(p - width);
    if (y + 1 < height) add(p + width);
  }
  return cleaned;
}

/// Remove long grid rulings connected to a delivery crop's boundary. Short
/// interior marks and disconnected glyphs remain untouched. Return the original
/// mask when no ruling is measured, so callers can avoid a duplicate reading.
Uint8List withoutBoundaryRulings(Uint8List mask, int width, int height) {
  if (width < 10 || height < 10 || mask.length != width * height) return mask;
  final edgeX = (width * .12).ceil(), edgeY = (height * .15).ceil();
  final seeds = <int>[];
  for (var y = 0; y < height; y++) {
    if (y >= edgeY && y < height - edgeY) continue;
    var count = 0;
    for (var x = 0; x < width; x++) {
      if (mask[y * width + x] != 0) count++;
    }
    if (count >= width * .8) {
      for (var x = 0; x < width; x++) {
        if (mask[y * width + x] != 0) seeds.add(y * width + x);
      }
    }
  }
  for (var x = 0; x < width; x++) {
    if (x >= edgeX && x < width - edgeX) continue;
    var count = 0;
    for (var y = 0; y < height; y++) {
      if (mask[y * width + x] != 0) count++;
    }
    if (count >= height * .92) {
      for (var y = 0; y < height; y++) {
        if (mask[y * width + x] != 0) seeds.add(y * width + x);
      }
    }
  }
  if (seeds.isEmpty) return mask;
  final cleaned = Uint8List.fromList(mask);
  for (var i = 0; i < seeds.length; i++) {
    final p = seeds[i];
    if (cleaned[p] == 0) continue;
    cleaned[p] = 0;
    final x = p % width, y = p ~/ width;
    for (final next in [
      if (x > 0) p - 1,
      if (x + 1 < width) p + 1,
      if (y > 0) p - width,
      if (y + 1 < height) p + width,
    ]) {
      final nx = next % width, ny = next ~/ width;
      if (cleaned[next] != 0 &&
          (nx < edgeX ||
              nx >= width - edgeX ||
              ny < edgeY ||
              ny >= height - edgeY)) {
        seeds.add(next);
      }
    }
  }
  return cleaned;
}
