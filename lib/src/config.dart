import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppConfig {
  static const name = 'TallyBowl!';
  static const tagline = 'How you bowled, tonight.';
  static const website = 'https://tallybowl.jws.app';
  static const websiteLabel = 'tallybowl.jws.app';
  static const blueskyUrl = 'https://bsky.app/profile/tallybowl.jws.app';
  static const blueskyHandle = '@tallybowl.jws.app';
  static const goToSocialUrl = 'https://jws.social/@tallybowl';
  static const goToSocialHandle = '@tallybowl@jws.social';
  // Development tile service. Select production hosting before release.
  static const tileUrl = String.fromEnvironment(
    'TALLYBOWL_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static String _userAgent = 'TallyBowl (+$website)';
  static String get userAgent => _userAgent;
  static Future<void> initialize({
    Future<PackageInfo> Function()? packageInfo,
  }) async {
    try {
      final info = await (packageInfo ?? PackageInfo.fromPlatform)();
      final version = info.version.replaceAll(RegExp(r'[^a-zA-Z0-9.+_-]'), '');
      final build = info.buildNumber.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
      _userAgent = version.isEmpty
          ? 'TallyBowl (+$website)'
          : 'TallyBowl/$version${build.isEmpty ? '' : '+$build'} (+$website)';
    } catch (_) {
      // Package metadata is useful identification, never a launch requirement.
      _userAgent = 'TallyBowl (+$website)';
    }
  }

  static const tileAttribution = String.fromEnvironment(
    'TALLYBOWL_TILE_ATTRIBUTION',
    defaultValue: 'OpenStreetMap contributors',
  );
  static const tileAttributionUrl = String.fromEnvironment(
    'TALLYBOWL_TILE_ATTRIBUTION_URL',
    defaultValue: 'https://www.openstreetmap.org/copyright',
  );
  static const placeSearchUrl = String.fromEnvironment(
    'TALLYBOWL_PHOTON_URL',
    defaultValue: 'https://photon.komoot.io/api/',
  );
}
