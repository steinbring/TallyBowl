import 'package:flutter/material.dart';

import '../domain/scoring.dart';
import 'layout.dart';

class FrameGrid extends StatelessWidget {
  const FrameGrid({
    super.key,
    required this.controllers,
    required this.result,
    required this.onChanged,
  });
  final List<TextEditingController> controllers;
  final ScoreResult result;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = BowlLayout.columns(
        context,
        c.maxWidth,
        minimumWidth: 140,
        maximum: 5,
        gap: 12,
      );
      return Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          for (var i = 0; i < 10; i++)
            SizedBox(
              width: (c.maxWidth - (count - 1) * 12) / count,
              child: TextField(
                key: ValueKey('frame-$i'),
                controller: controllers[i],
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: i == 9 ? 3 : 2,
                textInputAction: i == 9
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Frame ${i + 1}',
                  hintText: i == 9 ? 'X7/' : '9/',
                  counterText: '',
                  errorText: result.frames[i].error,
                  errorMaxLines: 3,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
        ],
      );
    },
  );
}

class ScoringSummary extends StatelessWidget {
  const ScoringSummary({super.key, required this.result});
  final ScoreResult result;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final description = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.complete ? 'Ready to save' : 'Every delivery counts',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 4),
        const Text(
          'X strike · / spare · - miss · F foul. Examples: X, 9/, 81, X7/.',
          style: TextStyle(height: 1.5),
        ),
      ],
    );
    final score = Text(
      '${result.total ?? result.runningTotal}',
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
    );
    return Card(
      color: colors.primaryContainer,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onPrimaryContainer),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, c) {
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              return c.maxWidth < 420 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        score,
                        const SizedBox(height: 12),
                        description,
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.scoreboard_outlined, size: 34),
                        const SizedBox(width: 16),
                        Expanded(child: description),
                        const SizedBox(width: 12),
                        score,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}
