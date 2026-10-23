import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.osmId,
    required this.latitude,
    required this.longitude,
  });
  final String name, address, osmId;
  final double latitude, longitude;
}

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Photon is queried only on explicit search, never on each keystroke. No
/// device location, journal, or photo is sent. Keep this shared across screens
/// so repeat requests share the bounded cache and server cooldown.
class PlaceSearch {
  PlaceSearch({http.Client Function()? clientFactory, Uri? endpoint})
    : _clientFactory = clientFactory ?? http.Client.new,
      _endpoint = endpoint ?? Uri.parse(AppConfig.placeSearchUrl);
  static final shared = PlaceSearch();
  final http.Client Function() _clientFactory;
  final Uri _endpoint;
  final _cache = <String, ({DateTime saved, List<PlaceSuggestion> places})>{};
  DateTime _nextRequest = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;

  Future<List<PlaceSuggestion>> search(String query) async {
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (q.length < 3 || q.length > 120) {
      throw const PlaceSearchException(
        'Enter 3–120 characters, including the city.',
      );
    }
    final key = q.toLowerCase();
    final now = DateTime.now();
    final cached = _cache[key];
    if (cached != null &&
        now.difference(cached.saved) < const Duration(minutes: 10)) {
      return cached.places;
    }
    if (_busy || now.isBefore(_nextRequest)) {
      throw const PlaceSearchException(
        'Please wait a moment before searching again.',
      );
    }
    if (_endpoint.scheme != 'https' ||
        _endpoint.host.isEmpty ||
        _endpoint.userInfo.isNotEmpty) {
      throw const PlaceSearchException(
        'Place search is not configured. Enter your alley manually.',
      );
    }
    _busy = true;
    _nextRequest = now.add(const Duration(seconds: 1));
    final client = _clientFactory();
    try {
      final places = await _fetch(
        client,
        q,
      ).timeout(const Duration(seconds: 12));
      if (_cache.length >= 30) _cache.remove(_cache.keys.first);
      _cache[key] = (saved: DateTime.now(), places: places);
      return places;
    } on PlaceSearchException {
      rethrow;
    } catch (_) {
      throw const PlaceSearchException(
        'Place search is unavailable. Try later or enter your alley manually.',
      );
    } finally {
      client.close();
      _busy = false;
    }
  }

  Future<List<PlaceSuggestion>> _fetch(http.Client client, String query) async {
    // Search all matching POIs: some real alleys are primarily tagged as pubs
    // or entertainment centres. The user confirms the venue before saving it.
    final request = http.Request(
      'GET',
      _endpoint.replace(queryParameters: {'q': query, 'limit': '5'}),
    )..followRedirects = false;
    request.headers.addAll({
      'User-Agent': AppConfig.userAgent,
      'Accept': 'application/json',
    });
    final response = await client.send(request);
    if (response.statusCode == 429 || response.statusCode == 503) {
      final seconds = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
      _nextRequest = DateTime.now().add(
        Duration(seconds: seconds.clamp(1, 3600)),
      );
      throw const PlaceSearchException(
        'The place service is busy. Please try later or enter your alley manually.',
      );
    }
    if (response.statusCode != 200) {
      throw const FormatException('Place service response.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > 256 * 1024) {
        throw const FormatException('Place response too large.');
      }
      bytes.addAll(chunk);
    }
    return parse(utf8.decode(bytes));
  }

  static List<PlaceSuggestion> parse(String body) {
    final document = jsonDecode(body);
    if (document is! Map || document['features'] is! List) {
      throw const FormatException('Invalid place response.');
    }
    final results = <PlaceSuggestion>[];
    final ids = <String>{};
    for (final feature in (document['features'] as List).take(50)) {
      if (feature is! Map) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map ||
          geometry is! Map ||
          geometry['type'] != 'Point') {
        continue;
      }
      String field(String key) {
        final value = properties[key];
        if (value is! String) return '';
        final cleaned = value.trim().replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
        return cleaned.substring(0, cleaned.length.clamp(0, 300));
      }

      final coordinates = geometry['coordinates'];
      final type = field('osm_type').toUpperCase();
      final id = properties['osm_id'];
      final name = field('name');
      if (name.isEmpty ||
          !['N', 'W', 'R'].contains(type) ||
          id is! int ||
          id <= 0 ||
          coordinates is! List ||
          coordinates.length < 2 ||
          coordinates[0] is! num ||
          coordinates[1] is! num) {
        continue;
      }
      final lon = (coordinates[0] as num).toDouble();
      final lat = (coordinates[1] as num).toDouble();
      final osmId = '$type/$id';
      if (!lat.isFinite ||
          lat.abs() > 90 ||
          !lon.isFinite ||
          lon.abs() > 180 ||
          !ids.add(osmId)) {
        continue;
      }
      final street = [
        field('housenumber'),
        field('street'),
      ].where((v) => v.isNotEmpty).join(' ');
      final address = [
        street,
        field('city'),
        field('state'),
        field('postcode'),
        field('country'),
      ].where((v) => v.isNotEmpty).toSet().join(', ');
      results.add(
        PlaceSuggestion(
          name: name,
          address: address,
          osmId: osmId,
          latitude: lat,
          longitude: lon,
        ),
      );
      if (results.length == 5) break;
    }
    return List.unmodifiable(results);
  }
}
