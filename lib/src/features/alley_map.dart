import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../config.dart';
import '../domain/models.dart';
import '../theme.dart';
import '../ui/dialogs.dart';

Future<void> pickAlleyOnMap(BuildContext context, BowlController controller) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AlleyMapPage(controller: controller)),
    );

class AlleyMapPage extends StatefulWidget {
  const AlleyMapPage({super.key, required this.controller});
  final BowlController controller;
  @override
  State<AlleyMapPage> createState() => _AlleyMapPageState();
}

class _AlleyMapPageState extends State<AlleyMapPage> {
  final _map = MapController();
  LatLng? _selected;
  bool _failed = false;
  int _tileGeneration = 0;
  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final id = widget.controller.newId();
    await editAlley(
      context,
      widget.controller,
      BowlingAlley(
        id: id,
        name: '',
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
      ),
    );
    if (mounted && widget.controller.data.alley(id) != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = widget.controller.data.alleys
        .where((a) => a.latitude != null && !a.retired)
        .toList();
    final start = located.isEmpty
        ? const LatLng(20, 0)
        : LatLng(located.last.latitude!, located.last.longitude!);
    return Scaffold(
      appBar: AppBar(title: const Text('Find your lanes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Zoom to your alley, then tap to place a pin.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                OutlinedButton.icon(
                  onPressed: () => editAlley(context, widget.controller),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Enter alley manually'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: start,
                    initialZoom: located.isEmpty ? 2 : 13,
                    minZoom: 2,
                    maxZoom: 19,
                    onTap: (_, point) => setState(() => _selected = point),
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_tileGeneration),
                      urlTemplate: AppConfig.tileUrl,
                      userAgentPackageName: 'app.jws.tallybowl',
                      panBuffer: 0,
                      keepBuffer: 0,
                      tileProvider: NetworkTileProvider(
                        headers: {'User-Agent': AppConfig.userAgent},
                      ),
                      errorTileCallback: (_, error, stack) {
                        if (!_failed && mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _failed = true);
                          });
                        }
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        for (final alley in located)
                          Marker(
                            point: LatLng(alley.latitude!, alley.longitude!),
                            width: 44,
                            height: 44,
                            child: Tooltip(
                              message: alley.name,
                              child: IconButton(
                                onPressed: () => setState(
                                  () => _selected = LatLng(
                                    alley.latitude!,
                                    alley.longitude!,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.location_on,
                                  size: 36,
                                  color: BowlColors.ink,
                                ),
                              ),
                            ),
                          ),
                        if (_selected != null)
                          Marker(
                            point: _selected!,
                            width: 56,
                            height: 56,
                            child: const Icon(
                              Icons.location_on,
                              size: 48,
                              color: BowlColors.orange,
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Card(
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: () => _map.move(
                            _map.camera.center,
                            (_map.camera.zoom + 1).clamp(2, 19),
                          ),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: () => _map.move(
                            _map.camera.center,
                            (_map.camera.zoom - 1).clamp(2, 19),
                          ),
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_failed)
                  Positioned(
                    left: 16,
                    right: 76,
                    top: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Map tiles couldn’t load. Manual alley entry is still available.',
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _failed = false;
                                _tileGeneration++;
                              }),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _selected == null
                        ? 'Choose a location on the map.'
                        : '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: BowlColors.muted),
                  ),
                  FilledButton.icon(
                    onPressed: _selected == null ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Use this location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
