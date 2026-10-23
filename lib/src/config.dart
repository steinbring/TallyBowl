abstract final class AppConfig {
  static const name = 'TallyBowl!';
  static const tagline = 'How you bowled, tonight.';
  static const website = 'https://tallybowl.jws.app';
  static const websiteLabel = 'tallybowl.jws.app';
  // Development tile service. Select production hosting before release.
  static const tileUrl = String.fromEnvironment(
    'TALLYBOWL_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const userAgent = 'TallyBowl/0.1 (+https://tallybowl.jws.app)';
}
