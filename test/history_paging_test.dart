import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/journal.dart';
import 'package:tallybowl/src/ui/journal_cards.dart';

void main() {
  testWidgets('history pages all sessions and resets paging for filters', (
    tester,
  ) async {
    final controller = BowlController(
      null,
      BowlData(
        alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
        sessions: [
          for (var i = 0; i < 120; i++)
            BowlingSession(
              id: 's$i',
              alleyId: 'a',
              startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
              finishedAt: DateTime(2026, 1, 1).add(Duration(days: i, hours: 1)),
              league: i.isEven,
              leagueName: i == 7 ? 'Unique league' : '',
            ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HistoryPage(controller: controller),
          ),
        ),
      ),
    );
    expect(find.byType(SessionCard), findsNWidgets(50));
    expect(
      tester.widget<SessionCard>(find.byType(SessionCard).first).session.id,
      's119',
    );
    await tester.ensureVisible(find.text('Show more sessions'));
    await tester.tap(find.text('Show more sessions'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionCard), findsNWidgets(100));
    await tester.ensureVisible(find.text('Show more sessions'));
    await tester.tap(find.text('Show more sessions'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionCard), findsNWidgets(120));
    expect(find.text('Show more sessions'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'League'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'League'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionCard), findsNWidgets(50));
    expect(find.text('Showing 50 of 60 sessions'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'All sessions'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'All sessions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unique league');
    await tester.pumpAndSettle();
    expect(find.byType(SessionCard), findsOneWidget);
    expect(
      tester.widget<SessionCard>(find.byType(SessionCard)).session.id,
      's7',
    );
    expect(tester.takeException(), isNull);
  });
}
