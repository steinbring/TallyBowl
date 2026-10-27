import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/photo_capture.dart';
import 'package:tallybowl/src/features/game_editor.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/theme.dart';

import 'recognition/frame_glyph_reader_test.dart' show game89, game109;
import 'recognition/scoreboard_grid_test.dart' show practiceFrames, checkpoints;

void main() {
  for (final score in [90, 89, 109]) {
    for (final resume in [false, true]) {
      testWidgets(
        'game $score ${resume ? 'resumes photo draft' : 'imports photo'} with ten filled frame inputs and metadata',
        (tester) async {
          await tester.runAsync(() async {
            tester.view.physicalSize = const Size(1440, 1800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final expectedFrames = score == 90
                ? practiceFrames
                : score == 89
                ? game89
                : game109;
            final path = score == 90
                ? '${Directory.current.path}/test/goldens/recap.png'
                : '${Directory.current.path}/test/fixtures/practice_$score.png';
            final session = BowlingSession(
              id: 's',
              alleyId: 'a',
              startedAt: DateTime(2026, 10, 24),
            );
            final controller = BowlController(
              null,
              BowlData(
                profile: const BowlerProfile(name: 'Bowler'),
                alleys: const [BowlingAlley(id: 'a', name: 'Home lanes')],
                balls: const [
                  BowlingBall(id: 'b1', name: 'Ball one'),
                  BowlingBall(id: 'b2', name: 'Ball two'),
                ],
                sessions: [session],
              ),
            );
            if (resume) {
              await controller.saveDraft({
                'sessionId': 's',
                'sourcePath': path,
                'frames': List.filled(10, ''),
                'lane': '5–6',
                'notes': 'Practice night',
                'ballIds': ['b1', 'b2'],
                'primaryBallId': 'b2',
              });
            }
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              PhotoService.channel,
              (call) async {
                final args = call.arguments as Map;
                final name = score != 90
                    ? 'practice_${score}_android'
                    : args['regions'] == null
                    ? 'monitor_geometry'
                    : 'monitor_cells';
                return jsonDecode(
                  await File('test/fixtures/$name.json').readAsString(),
                );
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(PhotoService.channel, null),
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: tallyBowlTheme,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () {
                        if (resume) {
                          recordOrResumeGame(context, controller, session);
                        } else {
                          importScorePhoto(
                            context,
                            controller,
                            session,
                            recoveredPath: path,
                          );
                        }
                      },
                      child: const Text('Open photo'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open photo'));
            // Native recognition and actual retained-file reads finish outside fake time.
            for (
              var i = 0;
              i < 50 && find.byType(GameEditor).evaluate().isEmpty;
              i++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              await tester.pump(const Duration(milliseconds: 100));
            }
            await tester.pumpAndSettle();
            expect(find.byType(GameEditor), findsOneWidget);
            for (var i = 0; i < 10; i++) {
              expect(
                tester
                    .widget<TextField>(find.byKey(ValueKey('frame-$i')))
                    .controller!
                    .text,
                expectedFrames[i],
              );
            }
            if (score == 90) {
              expect(controller.data.draft!['sourceCumulative'], checkpoints);
            }
            if (!resume) {
              for (final label in ['Ball one', 'Ball two']) {
                await tester.ensureVisible(find.text(label));
                await tester.tap(find.widgetWithText(FilterChip, label));
                await tester.pumpAndSettle();
              }
              final primary = find.byType(DropdownButtonFormField<String>);
              await tester.ensureVisible(primary);
              await tester.tap(primary);
              await tester.pumpAndSettle();
              await tester.tap(find.text('Ball two').last);
              await tester.pumpAndSettle();
              final lane = find.widgetWithText(
                TextField,
                'Lane or lane pair for this game',
              );
              await tester.ensureVisible(lane);
              await tester.enterText(lane, '5–6');
              final notes = find.widgetWithText(TextField, 'Game notes');
              await tester.ensureVisible(notes);
              await tester.enterText(notes, 'Practice night');
              await tester.pumpAndSettle();
            }
            await tester.tap(find.widgetWithText(FilledButton, 'Save game'));
            await tester.pumpAndSettle();
            expect(controller.data.games.single.frames, expectedFrames);
            expect(controller.data.games.single.score, score);
            expect(
              controller.data.games.single.ballIds,
              containsAll(['b1', 'b2']),
            );
            expect(controller.data.games.single.primaryBallId, 'b2');
            expect(controller.data.games.single.lane, '5–6');
            expect(controller.data.games.single.notes, 'Practice night');
            expect(controller.data.draft, isNull);
            expect(tester.takeException(), isNull);
          });
        },
      );
    }
  }
  testWidgets(
    'matching final total does not hide a conflicting frame checkpoint',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BowlingSession(
        id: 's',
        alleyId: 'a',
        startedAt: DateTime(2026),
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
            initialFrames: practiceFrames,
            displayedTotal: 90,
            sourceCumulative: [...checkpoints]..[4] = 45,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save game'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save game'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
