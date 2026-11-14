import '../domain/models.dart';

class BallSpecification {
  const BallSpecification(this.material, {this.type, required this.sourceUrl});
  final CoverMaterial material;
  final CoverType? type;
  final String sourceUrl;
}

/// Offline manufacturer specifications, checked 2026-11-10. See DATA_SOURCES.md.
/// Unknown names/variants stay unset; user choices take precedence.
abstract final class BallSpecifications {
  static const checkedOn = '2026-11-10';
  static BallSpecification? find(String brand, String model) =>
      _models['${_key(brand)}/${_key(model)}'];
  static String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static const _models = <String, BallSpecification>{
    'brunswick/alert': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/alert',
    ),
    'brunswick/butterflies': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/butterflies',
    ),
    'brunswick/combathybrid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/combat-hybrid',
    ),
    'brunswick/combatsolid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/combat-solid',
    ),
    'brunswick/crown78u': BallSpecification(
      CoverMaterial.urethane,
      type: CoverType.solid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/crown-78u',
    ),
    'brunswick/crownvictorypearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/crown-victory-pearl',
    ),
    'brunswick/dangerzone': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/danger-zone',
    ),
    'brunswick/dangerzonepurpleice': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/danger-zone-purple-ice',
    ),
    'brunswick/flamingskull': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/flaming-skull',
    ),
    'brunswick/furyemeraldblack': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/fury-emerald-black',
    ),
    'brunswick/furyorangered': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/fury-orange-red',
    ),
    'brunswick/furypinkicesilver': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/fury-pink-ice-silver',
    ),
    'brunswick/furypurpleblue': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/fury-purple-blue',
    ),
    'brunswick/furyredblueblack': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/fury-red-blue-black',
    ),
    'brunswick/hearts': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/hearts',
    ),
    'brunswick/infinityquestpearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/infinity-quest-pearl',
    ),
    'brunswick/lizardeye': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/lizard-eye',
    ),
    'brunswick/mesmerize': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/retired/mesmerize',
    ),
    'brunswick/paintsplatter': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/paint-splatter',
    ),
    'brunswick/purplerhinopro': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/purple-rhino-pro',
    ),
    'brunswick/retroflowers': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/retro-flowers',
    ),
    'brunswick/rhinobluecadetgreysilver': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/rhino-blue-cadet-grey-silver',
    ),
    'brunswick/rhinocarbonlimesilver': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/rhino-carbon-lime-silver',
    ),
    'brunswick/rhinopurpleblack': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/rhino-purple-black',
    ),
    'brunswick/rhinopurplepinkberry': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/rhino-purple-pink-berry',
    ),
    'brunswick/rhinoredblackgoldpearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/rhino-red-black-gold-pearl',
    ),
    'brunswick/seaturtle': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/sea-turtle',
    ),
    'brunswick/shark': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/shark',
    ),
    'brunswick/smileyface': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/smiley-face',
    ),
    'brunswick/starsandstripes': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/stars-and-stripes',
    ),
    'brunswick/strategy': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/strategy',
    ),
    'brunswick/strategylogic': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/strategy-logic',
    ),
    'brunswick/teambrunswickwhite': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/team-brunswick-white',
    ),
    'brunswick/tiedyeburst': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/tie-dye-burst',
    ),
    'brunswick/tiger': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tiger',
    ),
    'brunswick/tzone': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.nyc3.cdn.digitaloceanspaces.com/production/downloads/Ball-Info-Sheets/TZone_Info_Sheet.pdf',
    ),
    'brunswick/tzoneberryblast': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-berry-blast',
    ),
    'brunswick/tzoneblackpurplesilver': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-black-purple-silver',
    ),
    'brunswick/tzonecaribbeanblue': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-caribbean-blue',
    ),
    'brunswick/tzonedeepspace': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-deep-space',
    ),
    'brunswick/tzonefrozenbliss': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-frozen-bliss',
    ),
    'brunswick/tzoneindigoswirl': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-indigo-swirl',
    ),
    'brunswick/tzonenightsky': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/tzone-night-sky',
    ),
    'brunswick/tzoneoceanreef': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-ocean-reef',
    ),
    'brunswick/tzonepeekabooberry': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-peek-a-boo-berry',
    ),
    'brunswick/tzonescarletgoldblack': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-scarlet-gold-black',
    ),
    'brunswick/tzonescarletshadow': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-scarlet-shadow',
    ),
    'brunswick/tzonewildorchid': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/tzone-wild-orchid',
    ),
    'brunswick/unicorn': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/unicorn',
    ),
    'brunswick/warningalert': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/warning-alert',
    ),
    'brunswick/whiteball': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl:
          'https://brunswickbowling.com/products/balls/current/white-ball',
    ),
    'brunswick/world': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://brunswickbowling.com/products/balls/current/world',
    ),
    'ebonite/gamebreaker4': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://ebonite.com/products/game-breaker-4',
    ),
    'hammer/blackwidow20hybrid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl: 'https://hammerbowling.com/products/black-widow-2-0-hybrid',
    ),
    'hammer/blackwidow30': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://hammerbowling.com/products/black-widow-3-0',
    ),
    'motiv/venomshock': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://www.motivbowling.com/userfiles/filemanager/nenv0mnzlwlkte5npbl5',
    ),
    'radical/deepimpact': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/deep-impact',
    ),
    'radical/evileye': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/evil-eye',
    ),
    'radical/evileyepearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/evil-eye-pearl',
    ),
    'radical/guruoraclepearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/guru-oracle-pearl',
    ),
    'radical/intelreconhybrid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/intel-recon-hybrid',
    ),
    'radical/inteltour': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/intel-tour',
    ),
    'radical/nodoubthybrid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.hybrid,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/no-doubt-hybrid',
    ),
    'radical/outerlimitsblackhole': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/outer-limits-black-hole',
    ),
    'radical/revengepearl': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.pearl,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/revenge-pearl',
    ),
    'radical/revengesolid': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/revenge-solid',
    ),
    'radical/thespy': BallSpecification(
      CoverMaterial.polyester,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/the-spy',
    ),
    'radical/vexed': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://radicalbowling.com/products/balls/current/vexed',
    ),
    'radical/vexedvariant': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl:
          'https://radicalbowling.com/products/balls/current/vexed-variant',
    ),
    'storm/phazeii': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://www.stormbowling.com/storm-phaze-ii-bowling-ball',
    ),
    'track/cypher': BallSpecification(
      CoverMaterial.reactiveResin,
      type: CoverType.solid,
      sourceUrl: 'https://trackbowling.com/products/cypher',
    ),
  };
}
