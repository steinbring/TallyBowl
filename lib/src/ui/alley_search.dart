import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/place_search.dart';

class AlleySearch extends StatefulWidget {
  const AlleySearch({super.key, required this.onSelected, this.service});
  final ValueChanged<PlaceSuggestion> onSelected;
  final PlaceSearch? service;
  @override
  State<AlleySearch> createState() => _AlleySearchState();
}

class _AlleySearchState extends State<AlleySearch> {
  final _query = TextEditingController();
  List<PlaceSuggestion> _results = [];
  String? _status;
  bool _busy = false;
  int _generation = 0;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _results = [];
      _status = null;
    });
    try {
      final results = await (widget.service ?? PlaceSearch.shared).search(
        _query.text,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _results = results;
          _status = results.isEmpty
              ? 'No matches. Try the alley’s name and city, or enter it below.'
              : 'Choose your venue and check its address.';
        });
      }
    } on PlaceSearchException catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _status = error.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _query,
        textInputAction: TextInputAction.search,
        maxLength: 120,
        decoration: const InputDecoration(
          labelText: 'Find an alley by name and city',
          hintText: 'Holler House, Milwaukee',
          counterText: '',
        ),
        onChanged: (_) => setState(() {
          _generation++;
          _results = [];
          _status = null;
        }),
        onSubmitted: (_) => _search(),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _busy ? null : _search,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
        label: Text(_busy ? 'Searching…' : 'Search OpenStreetMap'),
      ),
      const Text(
        'Search sends only these words to Photon. You can also enter an alley manually.',
        style: TextStyle(fontSize: 12),
      ),
      if (_status != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_status!, semanticsLabel: _status),
        ),
      for (final result in _results)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined),
          title: Text(result.name),
          subtitle: Text(result.address),
          onTap: () => widget.onSelected(result),
        ),
      TextButton(
        onPressed: () =>
            launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
        child: const Text(
          '© OpenStreetMap contributors · Search by Photon',
          style: TextStyle(fontSize: 11),
        ),
      ),
    ],
  );
}
