import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../domain/scoring.dart';
import '../theme.dart';

String dateLabel(DateTime date) => DateFormat('EEE, MMM d, y').format(date);
String averageLabel(Iterable<BowlingGame> games) {
  final list = games.toList();
  return list.isEmpty
      ? '—'
      : (list.fold<int>(0, (n, g) => n + g.score) / list.length)
            .toStringAsFixed(1);
}

Future<void> safely(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your changes. $e')),
      );
    }
  }
}

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String action = 'Continue',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: BowlColors.muted)),
          ],
        ),
        ?action,
      ],
    ),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title, body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: BowlColors.mint,
              child: Icon(icon, size: 28, color: BowlColors.ink),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BowlColors.muted, height: 1.6),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard(
    this.label,
    this.value,
    this.detail, {
    super.key,
    this.accent = false,
  });
  final String label, value, detail;
  final bool accent;
  @override
  Widget build(BuildContext context) => Card(
    color: accent ? BowlColors.mint : null,
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: BowlColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 12, color: BowlColors.muted),
          ),
        ],
      ),
    ),
  );
}

class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = c.maxWidth > 800
          ? children.length
          : (c.maxWidth > 420 ? 2 : 1);
      final width = (c.maxWidth - (count - 1) * 16) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class BallArt extends StatelessWidget {
  const BallArt({super.key, this.size = 56, this.color = BowlColors.orange});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _BallPainter(color)),
  );
}

class _BallPainter extends CustomPainter {
  _BallPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, .2)!,
            color,
            Color.lerp(color, BowlColors.ink, .45)!,
          ],
          center: const Alignment(-.5, -.5),
        ).createShader(Offset.zero & size),
    );
    for (final point in [
      const Offset(.48, .31),
      const Offset(.65, .37),
      const Offset(.5, .51),
    ]) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        size.width * .055,
        Paint()..color = BowlColors.ink.withValues(alpha: .8),
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * .36),
      math.pi * .8,
      math.pi * .6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .16)
        ..strokeWidth = size.width * .04
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BallPainter oldDelegate) =>
      oldDelegate.color != color;
}

class ScoreStrip extends StatelessWidget {
  const ScoreStrip({super.key, required this.frames});
  final List<String> frames;
  @override
  Widget build(BuildContext context) {
    final result = TenPinScorer.score(frames);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 10; i++)
            Container(
              width: i == 9 ? 90 : 72,
              decoration: BoxDecoration(
                border: Border.all(color: BowlColors.line),
                color: result.frames[i].error != null
                    ? const Color(0xFFFFE4DE)
                    : Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    color: BowlColors.canvas,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: BowlColors.muted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Text(
                      result.frames[i].notation.isEmpty
                          ? '·'
                          : result.frames[i].notation,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${result.cumulative[i] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LabelPill extends StatelessWidget {
  const LabelPill(this.text, {super.key, this.color = BowlColors.mint});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
