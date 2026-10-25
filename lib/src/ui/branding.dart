import 'package:flutter/material.dart';

/// The fixed teal badge keeps the cream bowler legible in either app theme.
class TallyBowlLogo extends StatelessWidget {
  const TallyBowlLogo({super.key, this.size = 40});
  static const asset = 'assets/branding/tallybowl-logo.png';
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'TallyBowl! bowler pointing the way',
    child: Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .2)),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .2),
        border: Border.all(color: const Color(0xFF48615F)),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    ),
  );
}

/// A bowling ball with three finger holes, inheriting navigation icon colors.
class BowlingBallIcon extends StatelessWidget {
  const BowlingBallIcon({super.key, this.size, this.color});
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size ?? theme.size ?? 24,
        child: CustomPaint(
          painter: _BowlingBallPainter(
            color ?? theme.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _BowlingBallPainter extends CustomPainter {
  const _BowlingBallPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = size.shortestSide;
    final shape = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: diameter * .43,
        ),
      );
    for (final hole in [
      const Offset(.46, .32),
      const Offset(.64, .4),
      const Offset(.45, .53),
    ]) {
      shape.addOval(
        Rect.fromCircle(
          center: Offset(hole.dx * size.width, hole.dy * size.height),
          radius: diameter * .065,
        ),
      );
    }
    canvas.drawPath(shape, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BowlingBallPainter oldDelegate) =>
      color != oldDelegate.color;
}
