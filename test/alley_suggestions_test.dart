import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tallybowl/src/app_controller.dart';
import 'package:tallybowl/src/data/place_search.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/ui/alley_dialog.dart';
import 'package:tallybowl/src/ui/alley_search.dart';

import 'data/place_search_test.dart' show responseBody, place;

void main() {
  testWidgets(
    'search selection reuses an existing alley and preserves its notes',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = BowlController(
        null,
        const BowlData(
          alleys: [
            BowlingAlley(
              id: 'saved',
              name: 'My home lanes',
              notes: 'Favorite pair: 7–8',
              osmId: 'N/123',
            ),
          ],
        ),
      );
      final service = PlaceSearch(
        clientFactory: () => MockClient(
          (_) async => http.Response(responseBody([place()]), 200),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlleyDialog(
                    controller: controller,
                    searchService: service,
                  ),
                ),
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Holler House Milwaukee',
      );
      await tester.tap(find.text('Search OpenStreetMap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Holler House'));
      await tester.pumpAndSettle();
      expect(
        find.text('Already in your alleys. Saving updates the existing entry.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Save alley'));
      await tester.pumpAndSettle();
      expect(controller.data.alleys.single.id, 'saved');
      expect(controller.data.alleys.single.notes, 'Favorite pair: 7–8');
      expect(controller.data.alleys.single.latitude, 43);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'does not send keystrokes or display results for a changed query',
    (tester) async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final service = PlaceSearch(
        clientFactory: () => MockClient((_) {
          calls++;
          return pending.future;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlleySearch(service: service, onSelected: (_) {}),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Holler House');
      expect(calls, 0);
      await tester.tap(find.text('Search OpenStreetMap'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Another place');
      pending.complete(http.Response(responseBody([place()]), 200));
      await tester.pumpAndSettle();
      expect(find.text('Holler House'), findsNothing);
      expect(calls, 1);
    },
  );
}
