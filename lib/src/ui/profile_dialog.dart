import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import 'saving_dialog.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key, required this.controller});
  final BowlController controller;
  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final name = TextEditingController(
    text: widget.controller.data.profile.name,
  );
  late final aliases = TextEditingController(
    text: widget.controller.data.profile.aliases.join(', '),
  );
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    aliases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SavingDialog(
    title: 'Your bowler profile',
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
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
    saveLabel: 'Save profile',
    onSave: () async {
      if (!_form.currentState!.validate()) return false;
      await widget.controller.saveProfile(
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
      return true;
    },
  );
}
