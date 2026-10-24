import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/place_search.dart';
import '../domain/models.dart';
import 'alley_search.dart';

class AlleyDialog extends StatefulWidget {
  const AlleyDialog({
    super.key,
    required this.controller,
    this.alley,
    this.searchService,
  });
  final BowlController controller;
  final BowlingAlley? alley;
  final PlaceSearch? searchService;
  @override
  State<AlleyDialog> createState() => _AlleyDialogState();
}

class _AlleyDialogState extends State<AlleyDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _notes;
  late String _id;
  String? _osmId, _error;
  double? _latitude, _longitude;
  bool _retired = false, _saving = false, _alreadySaved = false;
  bool get _exists => widget.controller.data.alley(_id) != null;
  @override
  void initState() {
    super.initState();
    final alley = widget.alley;
    _id = alley?.id ?? widget.controller.newId();
    _name = TextEditingController(text: alley?.name);
    _address = TextEditingController(text: alley?.address);
    _notes = TextEditingController(text: alley?.notes);
    _latitude = alley?.latitude;
    _longitude = alley?.longitude;
    _osmId = alley?.osmId;
    _retired = alley?.retired ?? false;
  }

  @override
  void dispose() {
    for (final field in [_name, _address, _notes]) {
      field.dispose();
    }
    super.dispose();
  }

  void _select(PlaceSuggestion place) {
    final existing = widget.controller.data.alleys
        .where((a) => a.osmId == place.osmId)
        .firstOrNull;
    setState(() {
      _id = existing?.id ?? widget.alley?.id ?? widget.controller.newId();
      _name.text = existing?.name ?? place.name;
      _address.text = existing?.address ?? place.address;
      _notes.text = existing?.notes ?? '';
      _retired = existing?.retired ?? false;
      _latitude = place.latitude;
      _longitude = place.longitude;
      _osmId = place.osmId;
      _alreadySaved = existing != null;
      _error = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = BowlingAlley(
        id: _id,
        name: _name.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        osmId: _osmId,
        retired: _retired,
      );
      await widget.controller.saveAlley(saved);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save this alley. Your entries are still here; please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(_exists ? 'Edit bowling alley' : 'Add your bowling alley'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.alley == null || widget.alley!.name.isEmpty) ...[
                  IgnorePointer(
                    ignoring: _saving,
                    child: AlleySearch(
                      onSelected: _select,
                      service: widget.searchService,
                    ),
                  ),
                  const Divider(height: 28),
                ],
                if (_alreadySaved)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Already in your alleys. Saving updates the existing entry.',
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Alley name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter the alley’s name.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _address,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                if (_latitude != null)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _latitude = null;
                            _longitude = null;
                            _osmId = null;
                          }),
                    icon: const Icon(Icons.location_off_outlined, size: 18),
                    label: const Text('Clear map location'),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                if (_exists)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Archive alley'),
                    subtitle: const Text(
                      'Keep past visits, hide from new sessions.',
                    ),
                    value: _retired,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _retired = v),
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
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save alley'),
        ),
      ],
    ),
  );
}
