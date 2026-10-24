import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/main.dart' as entrypoint;
import 'package:tallybowl/src/app.dart';
import 'package:tallybowl/src/config.dart';

void main() {
  testWidgets('first frame does not wait for the native metadata reply', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) => pending.future,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    entrypoint.main();
    await tester.pump();
    expect(find.byType(TallyBowlApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(pending.isCompleted, isFalse);
    expect(AppConfig.userAgent, 'TallyBowl (+https://tallybowl.jws.app)');
    pending.complete({
      'appName': 'TallyBowl!',
      'packageName': 'app.jws.tallybowl',
      'version': '0.1.3',
      'buildNumber': '4',
    });
    await tester.pump();
    expect(
      AppConfig.userAgent,
      'TallyBowl/0.1.3+4 (+https://tallybowl.jws.app)',
    );
    expect(tester.takeException(), isNull);
  });
}
