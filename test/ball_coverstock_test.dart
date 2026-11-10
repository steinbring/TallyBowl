import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/ball_catalog.dart';
import 'package:tallybowl/src/data/ball_specifications.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/inventory.dart';
import 'package:tallybowl/src/ui/ball_dialog.dart';

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Finder picker<T>() => find.byType(DropdownButtonFormField<T>);
T? selected<T>(WidgetTester tester) =>
    tester.state<FormFieldState<T>>(picker<T>()).value;
Future<void> choose<T>(WidgetTester tester, String label) async {
  await tester.ensureVisible(picker<T>());
  await tester.tap(picker<T>());
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> host(
  WidgetTester tester,
  BowlController controller, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BallDialog(
                controller: controller,
                ball: controller.data.balls.firstOrNull,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

class RetryCoverController extends BowlController {
  RetryCoverController(BowlData data) : super(null, data);
  bool fail = true;
  @override
  Future<void> saveBall(BowlingBall ball) async {
    if (fail) {
      fail = false;
      throw StateError('Test write failure');
    }
    await super.saveBall(ball);
  }
}

void main() {
  test('all retained Brunswick/Radical variants have verified exact specifications', () {
    for (final model in [
      ...BallCatalog.brunswickCurrent,
      ...BallCatalog.radicalCurrent,
    ]) {
      final spec = BallSpecifications.find(model.brand, model.name);
      expect(spec, isNotNull, reason: model.label);
      expect(Uri.parse(spec!.sourceUrl).scheme, 'https');
    }
    final solid = BallSpecifications.find(
      'Brunswick',
      'Rhino - Purple / Black',
    )!;
    final pearl = BallSpecifications.find(
      'Brunswick',
      'Rhino - Purple / Pink / Berry',
    )!;
    expect(
      (solid.material, solid.type),
      (CoverMaterial.reactiveResin, CoverType.solid),
    );
    expect(
      (pearl.material, pearl.type),
      (CoverMaterial.reactiveResin, CoverType.pearl),
    );
    expect(
      BallSpecifications.find('Brunswick', 'Fury - Emerald / Black')!.type,
      CoverType.hybrid,
    );
    expect(
      BallSpecifications.find('Radical', 'Vexed Variant')!.type,
      CoverType.solid,
    );
    expect(
      BallSpecifications.find('Radical', 'The Spy')!.material,
      CoverMaterial.polyester,
    );
    expect(
      BallSpecifications.find('Brunswick', 'Crown 78U')!.material,
      CoverMaterial.urethane,
    );
    expect(
      BallSpecifications.find('Brunswick', 'Crown 78U')!.type,
      CoverType.solid,
    );
    expect(
      BallSpecifications.find('Brunswick', 'TZone')!.material,
      CoverMaterial.polyester,
    );
    expect(BallSpecifications.find('Brunswick', 'TZone')!.type, isNull);
    expect(BallSpecifications.find('Storm', 'Phaze II')!.type, CoverType.solid);
  });

  test('lookup normalizes punctuation but never guesses by partial names or keywords', () {
    expect(
      BallSpecifications.find(' BRUNSWICK ', 'T-Zone')!.material,
      CoverMaterial.polyester,
    );
    for (final (brand, model) in [
      ('', 'TZone'),
      ('Storm', 'TZone'),
      ('Brunswick', 'Rhino'),
      ('Brunswick', 'TZone - custom pearl'),
      ('Custom', 'Pearl Hybrid'),
      ('Radical', 'Evil Eye new version'),
    ]) {
      expect(
        BallSpecifications.find(brand, model),
        isNull,
        reason: '$brand $model',
      );
    }
  });

  test('optional coverstock fields preserve legacy JSON and reject malformed values', () {
    const old = BowlingBall(id: 'b', name: 'TZone');
    expect(BowlingBall.fromJson(old.toJson()).coverMaterial, isNull);
    expect(BowlingBall.fromJson(old.toJson()).coverType, isNull);
    expect(old.toJson().containsKey('coverMaterial'), isFalse);
    expect(old.toJson().containsKey('coverType'), isFalse);
    for (final key in ['coverMaterial', 'coverType']) {
      for (final invalid in [
        'unknown value',
        3,
        ['solid'],
      ]) {
        expect(
          () => BowlingBall.fromJson({...old.toJson(), key: invalid}),
          throwsFormatException,
        );
      }
    }
  });

  testWidgets(
    'new models default exactly while manual choices and clears take precedence',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = BowlController(null, const BowlData());
      addTearDown(controller.dispose);
      await host(tester, controller);
      await tester.enterText(field('Manufacturer'), 'Brunswick');
      await tester.enterText(field('Ball name / model'), 'TZone');
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), CoverMaterial.polyester);
      expect(selected<CoverType>(tester), isNull);
      await tester.enterText(field('Ball name / model'), 'Alert');
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), CoverMaterial.reactiveResin);
      expect(selected<CoverType>(tester), CoverType.solid);
      await tester.enterText(field('Ball name / model'), 'Custom Pearl');
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), isNull);
      expect(selected<CoverType>(tester), isNull);
      await choose<CoverMaterial>(tester, 'Urethane');
      await choose<CoverType>(tester, 'Pearl');
      await tester.ensureVisible(field('Ball name / model'));
      await tester.enterText(field('Ball name / model'), 'Combat Hybrid');
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), CoverMaterial.urethane);
      expect(selected<CoverType>(tester), CoverType.pearl);
      await tester.ensureVisible(find.text('Use model specifications'));
      await tester.tap(find.text('Use model specifications'));
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), CoverMaterial.reactiveResin);
      expect(selected<CoverType>(tester), CoverType.hybrid);
      await choose<CoverMaterial>(tester, 'Not set');
      await tester.ensureVisible(field('Ball name / model'));
      await tester.enterText(
        field('Ball name / model'),
        'Danger Zone Purple Ice',
      );
      await tester.pumpAndSettle();
      expect(selected<CoverMaterial>(tester), isNull);
      expect(selected<CoverType>(tester), CoverType.pearl);
      await tester.tap(find.text('Save ball'));
      await tester.pumpAndSettle();
      expect(controller.data.balls.single.coverMaterial, isNull);
      expect(controller.data.balls.single.coverType, CoverType.pearl);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'saved overrides, retry and clearing survive at 200% text in ${brightness.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = RetryCoverController(
          const BowlData(
            balls: [
              BowlingBall(
                id: 'b',
                brand: 'Brunswick',
                name: 'TZone',
                weight: 12,
                nickname: 'League',
                coverMaterial: CoverMaterial.other,
                coverType: CoverType.hybrid,
              ),
            ],
          ),
        );
        addTearDown(controller.dispose);
        await host(tester, controller, brightness: brightness);
        expect(selected<CoverMaterial>(tester), CoverMaterial.other);
        expect(selected<CoverType>(tester), CoverType.hybrid);
        await tester.ensureVisible(find.text('Use model specifications'));
        await tester.tap(find.text('Use model specifications'));
        await tester.pumpAndSettle();
        expect(selected<CoverMaterial>(tester), CoverMaterial.polyester);
        expect(selected<CoverType>(tester), isNull);
        await choose<CoverType>(tester, 'Solid');
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        expect(selected<CoverMaterial>(tester), CoverMaterial.polyester);
        expect(selected<CoverType>(tester), CoverType.solid);
        expect(
          find.textContaining('Your entries are still here'),
          findsOneWidget,
        );
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        expect(controller.data.balls.single.id, 'b');
        expect(controller.data.balls.single.nickname, 'League');
        expect(
          controller.data.balls.single.coverMaterial,
          CoverMaterial.polyester,
        );
        expect(controller.data.balls.single.coverType, CoverType.solid);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await choose<CoverMaterial>(tester, 'Not set');
        await choose<CoverType>(tester, 'Not set');
        await tester.tap(find.text('Save ball'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(selected<CoverMaterial>(tester), isNull);
        expect(selected<CoverType>(tester), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await controller.saveBall(
          const BowlingBall(
            id: 'b',
            name: 'TZone',
            weight: 12,
            coverMaterial: CoverMaterial.polyester,
            coverType: CoverType.solid,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BagPage(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cover: Polyester / plastic · Solid'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
