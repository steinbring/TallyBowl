import 'package:flutter/material.dart';

/// Keep a small form open until its write succeeds, and allow retry without
/// re-entering data. Return false from onSave for form validation failures.
class SavingDialog extends StatefulWidget {
  const SavingDialog({
    super.key,
    required this.title,
    required this.content,
    required this.saveLabel,
    required this.onSave,
  });
  final String title, saveLabel;
  final Widget content;
  final Future<bool> Function() onSave;
  @override
  State<SavingDialog> createState() => _SavingDialogState();
}

class _SavingDialogState extends State<SavingDialog> {
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave();
      if (!mounted) return;
      setState(() => _saving = false);
      if (saved) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save. Your entries are still here; please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                descendantsAreFocusable: !_saving,
                child: IgnorePointer(ignoring: _saving, child: widget.content),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : widget.saveLabel),
        ),
      ],
    ),
  );
}
