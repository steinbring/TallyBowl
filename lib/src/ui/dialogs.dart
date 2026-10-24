import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import 'alley_dialog.dart';
import 'ball_dialog.dart';
import 'profile_dialog.dart';
import 'session_dialog.dart';

Future<void> editProfile(BuildContext context, BowlController controller) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileDialog(controller: controller),
    );

Future<void> editBall(
  BuildContext context,
  BowlController controller, [
  BowlingBall? ball,
]) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BallDialog(controller: controller, ball: ball),
);

Future<BowlingAlley?> editAlley(
  BuildContext context,
  BowlController controller, [
  BowlingAlley? alley,
]) => showDialog<BowlingAlley>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AlleyDialog(controller: controller, alley: alley),
);

Future<void> startSession(
  BuildContext context,
  BowlController controller,
) async {
  if (controller.data.alleys.every((a) => a.retired)) {
    await editAlley(context, controller);
    if (!context.mounted || controller.data.alleys.every((a) => a.retired)) {
      return;
    }
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SessionDialog(
      controller: controller,
      alleys: controller.data.alleys.where((a) => !a.retired).toList(),
    ),
  );
}
