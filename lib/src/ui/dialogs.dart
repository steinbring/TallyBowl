import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import 'common.dart';

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
]) async {
  final name = TextEditingController(text: ball?.name);
  final brand = TextEditingController(text: ball?.brand);
  final weight = TextEditingController(text: (ball?.weight ?? 15).toString());
  final notes = TextEditingController(text: ball?.notes);
  var retired = ball?.retired ?? false;
  final key = GlobalKey<FormState>();
  final result = await showDialog<BowlingBall>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(ball == null ? 'Add a ball to your bag' : 'Edit your ball'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Ball name / model',
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: brand,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight (lb)'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || !n.isFinite || n <= 0 || n > 16
                          ? 'Use a weight greater than 0 and up to 16 lb.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Coverstock, surface, favorite conditions…',
                    ),
                  ),
                  if (ball != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Retired'),
                      subtitle: const Text(
                        'Keep its history, hide from new games.',
                      ),
                      value: retired,
                      onChanged: (v) => setState(() => retired = v),
                    ),
                ],
              ),
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
                  BowlingBall(
                    id: ball?.id ?? controller.newId(),
                    name: name.text.trim(),
                    brand: brand.text.trim(),
                    weight: double.parse(weight.text),
                    notes: notes.text.trim(),
                    retired: retired,
                  ),
                );
              }
            },
            child: const Text('Save ball'),
          ),
        ],
      ),
    ),
  );
  if (result != null && context.mounted) {
    await safely(context, () => controller.saveBall(result));
  }
  for (final c in [name, brand, weight, notes]) {
    c.dispose();
  }
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

Future<void> editAlley(
  BuildContext context,
  BowlController controller, [
  BowlingAlley? alley,
]) async {
  final name = TextEditingController(text: alley?.name);
  final address = TextEditingController(text: alley?.address);
  final notes = TextEditingController(text: alley?.notes);
  var retired = alley?.retired ?? false;
  final key = GlobalKey<FormState>();
  final result = await showDialog<BowlingAlley>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(
          alley == null ? 'Add your bowling alley' : 'Edit bowling alley',
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Alley name'),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  if (alley != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Archive alley'),
                      subtitle: const Text(
                        'Keep past visits, hide from new sessions.',
                      ),
                      value: retired,
                      onChanged: (v) => setState(() => retired = v),
                    ),
                ],
              ),
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
                  BowlingAlley(
                    id: alley?.id ?? controller.newId(),
                    name: name.text.trim(),
                    address: address.text.trim(),
                    notes: notes.text.trim(),
                    retired: retired,
                    latitude: alley?.latitude,
                    longitude: alley?.longitude,
                    osmId: alley?.osmId,
                  ),
                );
              }
            },
            child: const Text('Save alley'),
          ),
        ],
      ),
    ),
  );
  if (result != null && context.mounted) {
    await safely(context, () => controller.saveAlley(result));
  }
  for (final c in [name, address, notes]) {
    c.dispose();
  }
}

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
