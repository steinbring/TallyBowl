import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'alley_dialog.dart';
import 'ball_dialog.dart';

Future<void> editProfile(
  BuildContext context,
  BowlController controller,
) async {
  final name = TextEditingController(text: controller.data.profile.name);
  final aliases = TextEditingController(
    text: controller.data.profile.aliases.join(', '),
  );
  final key = GlobalKey<FormState>();
  final result = await showDialog<BowlerProfile>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Your bowler profile'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Your name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aliases,
                decoration: const InputDecoration(
                  labelText: 'Scoreboard names / nicknames',
                  hintText: 'JOE, JWS, Lefty',
                  helperText: 'Separate aliases with commas.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(
                c,
                BowlerProfile(
                  name: name.text.trim(),
                  aliases: aliases.text
                      .split(',')
                      .map((a) => a.trim())
                      .where((a) => a.isNotEmpty)
                      .toSet()
                      .toList(),
                ),
              );
            }
          },
          child: const Text('Save profile'),
        ),
      ],
    ),
  );
  if (result != null && context.mounted) {
    await safely(context, () => controller.saveProfile(result));
  }
  name.dispose();
  aliases.dispose();
}

Future<void> editBall(
  BuildContext context,
  BowlController controller, [
  BowlingBall? ball,
]) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BallDialog(controller: controller, ball: ball),
);

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

Future<void> editAlley(
  BuildContext context,
  BowlController controller, [
  BowlingAlley? alley,
]) => showDialog<void>(
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
  final alleys = controller.data.alleys.where((a) => !a.retired).toList();
  var alleyId = alleys.first.id;
  var league = false;
  var date = DateTime.now();
  final lane = TextEditingController();
  final leagueName = TextEditingController();
  final result = await showDialog<BowlingSession>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: const Text('Let’s bowl.'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: alleyId,
                  decoration: const InputDecoration(labelText: 'Bowling alley'),
                  items: [
                    for (final a in alleys)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => alleyId = v!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lane,
                  decoration: const InputDecoration(
                    labelText: 'Lane or lane pair',
                    hintText: '7 or 7–8',
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Practice'),
                      icon: Icon(Icons.sports_rounded),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('League'),
                      icon: Icon(Icons.emoji_events_outlined),
                    ),
                  ],
                  selected: {league},
                  onSelectionChanged: (v) => setState(() => league = v.single),
                ),
                if (league) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: leagueName,
                    decoration: const InputDecoration(
                      labelText: 'League name (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (selected != null) setState(() => date = selected);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(dateLabel(date)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              c,
              BowlingSession(
                id: controller.newId(),
                alleyId: alleyId,
                startedAt: date,
                lane: lane.text.trim(),
                league: league,
                leagueName: leagueName.text.trim(),
              ),
            ),
            child: const Text('Start session'),
          ),
        ],
      ),
    ),
  );
  if (result != null && context.mounted) {
    await safely(context, () => controller.startSession(result));
  }
  lane.dispose();
  leagueName.dispose();
}
