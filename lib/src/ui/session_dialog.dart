import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'saving_dialog.dart';

class SessionDialog extends StatefulWidget {
  const SessionDialog({
    super.key,
    required this.controller,
    required this.alleys,
  });
  final BowlController controller;
  final List<BowlingAlley> alleys;
  @override
  State<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<SessionDialog> {
  late String alleyId = widget.alleys.first.id;
  bool league = false;
  DateTime date = DateTime.now();
  final lane = TextEditingController();
  final leagueName = TextEditingController();
  late final sessionId = widget.controller.newId();
  @override
  void dispose() {
    lane.dispose();
    leagueName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SavingDialog(
    title: 'Let’s bowl.',
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: alleyId,
              decoration: const InputDecoration(labelText: 'Bowling alley'),
              items: [
                for (final a in widget.alleys)
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
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (selected != null && mounted) {
                  setState(() => date = selected);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(dateLabel(date)),
            ),
          ],
        ),
      ),
    ),
    saveLabel: 'Start session',
    onSave: () async {
      await widget.controller.startSession(
        BowlingSession(
          id: sessionId,
          alleyId: alleyId,
          startedAt: date,
          lane: lane.text.trim(),
          league: league,
          leagueName: leagueName.text.trim(),
        ),
      );
      return true;
    },
  );
}
