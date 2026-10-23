import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/session_share.dart';
import 'package:tallybowl/src/theme.dart';

void main() {
  testWidgets(
    'recap contains accurate scores, website branding and privacy choices',
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
      final data = BowlData(
        profile: const BowlerProfile(name: 'Joe'),
        alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
        sessions: [session],
        games: [
          BowlingGame(
            id: 'g',
            sessionId: 's',
            frames: List.filled(10, '9-'),
            createdAt: DateTime(2026, 10, 23),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: tallyBowlTheme,
          home: SessionSharePage(data: data, session: session),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('90.0'), findsOneWidget);
      expect(find.text('tallybowl.jws.app'), findsOneWidget);
      expect(find.text('Joe'), findsOneWidget);
      expect(find.text('Home lanes'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Your name'));
      await tester.tap(find.widgetWithText(FilterChip, 'Alley & lane'));
      await tester.pumpAndSettle();
      expect(find.text('Joe'), findsNothing);
      expect(find.text('Home lanes'), findsNothing);
      expect(find.text('90.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
