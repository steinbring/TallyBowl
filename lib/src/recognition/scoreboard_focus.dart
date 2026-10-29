import 'dart:math' as math;

import '../domain/models.dart';
import 'recognized_text.dart';
import 'scoreboard_grid.dart';

/// A context crop for small score tables. It keeps the name, headers, delivery
/// band and totals together; observations retain original-image coordinates.
abstract final class ScoreboardFocus {
  static RecognitionRegion? region(
    List<List<RecognizedLine>> readings,
    BowlerProfile profile,
  ) {
    String normalized(String value) =>
        value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final aliases = [
      profile.name,
      ...profile.aliases,
    ].map(normalized).where((s) => s.isNotEmpty).toSet();
    final candidates = <(RecognizedLine, RecognitionRegion, int)>[];
    for (final lines in readings) {
      final words = lines.expand(ScoreboardGrid.words).toList();
      for (final name in words.where(
        (w) => aliases.contains(normalized(w.text)) && w.height > 0,
      )) {
        final numbers = words.where((w) {
          final n = int.tryParse(w.text);
          return n != null &&
              n >= 0 &&
              n <= 300 &&
              w.x > name.x + name.width &&
              w.centerY >= name.y - name.height * .05 &&
              (w.centerY - name.centerY).abs() < name.height * 1.2;
        }).toList();
        if (numbers.length < 5) continue;
        final left = math.max(0.0, name.x - name.width * .3);
        final top = math.max(0.0, name.y - name.height * 3.5);
        // OCR may omit the separate final total. Keep space beyond the last
        // observed number for both scratch and handicap columns.
        final right = math.min(
          1.0,
          numbers.map((w) => w.x + w.width).reduce(math.max) +
              math.max(name.height * 3, name.width * 1.5),
        );
        final bottom = math.min(
          1.0,
          math.max(
                name.centerY + name.height * 1.4,
                numbers.map((w) => w.y + w.height).reduce(math.max),
              ) +
              name.height * .3,
        );
        if (right <= left ||
            bottom <= top ||
            (right - left) * (bottom - top) > .55 ||
            bottom - top > .55) {
          continue;
        }
        candidates.add((
          name,
          RecognitionRegion(left, top, right - left, bottom - top),
          numbers.length,
        ));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.$3.compareTo(a.$3));
    final best = candidates.first;
    // Duplicate passes of one name are useful; two distinct matching player
    // rows must stay visible to the existing ambiguous-row review flow.
    if (candidates.any(
      (c) =>
          (c.$1.centerY - best.$1.centerY).abs() >
          math.max(c.$1.height, best.$1.height) * .8,
    )) {
      return null;
    }
    return best.$2;
  }
}
