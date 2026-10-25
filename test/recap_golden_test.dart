import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/session_share.dart';
import 'package:tallybowl/src/theme.dart';
import 'package:tallybowl/src/ui/branding.dart';

void main() {
  testWidgets(
    'recap matches its visual baseline and is invariant to UI theme/text size',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final locale = Intl.defaultLocale;
      Intl.defaultLocale = 'en_US';
      addTearDown(() => Intl.defaultLocale = locale);
      final session = BowlingSession(
        id: 's',
        alleyId: 'a',
        startedAt: DateTime(2026, 10, 23),
        lane: '7–8',
      );
      final data = BowlData(
        profile: const BowlerProfile(name: 'Sample bowler'),
        alleys: const [BowlingAlley(id: 'a', name: 'Sample lanes')],
        sessions: [session],
        games: [
          BowlingGame(
            id: 'g1',
            sessionId: 's',
            frames: List.filled(10, '9-'),
            createdAt: session.startedAt,
          ),
          BowlingGame(
            id: 'g2',
            sessionId: 's',
            frames: [...List.filled(9, 'X'), 'XXX'],
            createdAt: session.startedAt,
          ),
        ],
      );
      List<int>? baseline;
      final key = GlobalKey();
      for (final variant in [
        (tallyBowlTheme, 1.0),
        (tallyBowlDarkTheme, 2.0),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: variant.$1,
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(variant.$2)),
                child: Center(
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: key,
                      child: RecapCard(data: data, session: session),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(TallyBowlLogo.asset),
            tester.element(find.byType(RecapCard)),
          ),
        );
        await tester.pumpAndSettle();
        final bytes = await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          image.dispose();
          return bytes;
        });
        if (baseline == null) {
          baseline = bytes;
        } else {
          expect(bytes, baseline);
        }
        await expectLater(
          find.byKey(key),
          matchesGoldenFile('goldens/recap.png'),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
