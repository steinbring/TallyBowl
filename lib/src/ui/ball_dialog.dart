import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/ball_catalog.dart';
import '../data/ball_specifications.dart';
import '../domain/models.dart';
import 'ball_color.dart';
import 'catalog_autocomplete.dart';

class BallDialog extends StatefulWidget {
  const BallDialog({super.key, required this.controller, this.ball});
  final BowlController controller;
  final BowlingBall? ball;
  @override
  State<BallDialog> createState() => _BallDialogState();
}

class _BallDialogState extends State<BallDialog> {
  final _form = GlobalKey<FormState>();
  final _brandFocus = FocusNode(), _nameFocus = FocusNode();
  late final TextEditingController _brand, _name, _weight, _nickname, _notes;
  late final String _id;
  bool _retired = false, _saving = false;
  BallColor? _color;
  CoverMaterial? _coverMaterial;
  CoverType? _coverType;
  BallSpecification? _specification;
  late bool _materialEdited, _typeEdited;
  String? _error;
  @override
  void initState() {
    super.initState();
    final ball = widget.ball;
    _id = ball?.id ?? widget.controller.newId();
    _brand = TextEditingController(text: ball?.brand);
    _name = TextEditingController(text: ball?.name);
    _weight = TextEditingController(text: (ball?.weight ?? 15).toString());
    _nickname = TextEditingController(text: ball?.nickname);
    _notes = TextEditingController(text: ball?.notes);
    _retired = ball?.retired ?? false;
    _color = ball?.color;
    _coverMaterial = ball?.coverMaterial;
    _coverType = ball?.coverType;
    // Opening an existing record must preserve its saved choices, including
    // deliberately unset fields. Applying specifications is explicit there.
    _materialEdited = _typeEdited = ball != null;
    _specification = BallSpecifications.find(_brand.text, _name.text);
    _brand.addListener(_modelChanged);
    _name.addListener(_modelChanged);
  }

  @override
  void dispose() {
    _brand.removeListener(_modelChanged);
    _name.removeListener(_modelChanged);
    for (final field in [_brand, _name, _weight, _nickname, _notes]) {
      field.dispose();
    }
    _brandFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _modelChanged() {
    final specification = BallSpecifications.find(_brand.text, _name.text);
    setState(() {
      _specification = specification;
      if (!_materialEdited) _coverMaterial = specification?.material;
      if (!_typeEdited) _coverType = specification?.type;
    });
  }

  void _useSpecifications() => setState(() {
    _coverMaterial = _specification!.material;
    _coverType = _specification!.type;
    _materialEdited = _typeEdited = false;
  });

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveBall(
        BowlingBall(
          id: _id,
          name: _name.text.trim(),
          brand: _brand.text.trim(),
          weight: double.parse(_weight.text),
          nickname: _nickname.text.trim(),
          notes: _notes.text.trim(),
          retired: _retired,
          color: _color,
          coverMaterial: _coverMaterial,
          coverType: _coverType,
        ),
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save this ball. Your entries are still here; please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.ball == null ? 'Add a ball to your bag' : 'Edit your ball',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline suggestions. Enter any manufacturer or model, including older balls.',
                ),
                const SizedBox(height: 16),
                CatalogAutocomplete<String>(
                  controller: _brand,
                  focusNode: _brandFocus,
                  label: 'Manufacturer',
                  enabled: !_saving,
                  options: (q) => BallCatalog.manufacturers(
                    q,
                    widget.controller.data.balls,
                  ),
                  display: (v) => v,
                  onSelected: (_) => _nameFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                CatalogAutocomplete<BallModelSuggestion>(
                  controller: _name,
                  focusNode: _nameFocus,
                  label: 'Ball name / model',
                  required: true,
                  enabled: !_saving,
                  options: (q) => BallCatalog.models(
                    q,
                    _brand.text,
                    widget.controller.data.balls,
                  ),
                  display: (v) => v.name,
                  optionLabel: (v) => v.label,
                  onSelected: (v) => setState(() {
                    _brand.text = v.brand;
                    _name.text = v.name;
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weight,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Weight (lb)'),
                  validator: (v) {
                    final weight = double.tryParse(v ?? '');
                    return weight == null ||
                            !weight.isFinite ||
                            weight <= 0 ||
                            weight > 16
                        ? 'Use a weight greater than 0 and up to 16 lb.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nickname,
                  enabled: !_saving,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nickname (optional)',
                    hintText: 'e.g. League or Spare',
                    helperText: 'Leave blank to use the model and weight.',
                    helperMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BallColor>(
                  initialValue: _color,
                  isExpanded: true,
                  hint: const Text('Not set'),
                  decoration: const InputDecoration(
                    labelText: 'Color (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<BallColor>(child: Text('Not set')),
                    for (final color in BallColor.values)
                      DropdownMenuItem(
                        value: color,
                        child: BallColorLabel(color),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _color = value),
                ),
                const SizedBox(height: 16),
                if (_specification != null) ...[
                  const Text(
                    'Manufacturer specifications are available for this model. You can change either coverstock field.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _saving ? null : _useSpecifications,
                    child: const Text('Use model specifications'),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<CoverMaterial>(
                  key: ValueKey('cover-material-${_coverMaterial?.name}'),
                  initialValue: _coverMaterial,
                  isExpanded: true,
                  hint: const Text('Not set'),
                  decoration: const InputDecoration(
                    labelText: 'Cover material (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<CoverMaterial>(
                      child: Text('Not set'),
                    ),
                    for (final material in CoverMaterial.values)
                      DropdownMenuItem(
                        value: material,
                        child: Text(
                          material.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _materialEdited = true;
                          _coverMaterial = value;
                        }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CoverType>(
                  key: ValueKey('cover-type-${_coverType?.name}'),
                  initialValue: _coverType,
                  isExpanded: true,
                  hint: const Text('Not set'),
                  decoration: const InputDecoration(
                    labelText: 'Cover type (optional)',
                    helperText: 'Solid, pearl or hybrid, when known.',
                    helperMaxLines: 2,
                  ),
                  items: [
                    const DropdownMenuItem<CoverType>(child: Text('Not set')),
                    for (final type in CoverType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _typeEdited = true;
                          _coverType = value;
                        }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Coverstock, surface, favorite conditions…',
                  ),
                ),
                if (widget.ball != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Retired'),
                    subtitle: const Text(
                      'Keep its history, hide from new games.',
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
          child: Text(_saving ? 'Saving…' : 'Save ball'),
        ),
      ],
    ),
  );
}
