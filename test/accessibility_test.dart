import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/features/session_share.dart';
import 'package:tallybowl/src/theme.dart';
import 'package:tallybowl/src/ui/common.dart';

BowlController accessibleJournal() {
  final session = BowlingSession(
    id: 'session',
    alleyId: 'alley',
    startedAt: DateTime(2026, 10, 23),
  );
  return BowlController(
    null,
    BowlData(
      profile: const BowlerProfile(name: 'Sample bowler'),
      alleys: const [BowlingAlley(id: 'alley', name: 'Neighborhood lanes')],
      balls: const [BowlingBall(id: 'ball', name: 'Phaze II', brand: 'Storm')],
      sessions: [session],
      games: [
        for (var i = 0; i < 3; i++)
          BowlingGame(
            id: 'game-$i',
            sessionId: session.id,
            frames: List.filled(10, '9-'),
            createdAt: session.startedAt,
            ballIds: const ['ball'],
            primaryBallId: 'ball',
          ),
      ],
    ),
  );
}

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final theme in [tallyBowlTheme, tallyBowlDarkTheme]) {
    test('${theme.brightness.name} text and chart colors meet AA contrast', () {
      final s = theme.colorScheme;
      for (final pair in [
        (s.onSurface, s.surface),
        (s.onSurfaceVariant, s.surface),
        (s.onSurfaceVariant, theme.scaffoldBackgroundColor),
        (s.onPrimaryContainer, s.primaryContainer),
        (s.onPrimary, s.primary),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(s.primary, s.surface), greaterThanOrEqualTo(3));
      expect(contrast(s.secondary, s.surface), greaterThanOrEqualTo(3));
    });
  }
  test('original muted and hero text colors already meet AA contrast', () {
    expect(contrast(BowlColors.muted, Colors.white), greaterThanOrEqualTo(4.5));
    for (final color in [const Color(0xFFD6E3DB), const Color(0xFFC5DDCC)]) {
      for (final background in [BowlColors.ink, const Color(0xFF284E4B)]) {
        expect(contrast(color, background), greaterThanOrEqualTo(4.5));
      }
    }
  });
  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final width
          in platform == TargetPlatform.android
              ? [360.0, 840.0]
              : [560.0, 1440.0]) {
        testWidgets(
          '${platform.name} ${brightness.name} width $width at 200% text',
          (tester) async {
            debugDefaultTargetPlatformOverride = platform;

            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            await tester.pumpWidget(
              TallyBowlApp(controller: accessibleJournal()),
            );
            await tester.pumpAndSettle();
            expect(
              Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
              brightness,
            );
            for (var i = 0; i < 5; i++) {
              if (find.byType(NavigationBar).evaluate().isNotEmpty) {
                await tester.tap(find.byType(NavigationDestination).at(i));
              } else if (find.byType(NavigationRail).evaluate().isNotEmpty) {
                await tester.tap(
                  find
                      .byTooltip(
                        [
                          'Tonight',
                          'History',
                          'Insights',
                          'My Bag',
                          'Alleys',
                        ][i],
                      )
                      .last,
                );
              } else {
                final item = find.widgetWithText(
                  ListTile,
                  ['Tonight', 'History', 'Insights', 'My Bag', 'Alleys'][i],
                );
                await tester.ensureVisible(item);
                await tester.tap(item);
              }
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            if (platform == TargetPlatform.macOS && width < 850) {
              expect(find.byType(NavigationRail), findsOneWidget);
              expect(find.byType(NavigationBar), findsNothing);
            }
            debugDefaultTargetPlatformOverride = null;
          },
        );
      }
    }
  }
  testWidgets('large-text editor and recap keep their controls readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = accessibleJournal();
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlDarkTheme,
        home: GameEditor(
          controller: controller,
          session: controller.activeSession!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('frame-9')));
    await tester.pumpAndSettle();
    expect(find.text('Save game'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlDarkTheme,
        home: SessionSharePage(
          data: controller.data,
          session: controller.activeSession!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Export image'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Total: 270'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'scorecard announces each frame, deliveries and cumulative score',
    (tester) async {
      final semantics = tester.ensureSemantics();

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: tallyBowlTheme,
          home: Scaffold(
            body: ScoreStrip(frames: [...List.filled(9, 'X'), 'XXX']),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Frame 1. strike. Cumulative score: 30.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Frame 10. strike, strike, strike. Cumulative score: 300.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );
  testWidgets('main navigation has labeled accessible touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      TallyBowlApp(controller: BowlController(null, const BowlData())),
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
  testWidgets('in-progress frames survive cover-to-unfolded window resizing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = accessibleJournal();
    await tester.pumpWidget(
      MaterialApp(
        theme: tallyBowlTheme,
        home: GameEditor(
          controller: controller,
          session: controller.activeSession!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('frame-0')), 'X');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(840, 900);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('frame-0')))
          .controller!
          .text,
      'X',
    );
    await tester.enterText(find.byKey(const ValueKey('frame-1')), '9/');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('frame-0')))
          .controller!
          .text,
      'X',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('frame-1')))
          .controller!
          .text,
      '9/',
    );
    expect(controller.data.draft!['frames'], [
      'X',
      '9/',
      ...List.filled(8, ''),
    ]);
    expect(tester.takeException(), isNull);
  });
}
