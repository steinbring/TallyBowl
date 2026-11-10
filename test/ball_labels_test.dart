import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/ball_labels.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/features/insights.dart';
import 'package:tallybowl/src/features/session_share.dart';
import 'package:tallybowl/src/ui/journal_cards.dart';

const testBalls = [
  BowlingBall(id: 'light', name: 'TZone', brand: 'Brunswick', weight: 12),
  BowlingBall(id: 'heavy', name: 'TZone', weight: 14, color: BallColor.blue),
  BowlingBall(id: 'twin', name: 'TZone', weight: 14, color: BallColor.blue),
  BowlingBall(id: 'spare', name: 'TZone', weight: 14, nickname: 'Spare'),
];

void main() {
  test(
    'labels distinguish weights and keep model and weight with nicknames',
    () {
      final labels = BallLabels(testBalls);
      expect(labels['light'], 'TZone · 12 lb');
      expect(labels['heavy'], 'Ball 1 · Blue · TZone · 14 lb');
      expect(labels['twin'], 'Ball 2 · Blue · TZone · 14 lb');
      expect(labels['spare'], 'Spare · TZone · 14 lb');
      expect(
        BallLabels.base(
          const BowlingBall(id: 'x', name: 'TZone', weight: 13.25),
        ),
        'TZone · 13.25 lb',
      );
    },
  );

  test('colors distinguish matching models before numbering is needed', () {
    final labels = BallLabels(const [
      BowlingBall(id: 'b', name: 'TZone', color: BallColor.blue),
      BowlingBall(id: 'r', name: 'TZone', color: BallColor.red),
    ]);
    expect(labels['b'], 'Blue · TZone · 15 lb');
    expect(labels['r'], 'Red · TZone · 15 lb');
  });

  test(
    'case, whitespace, matching nicknames and retired balls stay distinct',
    () {
      const balls = [
        BowlingBall(id: 'a', name: ' TZone ', nickname: ' League '),
        BowlingBall(id: 'b', name: 'tzone', nickname: 'league', retired: true),
        BowlingBall(id: 'c', name: 'TZone', nickname: 'League'),
        BowlingBall(id: 'd', name: 'Ball 1 · League · TZone'),
      ];
      final labels = BallLabels(balls);
      expect(labels['a'], 'Ball 2 · League · TZone · 15 lb');
      expect(labels['b'], 'Ball 3 · league · tzone · 15 lb');
      expect(labels['c'], 'Ball 4 · League · TZone · 15 lb');
      expect(labels['d'], 'Ball 1 · League · TZone · 15 lb');
      expect(
        balls.map((b) => labels[b.id].toLowerCase()).toSet().length,
        balls.length,
      );
    },
  );

  test('blank nickname keeps legacy JSON and a derived default', () {
    const ball = BowlingBall(id: 'b', name: 'TZone', weight: 12);
    expect(ball.toJson(), isNot(contains('nickname')));
    final restored = BowlingBall.fromJson(ball.toJson());
    expect(restored.nickname, '');
    expect(BallLabels([restored])['b'], 'TZone · 12 lb');
    expect(
      BallLabels.base(
        const BowlingBall(id: 'b', name: 'New model', weight: 14),
      ),
      'New model · 14 lb',
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'used and primary selectors preserve distinct IDs at ${scale}x',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final session = BowlingSession(
          id: 's',
          alleyId: 'a',
          startedAt: DateTime(2026, 11, 9),
        );
        final controller = BowlController(
          null,
          BowlData(
            balls: testBalls,
            alleys: const [BowlingAlley(id: 'a', name: 'Home')],
            sessions: [session],
          ),
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => openGameEditor(
                      context,
                      controller,
                      session,
                      game: controller.data.games.firstOrNull,
                      initialFrames: List.filled(10, '9-'),
                    ),
                    child: const Text('Record'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Record'));
        await tester.pumpAndSettle();
        for (final entry in const {
          'light': 'TZone · 12 lb',
          'heavy': 'Ball 1 · Blue · TZone · 14 lb',
          'twin': 'Ball 2 · Blue · TZone · 14 lb',
          'spare': 'Spare · TZone · 14 lb',
        }.entries) {
          final chip = find.byKey(ValueKey('ball-tag-${entry.key}'));
          await tester.ensureVisible(chip);
          expect(
            find.descendant(of: chip, matching: find.text(entry.value)),
            findsOneWidget,
          );
        }
        for (final id in ['light', 'twin']) {
          final chip = find.byKey(ValueKey('ball-tag-$id'));
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
        }
        final primary = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(primary);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ball 2 · Blue · TZone · 14 lb').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save game'));
        await tester.pumpAndSettle();
        expect(controller.data.games.single.ballIds, ['light', 'twin']);
        expect(controller.data.games.single.primaryBallId, 'twin');
        await controller.saveBall(
          const BowlingBall(
            id: 'twin',
            name: 'TZone',
            weight: 14,
            color: BallColor.blue,
            nickname: 'League',
          ),
        );
        await tester.tap(find.text('Record'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(primary);
        expect(tester.state<FormFieldState<String>>(primary).value, 'twin');
        expect(find.text('League · TZone · 14 lb'), findsWidgets);
        expect(controller.data.games.single.ballIds, ['light', 'twin']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('history, insights and recap identify the same tagged balls', (
    tester,
  ) async {
    final session = BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026, 11, 9),
    );
    final game = BowlingGame(
      id: 'g',
      sessionId: 's',
      createdAt: session.startedAt,
      frames: List.filled(10, '9-'),
      ballIds: const ['light', 'twin'],
      primaryBallId: 'twin',
    );
    final data = BowlData(
      balls: testBalls,
      sessions: [session],
      games: [game],
      alleys: const [BowlingAlley(id: 'a', name: 'Home')],
    );
    final controller = BowlController(null, data);
    addTearDown(controller.dispose);
    Future<void> show(Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(GameCard(game: game, number: 1, data: data, onTap: () {}));
    expect(
      find.text('TZone · 12 lb · Ball 2 · Blue · TZone · 14 lb'),
      findsOneWidget,
    );
    await show(InsightsPage(controller: controller));
    expect(find.text('TZone · 12 lb'), findsOneWidget);
    expect(find.text('Ball 2 · Blue · TZone · 14 lb'), findsOneWidget);
    await show(RecapCard(data: data, session: session));
    expect(
      find.text('IN THE BAG  ·  TZone · 12 lb / Ball 2 · Blue · TZone · 14 lb'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
