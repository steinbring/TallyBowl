import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/place_search.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/alley_map.dart';
import 'package:tallybowl/src/ui/alley_search.dart';
import 'package:tallybowl/src/theme.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    testWidgets('map coordinates support large text and a keyboard at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: tallyBowlDarkTheme,
          home: AlleyMapPage(
            controller: BowlController(null, const BowlData()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enter coordinates'));
      await tester.tap(find.text('Enter coordinates'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(
        bottom: size.height > 500 ? 280 : 100,
      );
      await tester.pumpAndSettle();
      final latitude = find.widgetWithText(TextFormField, 'Latitude');
      final longitude = find.widgetWithText(TextFormField, 'Longitude');
      await tester.enterText(latitude, 'NaN');
      await tester.enterText(longitude, '999');
      await tester.ensureVisible(find.text('Use coordinates'));
      await tester.tap(find.text('Use coordinates'));
      await tester.pumpAndSettle();
      expect(find.text('Enter latitude from -90 to 90.'), findsOneWidget);
      await tester.enterText(latitude, '43');
      await tester.enterText(longitude, '-88');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Use coordinates'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use coordinates'));
      await tester.pumpAndSettle();
      expect(find.text('43.00000, -88.00000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'map completes when a selected suggestion reuses an existing venue',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = BowlController(
        null,
        const BowlData(
          alleys: [
            BowlingAlley(id: 'saved', name: 'Home lanes', osmId: 'N/123'),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => pickAlleyOnMap(context, controller),
                child: const Text('Open map'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open map'));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();
      tester
          .widget<AlleySearch>(find.byType(AlleySearch))
          .onSelected(
            const PlaceSuggestion(
              name: 'Home lanes',
              address: '123 Main',
              osmId: 'N/123',
              latitude: 43,
              longitude: -88,
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save alley'));
      await tester.pumpAndSettle();
      expect(controller.data.alleys.length, 1);
      expect(controller.data.alleys.single.id, 'saved');
      expect(find.byType(AlleyMapPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('map status uses readable dark-theme contrast', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlDarkTheme,
        home: AlleyMapPage(controller: BowlController(null, const BowlData())),
      ),
    );
    await tester.pumpAndSettle();
    final status = tester.widget<Text>(
      find.text('Choose a location on the map.'),
    );
    final foreground = status.style!.color!.computeLuminance();
    final background = tallyBowlDarkTheme.scaffoldBackgroundColor
        .computeLuminance();
    final lighter = foreground > background ? foreground : background;
    final darker = foreground > background ? background : foreground;
    expect((lighter + .05) / (darker + .05), greaterThanOrEqualTo(4.5));
  });
}
