import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/config.dart';
import 'package:tallybowl/src/data/ball_catalog.dart';
import 'package:tallybowl/src/data/place_search.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/game_editor.dart';

void main() {
  test(
    'service identification uses installed version and has a safe fallback',
    () async {
      await AppConfig.initialize(
        packageInfo: () async => PackageInfo(
          appName: 'TallyBowl!',
          packageName: 'app.jws.tallybowl',
          version: '2.3.4',
          buildNumber: '19',
        ),
      );
      expect(
        AppConfig.userAgent,
        'TallyBowl/2.3.4+19 (+https://tallybowl.jws.app)',
      );
      await AppConfig.initialize(
        packageInfo: () async => throw StateError('Unavailable'),
      );
      expect(AppConfig.userAgent, 'TallyBowl (+https://tallybowl.jws.app)');
    },
  );
  test(
    'starter catalog names are nonempty, unique and linked to known brands',
    () {
      expect(BallCatalog.starter, isNotEmpty);
      final keys = <String>{};
      for (final model in BallCatalog.starter) {
        expect(model.name.trim(), isNotEmpty);
        expect(BallCatalog.brands, contains(model.brand));
        expect(keys.add('${model.brand}/${model.name}'.toLowerCase()), isTrue);
      }
      expect(BallCatalog.brands.toSet().length, BallCatalog.brands.length);
    },
  );
  test(
    'place cache evicts the least recently used entry and expires fetches',
    () async {
      var now = DateTime(2026, 10, 23);
      final calls = <String>[];
      final service = PlaceSearch(
        clock: () => now,
        clientFactory: () => MockClient((request) async {
          calls.add(request.url.queryParameters['q']!);
          return http.Response('{"features":[]}', 200);
        }),
      );
      for (var i = 0; i < 30; i++) {
        await service.search('Venue $i');
        now = now.add(const Duration(seconds: 2));
      }
      await service.search('Venue 0'); // Refresh usage order, not the TTL.
      await service.search('Venue 30');
      now = now.add(const Duration(seconds: 2));
      await service.search('Venue 0');
      expect(calls.where((q) => q == 'Venue 0').length, 1);
      await service.search('Venue 1');
      expect(calls.where((q) => q == 'Venue 1').length, 2);
      now = now.add(const Duration(minutes: 11));
      await service.search('Venue 0');
      expect(calls.where((q) => q == 'Venue 0').length, 2);
    },
  );
  testWidgets(
    'primary ball resets when untagged without recreating the dropdown',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BowlingSession(
        id: 's',
        alleyId: 'a',
        startedAt: DateTime(2026, 10, 23),
      );
      final game = BowlingGame(
        id: 'g',
        sessionId: 's',
        frames: List.filled(10, '9-'),
        createdAt: session.startedAt,
        ballIds: const ['a', 'b'],
        primaryBallId: 'a',
      );
      final controller = BowlController(
        null,
        BowlData(
          alleys: const [BowlingAlley(id: 'a', name: 'Home')],
          balls: const [
            BowlingBall(id: 'a', name: 'Ball A'),
            BowlingBall(id: 'b', name: 'Ball B'),
          ],
          sessions: [session],
          games: [game],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    openGameEditor(context, controller, session, game: game),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final dropdown = find.byType(DropdownButtonFormField<String>);
      final state = tester.state<FormFieldState<String>>(dropdown);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Ball A'));
      await tester.tap(find.widgetWithText(FilterChip, 'Ball A'));
      await tester.pumpAndSettle();
      expect(tester.state(dropdown), same(state));
      expect(state.value, '');
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ball B').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save game'));
      await tester.pumpAndSettle();
      expect(controller.data.games.single.primaryBallId, 'b');
      expect(controller.data.games.single.ballIds, ['b']);
      expect(find.text('Game saved · 90'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
