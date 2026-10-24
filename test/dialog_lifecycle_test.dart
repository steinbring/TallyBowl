import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/ui/dialogs.dart';

void main() {
  for (final profile in [true, false]) {
    for (final save in [false, true]) {
      testWidgets(
        '${profile ? 'profile' : 'session'} controllers survive keyboard changes during ${save ? 'save' : 'cancel'}',
        (tester) async {
          tester.view.physicalSize = const Size(480, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final controller = BowlController(
            null,
            const BowlData(
              profile: BowlerProfile(name: 'Joe'),
              alleys: [BowlingAlley(id: 'a', name: 'Home lanes')],
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => profile
                        ? editProfile(context, controller)
                        : startSession(context, controller),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, 'Example');
          tester.view.viewInsets = const FakeViewPadding(bottom: 220);
          await tester.pumpAndSettle();
          final action = save
              ? (profile ? 'Save profile' : 'Start session')
              : 'Cancel';
          await tester.ensureVisible(find.text(action));
          await tester.tap(find.text(action));
          // pop completes the showDialog Future before the route's reverse
          // animation removes its fields. Real keyboards change metrics here.
          await tester.pump();
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.pump(const Duration(milliseconds: 30));
          await tester.pumpAndSettle();
          expect(find.text('Open'), findsOneWidget);
          if (profile) {
            expect(controller.data.profile.name, save ? 'Example' : 'Joe');
          } else {
            expect(controller.activeSession?.lane, save ? 'Example' : null);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
