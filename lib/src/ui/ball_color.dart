import 'package:flutter/material.dart';

import '../domain/models.dart';

extension BallColorAppearance on BallColor {
  Color get swatch => switch (this) {
    BallColor.black => const Color(0xFF202020),
    BallColor.white => const Color(0xFFF5F5F5),
    BallColor.gray => const Color(0xFF808080),
    BallColor.red => const Color(0xFFC62828),
    BallColor.orange => const Color(0xFFEF6C00),
    BallColor.yellow => const Color(0xFFFDD835),
    BallColor.green => const Color(0xFF2E7D32),
    BallColor.blue => const Color(0xFF1565C0),
    BallColor.purple => const Color(0xFF7B1FA2),
    BallColor.pink => const Color(0xFFEC407A),
    BallColor.brown => const Color(0xFF795548),
  };
}

/// Names identify choices independently of color perception or app theme.
class BallColorLabel extends StatelessWidget {
  const BallColorLabel(this.color, {super.key});
  final BallColor color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.swatch,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(child: Text(color.label)),
    ],
  );
}
