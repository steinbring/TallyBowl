import 'package:flutter/widgets.dart';

abstract final class BowlLayout {
  static const navigationWidth = 850.0;
  static const spaciousWidth = 700.0;
  static const dashboardWidth = 1200.0;
  static const editorWidth = 1000.0;
  static const recapWidth = 900.0;

  static double toolbarHeight(BuildContext context) =>
      56 * (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);

  /// Component density follows available space and the user's text size.
  static int columns(
    BuildContext context,
    double width, {
    required double minimumWidth,
    required int maximum,
    double gap = 16,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return ((width + gap) / (minimumWidth * scale + gap)).floor().clamp(
      1,
      maximum,
    );
  }
}
