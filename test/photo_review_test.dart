import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/theme.dart';

void main() {
  testWidgets('a conflicting displayed total requires an explicit review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026, 10, 23),
    );
    final controller = BowlController(
      null,
      BowlData(
        alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
        sessions: [session],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlTheme,
        home: GameEditor(
          controller: controller,
          session: session,
          initialFrames: List.filled(10, '9-'),
          displayedTotal: 150,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save game'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save game'))
          .onPressed,
      isNotNull,
    );
    await tester.enterText(find.byKey(const ValueKey('frame-0')), '8-');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save game'))
          .onPressed,
      isNull,
    );
  });
}
