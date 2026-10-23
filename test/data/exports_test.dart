import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/data/exports.dart';
import 'package:tallybowl/src/domain/models.dart';

BowlData exportData() => BowlData(
  alleys: const [BowlingAlley(id: 'a', name: 'Home, lanes')],
  balls: const [BowlingBall(id: 'b', name: 'My ball')],
  sessions: [
    BowlingSession(
      id: 's',
      alleyId: 'a',
      startedAt: DateTime(2026, 10, 23),
      utcOffsetMinutes: -300,
    ),
  ],
  games: [
    BowlingGame(
      id: 'g',
      sessionId: 's',
      frames: [...List.filled(9, 'X'), 'XXX'],
      createdAt: DateTime(2026, 10, 23),
      ballIds: ['b'],
      primaryBallId: 'b',
      notes: '=HYPERLINK("example")\nA good night',
    ),
  ],
  draft: {
    'sessionId': 's',
    'frames': List.filled(10, ''),
    'sourcePath': '/private/device-only/photo.image',
  },
);
void main() {
  test(
    'portable backup removes file paths without mutating the live draft',
    () {
      final original = exportData();
      final backup = BowlStore.encodeBackup(original);
      expect(backup, isNot(contains('/private/device-only')));
      expect(original.draft!['sourcePath'], '/private/device-only/photo.image');
      final restored = BowlStore.readBackup(backup);
      expect(restored.draft!['sourcePath'], isNull);
      expect(restored.games.single.score, 300);
      expect(restored.sessions.single.utcOffsetMinutes, -300);
      expect(restored.sessions.single.finish().utcOffsetMinutes, -300);
    },
  );
  test(
    'import cannot inject a local image path or invalid ball selections',
    () {
      final envelope = jsonDecode(
        BowlStore.encodeBackup(exportData()),
      ) as Map<String, dynamic>;
      envelope['data']['draft']['sourcePath'] = '/Users/someone/private.png';
      expect(
        BowlStore.readBackup(jsonEncode(envelope)).draft!['sourcePath'],
        isNull,
      );
      envelope['data']['draft']['ballIds'] = ['missing-ball'];
      expect(
        () => BowlStore.readBackup(jsonEncode(envelope)),
        throwsFormatException,
      );
    },
  );
  test(
    'game CSV quotes commas, quotes and line breaks and protects text cells',
    () {
      final csv = BowlExports.gameCsv(exportData());
      expect(csv, contains('"Home, lanes"'));
      expect(csv, contains('"300"'));
      expect(csv, contains('"-300"'));
      expect(csv, contains("\"'=HYPERLINK(\"\"example\"\")\nA good night\""));
    },
  );
  test('delivery export includes all twelve deliveries of a perfect game', () {
    final csv = BowlExports.deliveryCsv(exportData());
    expect(csv.split('\r\n').length, 13);
    expect(csv, contains('"g","s","10","3","X","10","300"'));
  });
  test('CSV treats whitespace-prefixed formulas and leading control characters as text', () {
    for (final text in [
      '  =1+1',
      '\n=1+1',
      '\tDanger',
      '\uFEFF+SUM(1,2)',
      '\u0000@SUM(1,2)',
    ]) {
      final original = exportData();
      final data = original.copyWith(
        alleys: [BowlingAlley(id: 'a', name: text)],
      );
      expect(BowlExports.gameCsv(data), contains('"\'$text"'));
    }
    expect(BowlExports.deliveryCsv(exportData()), isNot(contains('"\'-"')));
  });
}
