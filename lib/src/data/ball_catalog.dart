import '../domain/models.dart';

class BallModelSuggestion {
  const BallModelSuggestion(this.brand, this.name);
  final String brand, name;
  String get label => '$brand · $name';
}

/// Offline name-only suggestions. Current Brunswick/Radical lists were checked
/// against their official catalogs on 2026-10-30; see DATA_SOURCES.md.
/// Older starter and owned/custom models remain available. No runtime feed.
abstract final class BallCatalog {
  // Brands represented by models are derived, so the two lists cannot drift.
  static const additionalBrands = ['Columbia 300'];
  static final List<String> brands = List.unmodifiable(
    {...starter.map((model) => model.brand), ...additionalBrands}.toList()
      ..sort(),
  );
  // https://brunswickbowling.com/products/balls/current (50 models, checked 2026-10-30).
  static const brunswickCurrent = [
    BallModelSuggestion('Brunswick', 'Alert'),
    BallModelSuggestion('Brunswick', 'Butterflies'),
    BallModelSuggestion('Brunswick', 'Combat Hybrid'),
    BallModelSuggestion('Brunswick', 'Combat Solid'),
    BallModelSuggestion('Brunswick', 'Crown 78U'),
    BallModelSuggestion('Brunswick', 'Crown Victory Pearl'),
    BallModelSuggestion('Brunswick', 'Danger Zone'),
    BallModelSuggestion('Brunswick', 'Danger Zone Purple Ice'),
    BallModelSuggestion('Brunswick', 'Flaming Skull'),
    BallModelSuggestion('Brunswick', 'Fury - Emerald / Black'),
    BallModelSuggestion('Brunswick', 'Fury - Orange / Red'),
    BallModelSuggestion('Brunswick', 'Fury - Pink / Ice / Silver'),
    BallModelSuggestion('Brunswick', 'Fury - Purple / Blue'),
    BallModelSuggestion('Brunswick', 'Fury - Red / Blue / Black'),
    BallModelSuggestion('Brunswick', 'Hearts'),
    BallModelSuggestion('Brunswick', 'Infinity Quest Pearl'),
    BallModelSuggestion('Brunswick', 'Lizard Eye'),
    BallModelSuggestion('Brunswick', 'Paint Splatter'),
    BallModelSuggestion('Brunswick', 'Purple Rhino Pro'),
    BallModelSuggestion('Brunswick', 'Retro Flowers'),
    BallModelSuggestion('Brunswick', 'Rhino - Blue / Cadet Grey / Silver'),
    BallModelSuggestion('Brunswick', 'Rhino - Carbon / Lime / Silver'),
    BallModelSuggestion('Brunswick', 'Rhino - Purple / Black'),
    BallModelSuggestion('Brunswick', 'Rhino - Purple / Pink / Berry'),
    BallModelSuggestion('Brunswick', 'Rhino - Red / Black / Gold Pearl'),
    BallModelSuggestion('Brunswick', 'Sea Turtle'),
    BallModelSuggestion('Brunswick', 'Shark'),
    BallModelSuggestion('Brunswick', 'Smiley Face'),
    BallModelSuggestion('Brunswick', 'Stars and Stripes'),
    BallModelSuggestion('Brunswick', 'Strategy'),
    BallModelSuggestion('Brunswick', 'Strategy Logic'),
    BallModelSuggestion('Brunswick', 'Team Brunswick White'),
    BallModelSuggestion('Brunswick', 'Tie-Dye Burst'),
    BallModelSuggestion('Brunswick', 'Tiger'),
    BallModelSuggestion('Brunswick', 'TZone - Berry Blast'),
    BallModelSuggestion('Brunswick', 'TZone - Black / Purple / Silver'),
    BallModelSuggestion('Brunswick', 'TZone - Caribbean Blue'),
    BallModelSuggestion('Brunswick', 'TZone - Deep Space'),
    BallModelSuggestion('Brunswick', 'TZone - Frozen Bliss'),
    BallModelSuggestion('Brunswick', 'TZone - Indigo Swirl'),
    BallModelSuggestion('Brunswick', 'TZone - Night Sky'),
    BallModelSuggestion('Brunswick', 'TZone - Ocean Reef'),
    BallModelSuggestion('Brunswick', 'TZone - Peek-A-Boo Berry'),
    BallModelSuggestion('Brunswick', 'TZone - Scarlet / Gold / Black'),
    BallModelSuggestion('Brunswick', 'TZone - Scarlet Shadow'),
    BallModelSuggestion('Brunswick', 'TZone - Wild Orchid'),
    BallModelSuggestion('Brunswick', 'Unicorn'),
    BallModelSuggestion('Brunswick', 'Warning Alert'),
    BallModelSuggestion('Brunswick', 'White Ball'),
    BallModelSuggestion('Brunswick', 'World'),
  ];
  // https://radicalbowling.com/products/balls/current (13 models, checked 2026-10-30).
  static const radicalCurrent = [
    BallModelSuggestion('Radical', 'Deep Impact'),
    BallModelSuggestion('Radical', 'Evil Eye'),
    BallModelSuggestion('Radical', 'Evil Eye Pearl'),
    BallModelSuggestion('Radical', 'Guru Oracle Pearl'),
    BallModelSuggestion('Radical', 'Intel Recon Hybrid'),
    BallModelSuggestion('Radical', 'Intel Tour'),
    BallModelSuggestion('Radical', 'No Doubt Hybrid'),
    BallModelSuggestion('Radical', 'Outer Limits Black Hole'),
    BallModelSuggestion('Radical', 'Revenge Pearl'),
    BallModelSuggestion('Radical', 'Revenge Solid'),
    BallModelSuggestion('Radical', 'The Spy'),
    BallModelSuggestion('Radical', 'Vexed'),
    BallModelSuggestion('Radical', 'Vexed Variant'),
  ];

  static const starter = [
    ...brunswickCurrent,
    ...radicalCurrent,
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
