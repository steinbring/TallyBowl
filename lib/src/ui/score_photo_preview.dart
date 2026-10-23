import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';

class ScorePhotoPreview extends StatelessWidget {
  const ScorePhotoPreview({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 280,
      width: double.infinity,
      color: BowlColors.ink,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => const Center(
            child: Text(
              'This photo is no longer available. You can still finish your frames.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}
