import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';

BowlController journalController() => BowlController(
  null,
  const BowlData(
    profile: BowlerProfile(name: 'Joe', aliases: ['JWS']),
    balls: [BowlingBall(id: 'ball', name: 'My ball')],
    alleys: [BowlingAlley(id: 'alley', name: 'Home lanes')],
  ),
);
void main() {
  testWidgets('record and finish a session with calculated frame scores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = journalController();
    await tester.pumpWidget(TallyBowlApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start a session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();
    expect(controller.activeSession, isNotNull);
    await tester.tap(find.text('Record a game'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      final field = find.byKey(ValueKey('frame-$i'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '9-');
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My ball'));
    await tester.tap(find.text('My ball'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save game'));
    await tester.pumpAndSettle();
    expect(controller.data.games.single.score, 90);
    expect(controller.data.games.single.ballIds, ['ball']);
    expect(controller.data.draft, isNull);
    await tester.ensureVisible(find.text('Finish session'));
    await tester.tap(find.text('Finish session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish session'));
    await tester.pumpAndSettle();
    expect(controller.activeSession, isNull);
    expect(controller.data.sessions.single.finished, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'phone layout preserves unfinished game when leaving the editor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = journalController();
      await controller.startSession(
        BowlingSession(
          id: 'session',
          alleyId: 'alley',
          startedAt: DateTime(2026, 10, 23),
        ),
      );
      await tester.pumpWidget(TallyBowlApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Record a game'));
      await tester.tap(find.text('Record a game'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('frame-0')), 'X');
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.data.draft?['frames'], ['X', ...List.filled(9, '')]);
      await tester.ensureVisible(find.text('Resume game'));
      await tester.tap(find.text('Resume game'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('frame-0')))
            .controller!
            .text,
        'X',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
