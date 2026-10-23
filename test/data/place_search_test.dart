import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tallybowl/src/data/place_search.dart';

Map<String, dynamic> place({
  String name = 'Holler House',
  Object id = 123,
  Object lon = -87.93,
}) => {
  'type': 'Feature',
  'properties': {
    'name': name,
    'osm_type': 'N',
    'osm_id': id,
    'osm_key': 'amenity',
    'osm_value': 'pub',
    'housenumber': '2042',
    'street': 'West Lincoln Avenue',
    'city': 'Milwaukee',
  },
  'geometry': {
    'type': 'Point',
    'coordinates': [lon, 43.0],
  },
};
String responseBody(List<Object> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

void main() {
  test('uses documented JSON API, identifies app, encodes input and caches repeats', () async {
    var calls = 0;
    final service = PlaceSearch(
      clientFactory: () => MockClient((request) async {
        calls++;
        expect(request.url.queryParameters, {
          'q': 'Holler & House, Milwaukee',
          'limit': '5',
        });
        expect(request.headers['User-Agent'], contains('tallybowl.jws.app'));
        expect(request.followRedirects, isFalse);
        return http.Response(responseBody([place()]), 200);
      }),
    );
    final results = await service.search('  Holler & House, Milwaukee  ');
    expect(results.single.osmId, 'N/123');
    expect(results.single.address, '2042 West Lincoln Avenue, Milwaukee');
    expect(await service.search('holler & house, milwaukee'), same(results));
    expect(calls, 1);
  });
  test('rejects malformed data and filters invalid coordinates, identities and duplicates', () {
    final results = PlaceSearch.parse(
      responseBody([
        place(),
        place(),
        place(name: '', id: 2),
        place(id: 3, lon: 181),
        place(id: '123'),
        {'properties': {}},
        place(name: 'Other alley', id: 4),
      ]),
    );
    expect(results.map((r) => r.name), ['Holler House', 'Other alley']);
    expect(() => PlaceSearch.parse('{}'), throwsFormatException);
  });
  test('server throttling has a cooldown and no automatic retries', () async {
    var calls = 0;
    final service = PlaceSearch(
      clientFactory: () => MockClient((_) async {
        calls++;
        return http.Response('', 429, headers: {'retry-after': '60'});
      }),
    );
    await expectLater(
      service.search('Bowling Madison'),
      throwsA(isA<PlaceSearchException>()),
    );
    await expectLater(
      service.search('Bowling Chicago'),
      throwsA(isA<PlaceSearchException>()),
    );
    expect(calls, 1);
  });
  test(
    'bounds responses and refuses insecure endpoint configuration',
    () async {
      final service = PlaceSearch(
        clientFactory: () =>
            MockClient((_) async => http.Response('x' * (256 * 1024 + 1), 200)),
      );
      await expectLater(
        service.search('Large response'),
        throwsA(isA<PlaceSearchException>()),
      );
      await expectLater(
        PlaceSearch(endpoint: Uri.parse('http://example.com/api'))
            .search('No TLS'),
        throwsA(isA<PlaceSearchException>()),
      );
    },
  );
}
