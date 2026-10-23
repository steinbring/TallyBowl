/// Standard ten-pin scoring. Recognition never decides the score: this engine
/// validates the delivery sequence and calculates all strike/spare bonuses.
class FrameResult {
  const FrameResult(
    this.notation,
    this.marks,
    this.pins,
    this.complete,
    this.error,
  );
  final String notation;
  final List<String> marks;
  final List<int> pins;
  final bool complete;
  final String? error;
  bool get strike => pins.isNotEmpty && pins.first == 10;
  bool get spare => marks.length > 1 && marks[1] == '/';
}

class ScoreResult {
  const ScoreResult(this.frames, this.cumulative);
  final List<FrameResult> frames;
  final List<int?> cumulative;
  bool get complete =>
      frames.length == 10 && frames.every((f) => f.complete && f.error == null);
  bool get valid => frames.every((f) => f.error == null);
  int? get total => complete ? cumulative.last : null;
  int get runningTotal => cumulative.whereType<int>().lastOrNull ?? 0;
  int get strikes => frames.where((f) => f.complete && f.strike).length;
  int get spares => frames.where((f) => f.complete && f.spare).length;
  int get spareOpportunities =>
      frames.where((f) => f.complete && !f.strike).length;
}

abstract final class TenPinScorer {
  static ScoreResult score(List<String> notation) {
    if (notation.length != 10) {
      throw ArgumentError('A game must have exactly ten frames.');
    }
    final frames = [
      for (var i = 0; i < 10; i++) parseFrame(notation[i], tenth: i == 9),
    ];
    final cumulative = <int?>[];
    var total = 0;
    var unresolved = false;
    for (var i = 0; i < 10; i++) {
      final frame = frames[i];
      if (unresolved || !frame.complete || frame.error != null) {
        unresolved = true;
        cumulative.add(null);
        continue;
      }
      var points = frame.pins.fold(0, (a, b) => a + b);
      if (i < 9 && (frame.strike || frame.spare)) {
        final following = <int>[];
        for (var j = i + 1; j < 10; j++) {
          if (frames[j].error != null) break;
          following.addAll(frames[j].pins);
          if (!frames[j].complete) break;
        }
        final required = frame.strike ? 2 : 1;
        if (following.length < required) {
          unresolved = true;
          cumulative.add(null);
          continue;
        }
        points += following.take(required).fold(0, (a, b) => a + b);
      }
      total += points;
      cumulative.add(total);
    }
    return ScoreResult(frames, cumulative);
  }

  static FrameResult parseFrame(String value, {bool tenth = false}) {
    final text = value
        .toUpperCase()
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('×', 'X')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    final marks = text.split('');
    final pins = <int>[];
    FrameResult result(bool complete, [String? error]) =>
        FrameResult(text, marks, List.unmodifiable(pins), complete, error);
    if (marks.isEmpty) return result(false);
    if (marks.length > (tenth ? 3 : 2)) {
      return result(false, 'Too many deliveries.');
    }
    for (var i = 0; i < marks.length; i++) {
      final mark = marks[i];
      // A new rack follows a strike, or follows a spare before the final fill.
      final freshRack =
          i == 0 ||
          (tenth && (pins[i - 1] == 10 || (i == 2 && marks[1] == '/')));
      final remaining = freshRack ? 10 : 10 - pins[i - 1];
      if (i > 0 && !tenth && pins.first == 10) {
        return result(false, 'A strike completes this frame.');
      }
      if (i == 2 && tenth && pins.first != 10 && marks[1] != '/') {
        return result(false, 'An open tenth frame has two deliveries.');
      }
      int? count;
      if (mark == 'X') {
        if (!freshRack) {
          return result(false, 'Use / for a spare on the same rack.');
        }
        count = 10;
      } else if (mark == '/') {
        if (freshRack) {
          return result(
            false,
            'A spare must follow a delivery on the same rack.',
          );
        }
        count = remaining;
      } else if (mark == '-' || mark == 'F') {
        count = 0;
      } else {
        count = int.tryParse(mark);
        if (count == null || count < 0 || count > 9) {
          return result(false, 'Use X, /, -, F, or digits 0–9.');
        }
        if (count > remaining) {
          return result(false, 'More pins than remain on the rack.');
        }
        if (!freshRack && count == remaining) {
          return result(false, 'Mark a spare with /.');
        }
      }
      pins.add(count);
    }
    final needed = !tenth
        ? (pins.first == 10 ? 1 : 2)
        : (pins.first == 10 || (marks.length > 1 && marks[1] == '/') ? 3 : 2);
    return result(marks.length == needed);
  }
}
