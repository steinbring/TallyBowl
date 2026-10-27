import '../domain/scoring.dart';

class RecognizedLine {
  const RecognizedLine({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence,
    this.isStroke = false,
    this.elements = const [],
    this.frameRow,
  });
  final ScoreRow? frameRow;
  final String text;
  final double x, y, width, height;
  final double? confidence;
  final bool isStroke;

  /// Native word bounds, with symbol bounds nested on Android. Older bridges
  /// and test callers may provide only lines.
  final List<RecognizedLine> elements;
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
  factory RecognizedLine.fromJson(Map<dynamic, dynamic> j) => RecognizedLine(
    text: j['text'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
    confidence: (j['confidence'] as num?)?.toDouble(),
    isStroke: j['stroke'] == true,
    elements: [
      for (final element in (j['elements'] as List? ?? const []))
        RecognizedLine.fromJson(element as Map),
    ],
  );
}

class ScoreRow {
  const ScoreRow({
    required this.text,
    required this.frames,
    required this.suggested,
    required this.y,
    required this.height,
    this.displayedTotal,
    this.cumulativeTotals,
  });
  final String text;
  final List<String> frames;
  final bool suggested;
  final double y, height;
  final int? displayedTotal;
  final List<int>? cumulativeTotals;
  bool get hasScoreConflict {
    final score = TenPinScorer.score(frames);
    return score.complete &&
        ((displayedTotal != null && displayedTotal != score.total) ||
            (cumulativeTotals != null &&
                (cumulativeTotals!.length != 10 ||
                    List.generate(10, (i) => i).any(
                      (i) => cumulativeTotals![i] != score.cumulative[i],
                    ))));
  }

  bool get canAutoSelect =>
      suggested &&
      extracted &&
      !hasScoreConflict &&
      (displayedTotal != null || cumulativeTotals != null);
  bool get extracted => TenPinScorer.score(frames).complete;
}

/// Normalized bounds in the upright source image, with a top-left origin.
class RecognitionRegion {
  const RecognitionRegion(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.tenth = false,
  });
  final double x, y, width, height;
  final bool tenth;
  bool contains(RecognizedLine text) =>
      text.centerX >= x &&
      text.centerX <= x + width &&
      text.centerY >= y &&
      text.centerY <= y + height;
  Map<String, double> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}
