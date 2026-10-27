import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/features/app_document.dart';
import 'package:tallybowl/src/features/settings.dart';

void main() {
  testWidgets(
    'Settings opens bundled help and privacy and identifies the build',
    (tester) async {
      await tester.runAsync(() async {
        PackageInfo.setMockInitialValues(
          appName: 'TallyBowl!',
          packageName: 'app.jws.tallybowl',
          version: '9.2.1',
          buildNumber: '42',
          buildSignature: '',
        );
        final controller = BowlController(null, const BowlData());
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(home: ProfileSettings(controller: controller)),
        );
        await tester.pumpAndSettle();
        for (final document in AppDocument.values) {
          final link = find.widgetWithText(TextButton, document.title);
          await tester.ensureVisible(link);
          await tester.tap(link);
          await tester.pumpAndSettle();
          expect(find.byType(AppDocumentPage), findsOneWidget);
          expect(
            find.textContaining(RegExp(r'^Updated \d{4}-\d{2}-\d{2}$')),
            findsOneWidget,
          );
          expect(
            find.text(
              document == AppDocument.guide
                  ? 'Back up before you experiment'
                  : 'Sharing, exports, and retention',
            ),
            findsOneWidget,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Version 9.2.1 (build 42)'));
        expect(find.text('Version 9.2.1 (build 42)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets(
    'offline policy remains scrollable at narrow width and 200% text',
    (tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          const MaterialApp(
            home: AppDocumentPage(document: AppDocument.privacy),
          ),
        );
        await tester.pumpAndSettle();
        final heading = find.text('Your journal on your device');
        expect(heading, findsOneWidget);
        final semantics = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(heading)
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        semantics.dispose();
        await tester.ensureVisible(find.text('Apple TestFlight privacy'));
        await tester.pumpAndSettle();
        expect(
          find.text('Apple TestFlight privacy').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );
}
