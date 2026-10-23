import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/ball_catalog.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/ui/ball_dialog.dart';

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
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your entries are still here'),
        findsOneWidget,
      );
      expect(find.text('My vintage ball'), findsOneWidget);
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(controller.data.balls.single.name, 'My vintage ball');
      expect(tester.takeException(), isNull);
    },
  );
}
