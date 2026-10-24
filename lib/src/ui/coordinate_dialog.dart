import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng?> enterCoordinates(BuildContext context, {LatLng? initial}) =>
    showDialog<LatLng>(
      context: context,
      builder: (_) => _CoordinateDialog(initial: initial),
    );

class _CoordinateDialog extends StatefulWidget {
  const _CoordinateDialog({this.initial});
  final LatLng? initial;

  @override
  State<_CoordinateDialog> createState() => _CoordinateDialogState();
}

class _CoordinateDialogState extends State<_CoordinateDialog> {
  late final _latitude = TextEditingController(
    text: widget.initial?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.initial?.longitude.toString(),
  );
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                namesRoute: true,
                child: Text(
                  'Enter map coordinates',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use decimal degrees. North/east are positive; south/west are negative.',
              ),
              const SizedBox(height: 16),
              for (final field in [
                (_latitude, 'Latitude', 90),
                (_longitude, 'Longitude', 180),
              ]) ...[
                TextFormField(
                  controller: field.$1,
                  decoration: InputDecoration(labelText: field.$2),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (text) {
                    final value = double.tryParse(text ?? '');
                    return value == null ||
                            !value.isFinite ||
                            value.abs() > field.$3
                        ? 'Enter ${field.$2.toLowerCase()} from -${field.$3} to ${field.$3}.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        Navigator.pop(
                          context,
                          LatLng(
                            double.parse(_latitude.text),
                            double.parse(_longitude.text),
                          ),
                        );
                      }
                    },
                    child: const Text('Use coordinates'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
