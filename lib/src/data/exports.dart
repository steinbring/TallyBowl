import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import 'bowl_store.dart';
import 'bounded_file.dart';

abstract final class BowlExports {
  static const maxBackupBytes = 100 * 1024 * 1024;
  static Future<BowlData> readBackupFile(XFile file) async =>
      BowlStore.readBackup(
        utf8.decode(
          await readBoundedFile(
            file,
            maxBytes: maxBackupBytes,
            tooLargeMessage: 'Choose a backup smaller than 100 MB.',
          ),
        ),
      );
  static Future<File> temporaryFile(String name, Uint8List bytes) async {
    final directory = await Directory(
      p.join((await getTemporaryDirectory()).path, 'tallybowl-exports'),
    ).create(recursive: true);
    final before = DateTime.now().subtract(const Duration(days: 1));
    await for (final entry in directory.list(followLinks: false)) {
      if ((entry is File || entry is Directory) &&
          (await entry.stat()).modified.isBefore(before)) {
        await entry.delete(recursive: true);
      }
    }
    // Isolate identical export names without exposing a timestamp in the name
    // or relying on share plugins to override the name of an existing file.
    final exportDirectory = await Directory(
      p.join(directory.path, const Uuid().v4()),
    ).create();
    final file = File(p.join(exportDirectory.path, name));
    return file.writeAsBytes(bytes, flush: true);
  }

  static Rect origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
  }

  static const imageShareChannel = MethodChannel('app.jws.tallybowl/share');
  static Future<void> shareImage(File file, String name, Rect anchor) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await imageShareChannel.invokeMethod<void>('shareImage', {
        'path': file.path,
      });
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          fileNameOverrides: [name],
          sharePositionOrigin: anchor,
        ),
      );
    }
  }

  static Future<void> exportFile(
    BuildContext context, {
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async {
    if (Platform.isMacOS) {
      final destination = await getSaveLocation(suggestedName: name);
      if (destination != null) {
        await XFile.fromData(
          bytes,
          mimeType: mime,
          name: name,
        ).saveTo(destination.path);
      }
    } else {
      final anchor = origin(context);
      final file = await temporaryFile(name, bytes);
      if (mime == 'image/png') {
        await shareImage(file, name, anchor);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mime)],
          fileNameOverrides: [name],
          sharePositionOrigin: anchor,
        ),
      );
    }
  }

  static Future<void> safetyCopy(BowlData data) async {
    final file = File(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'before-restore.json',
      ),
    );
    final staging = File('${file.path}.tmp');
    await staging.writeAsString(BowlStore.encodeBackup(data), flush: true);
    await staging.rename(file.path);
  }

  static Future<BowlData?> safetyData() async {
    final file = File(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'before-restore.json',
      ),
    );
    return await file.exists() ? readBackupFile(XFile(file.path)) : null;
  }

  static String gameCsv(BowlData data) {
    final rows = <List<Object?>>[
      [
        'game_id',
        'session_id',
        'bowling_date',
        'utc_offset_minutes',
        'type',
        'alley',
        'lane',
        'game_number',
        'scratch_score',
        'balls_tagged',
        'primary_ball',
        'notes',
        for (var i = 1; i <= 10; i++) 'frame_$i',
      ],
    ];
    for (final session in data.sessions) {
      final games = data.sessionGames(session.id);
      for (var i = 0; i < games.length; i++) {
        final g = games[i];
        rows.add([
          g.id,
          session.id,
          session.startedAt.toIso8601String(),
          session.utcOffsetMinutes,
          session.league ? 'league' : 'practice',
          data.alley(session.alleyId)!.name,
          g.lane,
          i + 1,
          g.score,
          g.ballIds.map((id) => data.ball(id)!.name).join(' | '),
          g.primaryBallId == null ? '' : data.ball(g.primaryBallId!)!.name,
          g.notes,
          ...g.frames,
        ]);
      }
    }
    return _csv(rows);
  }

  static String deliveryCsv(BowlData data) {
    final rows = <List<Object?>>[
      [
        'game_id',
        'session_id',
        'frame',
        'delivery',
        'mark',
        'pinfall',
        'cumulative_score',
      ],
    ];
    for (final game in data.games) {
      final score = game.result;
      for (var f = 0; f < 10; f++) {
        for (var d = 0; d < score.frames[f].marks.length; d++) {
          rows.add([
            game.id,
            game.sessionId,
            f + 1,
            d + 1,
            score.frames[f].marks[d],
            score.frames[f].pins[d],
            score.cumulative[f],
          ]);
        }
      }
    }
    return _csv(rows);
  }

  static Uint8List textBytes(String value) =>
      Uint8List.fromList(utf8.encode(value));
  static String _csv(List<List<Object?>> rows) => rows
      .map(
        (r) => r
            .map((value) {
              var cell = value?.toString() ?? '';
              // Treat user-entered names/notes as text when opened in a spreadsheet.
              if (value is String &&
                  cell != '-' &&
                  (RegExp(r'^[=+@\-]').hasMatch(cell.trimLeft()) ||
                      RegExp(r'^[\x00-\x20\uFEFF]*[=+@\-]').hasMatch(cell) ||
                      RegExp(r'^[\t\r\n]').hasMatch(cell))) {
                cell = "'$cell";
              }
              return '"${cell.replaceAll('"', '""')}"';
            })
            .join(','),
      )
      .join('\r\n');
}
