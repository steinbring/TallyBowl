import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/ball_catalog.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/inventory.dart';
import 'package:tallybowl/src/ui/ball_color.dart';
import 'package:tallybowl/src/ui/ball_dialog.dart';
import 'package:tallybowl/src/ui/common.dart';

class RetryController extends BowlController {
  RetryController() : super(null, const BowlData());
  bool fail = true;
  @override
  Future<void> saveBall(BowlingBall ball) async {
    if (fail) {
      fail = false;
      throw StateError('Disk unavailable');
    }
    await super.saveBall(ball);
  }
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> openBall(WidgetTester tester, BowlController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BallDialog(controller: controller),
            ),
            child: const Text('Add'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Add'));
  await tester.pumpAndSettle();
}

Future<void> chooseColor(WidgetTester tester, String label) async {
  final picker = find.byType(DropdownButtonFormField<BallColor>);
  await tester.ensureVisible(picker);
  await tester.tap(picker);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  test('catalog includes owned custom models, deduplicates and filters by manufacturer', () {
    const owned = [
      BowlingBall(id: 'old', name: 'Vintage Gold', brand: 'My brand'),
      BowlingBall(id: 'p', name: 'Phaze II', brand: 'Storm'),
    ];
    expect(BallCatalog.manufacturers('MY', owned), ['My brand']);
    expect(
      BallCatalog.models('vintage', 'My brand', owned).single.name,
      'Vintage Gold',
    );
    expect(BallCatalog.models('phaze', 'storm', owned).length, 1);
    expect(BallCatalog.models('phaze', 'Hammer', owned), isEmpty);
  });
  test(
    'expanded models remain searchable past the first eight suggestions',
    () {
      expect(
        BallCatalog.models('White Ball', 'Brunswick', []).single.name,
        'White Ball',
      );
      expect(
        BallCatalog.models('TZone Indigo', 'Brunswick', []).single.name,
        'TZone - Indigo Swirl',
      );
      expect(
        BallCatalog.models('The Spy', 'Radical', []).single.name,
        'The Spy',
      );
      expect(BallCatalog.models('The Spy', 'Brunswick', []), isEmpty);
      expect(
        BallCatalog.models('mesmerize', 'Brunswick', []).single.name,
        'Mesmerize',
        reason: 'Previously supported equipment remains available.',
      );
      for (final model in [
        ...BallCatalog.brunswickCurrent,
        ...BallCatalog.radicalCurrent,
      ]) {
        expect(
          BallCatalog.models(model.name, model.brand, []).map((v) => v.name),
          contains(model.name),
          reason: model.label,
        );
      }
    },
  );
  testWidgets('manufacturer and model suggestions fill consistent values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = BowlController(null, const BowlData());
    await openBall(tester, controller);
    await tester.enterText(field('Manufacturer'), 'Sto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storm').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Ball name / model'), 'phaze');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storm · Phaze II'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save ball'));
    await tester.pumpAndSettle();
    expect(controller.data.balls.single.name, 'Phaze II');
    expect(controller.data.balls.single.brand, 'Storm');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'phone form accepts custom models and retains entries after a failed save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = RetryController();
      await openBall(tester, controller);
      await tester.enterText(field('Manufacturer'), 'Custom brand');
      await tester.enterText(field('Ball name / model'), 'My vintage ball');
      await chooseColor(tester, 'Blue');
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your entries are still here'),
        findsOneWidget,
      );
      expect(find.text('My vintage ball'), findsOneWidget);
      expect(
        tester
            .state<FormFieldState<BallColor>>(
              find.byType(DropdownButtonFormField<BallColor>),
            )
            .value,
        BallColor.blue,
      );
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(controller.data.balls.single.name, 'My vintage ball');
      expect(controller.data.balls.single.color, BallColor.blue);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'ball color can be saved, edited and cleared in ${brightness.name} at 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = BowlController(null, const BowlData());
        addTearDown(controller.dispose);
        // The same dialog is used by adding and editing from My Bag.
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (_, _) => BagPage(controller: controller),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Add a ball'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Ball name / model'), 'My colorful ball');
        await chooseColor(tester, 'Purple');
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        expect(controller.data.balls.single.color, BallColor.purple);
        await tester.ensureVisible(find.text('Color: Purple'));
        expect(
          tester.widget<BallArt>(find.byType(BallArt)).color,
          BallColor.purple.swatch,
        );
        await tester.tap(find.text('My colorful ball'));
        await tester.pumpAndSettle();
        expect(
          tester
              .state<FormFieldState<BallColor>>(
                find.byType(DropdownButtonFormField<BallColor>),
              )
              .value,
          BallColor.purple,
        );
        await chooseColor(tester, 'Green');
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        expect(controller.data.balls.single.color, BallColor.green);
        await tester.tap(find.text('My colorful ball'));
        await tester.pumpAndSettle();
        expect(
          tester
              .state<FormFieldState<BallColor>>(
                find.byType(DropdownButtonFormField<BallColor>),
              )
              .value,
          BallColor.green,
        );
        await chooseColor(tester, 'Not set');
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        expect(controller.data.balls.single.color, isNull);
        expect(find.text('Color: Green'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
