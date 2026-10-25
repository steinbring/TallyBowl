import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/data/place_search.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/theme.dart';
import 'package:tallybowl/src/ui/branding.dart';
import 'package:tallybowl/src/ui/alley_dialog.dart';
import 'package:tallybowl/src/ui/ball_dialog.dart';

Future<void> savePreview(GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(
    '${(await getTemporaryDirectory()).path}/tallybowl-$name.png',
  );
  await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
  debugPrint('Preview: ${file.path}');
  image.dispose();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native forms support manufacturer selection and OSM suggestions',
    (tester) async {
      final controller = BowlController(null, const BowlData());
      final preview = GlobalKey();
      final service = PlaceSearch(
        clientFactory: () => MockClient(
          (_) async => http.Response(
            '''{"features":[{"properties":{"name":"Holler House","osm_type":"N","osm_id":12168828291,"housenumber":"2042","street":"West Lincoln Avenue","city":"Milwaukee","state":"WI","postcode":"53215","country":"United States"},"geometry":{"type":"Point","coordinates":[-87.9395795,43.0031865]}}]}''',
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: preview,
          child: MaterialApp(
            theme: tallyBowlTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: Wrap(
                    spacing: 16,
                    children: [
                      FilledButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => BallDialog(controller: controller),
                        ),
                        child: const Text('Add ball'),
                      ),
                      FilledButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => AlleyDialog(
                            controller: controller,
                            searchService: service,
                          ),
                        ),
                        child: const Text('Add alley'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add ball'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(field('Manufacturer'), 'Sto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Storm').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('Ball name / model'), 'phaze');
      await tester.pumpAndSettle();
      await savePreview(preview, 'ball-suggestions');
      await tester.tap(find.text('Storm · Phaze II'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(controller.data.balls.single.name, 'Phaze II');
      await tester.tap(find.text('Add alley'));
      await tester.pumpAndSettle();
      await tester.enterText(
        field('Find an alley by name and city'),
        'Holler House, Milwaukee',
      );
      await tester.tap(find.text('Search OpenStreetMap'));
      await tester.pumpAndSettle();
      await savePreview(preview, 'alley-suggestions');
      await tester.tap(find.text('Holler House'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save alley'));
      await tester.pumpAndSettle();
      expect(controller.data.alleys.single.osmId, 'N/12168828291');
    },
  );
  testWidgets('renders the adaptive dashboard in both themes with large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    for (final brightness in [Brightness.light, Brightness.dark]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      final key = GlobalKey();
      final controller = BowlController(
        null,
        const BowlData(
          profile: BowlerProfile(name: 'Sample bowler'),
          balls: [BowlingBall(id: 'b', name: 'Phaze II', brand: 'Storm')],
          alleys: [BowlingAlley(id: 'a', name: 'Sample lanes')],
        ),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: TallyBowlApp(controller: controller),
        ),
      );
      await precacheImage(
        const AssetImage(TallyBowlLogo.asset),
        tester.element(find.byType(TallyBowlLogo).first),
      );
      await tester.pumpAndSettle();
      await savePreview(key, '${brightness.name}-dashboard');
      expect(tester.takeException(), isNull);
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  testWidgets('renders the committed bowler branding at launcher sizes', (
    tester,
  ) async {
    for (final mac in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox.square(
                    dimension: 1024,
                    child: Padding(
                      padding: EdgeInsets.all(mac ? 64 : 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: BowlColors.ink,
                          borderRadius: mac
                              ? BorderRadius.circular(196)
                              : BorderRadius.zero,
                        ),
                        child: ClipRRect(
                          borderRadius: mac
                              ? BorderRadius.circular(196)
                              : BorderRadius.zero,
                          child: Image.asset(
                            'assets/branding/tallybowl-logo.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await savePreview(key, mac ? 'icon-mac' : 'icon');
    }
  });
}
