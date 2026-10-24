import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/data/bounded_file.dart';
import 'package:tallybowl/src/data/bowl_store.dart';
import 'package:tallybowl/src/data/exports.dart';
import 'package:tallybowl/src/domain/models.dart';

class _GrowingBackup extends XFile {
  _GrowingBackup({this.declaredSize = 1}) : super('provider-backup');
  final int declaredSize;
  var chunksRead = 0;
  @override
  Future<int> length() async => declaredSize;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    final chunk = Uint8List(1024 * 1024);
    for (var i = 0; i < 200; i++) {
      chunksRead++;
      yield chunk;
    }
  }
}

void main() {
  test('oversized backup is rejected without opening its stream', () async {
    final file = _GrowingBackup(declaredSize: BowlExports.maxBackupBytes + 1);
    await expectLater(BowlExports.readBackupFile(file), throwsFormatException);
    expect(file.chunksRead, 0);
  });
  test(
    'a misleading provider cannot exceed the streamed backup limit',
    () async {
      final file = _GrowingBackup();
      await expectLater(
        BowlExports.readBackupFile(file),
        throwsFormatException,
      );
      expect(file.chunksRead, 101);
    },
  );
  test('bounded reader accepts the exact limit and in-memory XFiles', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(
      await readBoundedFile(
        XFile.fromData(bytes),
        maxBytes: 3,
        tooLargeMessage: 'too large',
      ),
      bytes,
    );
  });
  test(
    'backup reader accepts valid UTF-8 JSON and rejects malformed input',
    () async {
      final source = BowlStore.encodeBackup(
        const BowlData(profile: BowlerProfile(name: 'Zoë')),
      );
      final loaded = await BowlExports.readBackupFile(
        XFile.fromData(Uint8List.fromList(utf8.encode(source))),
      );
      expect(loaded.profile.name, 'Zoë');
      for (final bytes in [
        Uint8List.fromList([255]),
        Uint8List.fromList(utf8.encode('{invalid}')),
      ]) {
        await expectLater(
          BowlExports.readBackupFile(XFile.fromData(bytes)),
          throwsFormatException,
        );
      }
    },
  );
}
