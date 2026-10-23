import '../domain/models.dart';

class BallModelSuggestion {
  const BallModelSuggestion(this.brand, this.name);
  final String brand, name;
  String get label => '$brand · $name';
}

/// Small, manually maintained name-only starter list. See DATA_SOURCES.md for
/// first-party references. No prices, product claims, images or scraped feed.
abstract final class BallCatalog {
  // Brands represented by models are derived, so the two lists cannot drift.
  static const additionalBrands = ['Columbia 300', 'Radical'];
  static final List<String> brands = List.unmodifiable(
    {...starter.map((model) => model.brand), ...additionalBrands}.toList()
      ..sort(),
  );
  static const starter = [
    BallModelSuggestion('900 Global', 'Sublime Focus'),
    BallModelSuggestion('Brunswick', 'Mesmerize'),
    BallModelSuggestion('Brunswick', 'Rhino'),
    BallModelSuggestion('DV8', 'Trouble Maker'),
    BallModelSuggestion('Ebonite', 'Game Breaker 4'),
    BallModelSuggestion('Hammer', 'Black Widow 2.0 Hybrid'),
    BallModelSuggestion('Hammer', 'Black Widow 3.0'),
    BallModelSuggestion('MOTIV', 'Jackal Ghost V2'),
    BallModelSuggestion('MOTIV', 'Venom Shock'),
    BallModelSuggestion('Roto Grip', 'Hustle B-R-Y'),
    BallModelSuggestion('Roto Grip', 'Hustle M-M'),
    BallModelSuggestion('Roto Grip', 'Hustle RIP'),
    BallModelSuggestion('Roto Grip', 'Hustle X-RAY'),
    BallModelSuggestion('Roto Grip', 'Hyperdrive'),
    BallModelSuggestion('Roto Grip', 'Rockstar'),
    BallModelSuggestion('Storm', '!Q Tour A.I.'),
    BallModelSuggestion('Storm', 'Ion Pro'),
    BallModelSuggestion('Storm', 'Ion Pro Solid'),
    BallModelSuggestion('Storm', 'Phaze II'),
    BallModelSuggestion('Storm', 'Tropical Surge Black-Cherry'),
    BallModelSuggestion('Track', 'Cypher'),
    BallModelSuggestion('Track', 'Cyborg'),
  ];
  static String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static List<String> manufacturers(String query, Iterable<BowlingBall> owned) {
    final values = <String, String>{};
    for (final name in [...brands, ...owned.map((b) => b.brand)]) {
      if (name.trim().isNotEmpty) {
        values.putIfAbsent(_key(name), () => name.trim());
      }
    }
    return values.values.where((v) => _key(v).contains(_key(query))).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static List<BallModelSuggestion> models(
    String query,
    String brand,
    Iterable<BowlingBall> owned,
  ) {
    final values = <String, BallModelSuggestion>{};
    for (final model in [
      ...owned.map((b) => BallModelSuggestion(b.brand, b.name)),
      ...starter,
    ]) {
      if ((brand.trim().isEmpty || _key(model.brand) == _key(brand)) &&
          _key(model.name).contains(_key(query))) {
        values.putIfAbsent(
          '${_key(model.brand)}/${_key(model.name)}',
          () => model,
        );
      }
    }
    final matches = values.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return matches.take(8).toList();
  }
}
