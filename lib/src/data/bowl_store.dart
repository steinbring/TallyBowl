import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';

/// A snapshot is committed in a single transaction so a killed app never leaves
/// half a session, inventory, or restore on disk. IDs stay stable across edits.
class BowlStore {
  BowlStore(this.database);
  final Database database;
  static Future<BowlStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbPath =
        path ??
        p.join((await getApplicationSupportDirectory()).path, 'tallybowl.db');
    final db = await (factory ?? databaseFactory).openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE balls (id TEXT PRIMARY KEY, document TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE alleys (id TEXT PRIMARY KEY, document TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE sessions (id TEXT PRIMARY KEY, alley_id TEXT NOT NULL REFERENCES alleys(id), document TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE games (id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(id), document TEXT NOT NULL)',
          );
        },
      ),
    );
    return BowlStore(db);
  }

  Future<BowlData> load() async {
    final settings = {
      for (final row in await database.query('settings'))
        row['key'] as String: jsonDecode(row['value'] as String),
    };
    Future<List<dynamic>> read(String table) async => [
      for (final row in await database.query(table, orderBy: 'rowid'))
        jsonDecode(row['document'] as String),
    ];
    return BowlData.fromJson({
      'profile': settings['profile'] ?? const BowlerProfile().toJson(),
      'draft': settings['draft'],
      'balls': await read('balls'),
      'alleys': await read('alleys'),
      'sessions': await read('sessions'),
      'games': await read('games'),
    });
  }

  Future<void> save(BowlData data) async {
    data.validate();
    await database.transaction((txn) async {
      for (final table in [
        'games',
        'sessions',
        'alleys',
        'balls',
        'settings',
      ]) {
        await txn.delete(table);
      }
      await txn.insert('settings', {
        'key': 'profile',
        'value': jsonEncode(data.profile.toJson()),
      });
      if (data.draft != null) {
        await txn.insert('settings', {
          'key': 'draft',
          'value': jsonEncode(data.draft),
        });
      }
      for (final b in data.balls) {
        await txn.insert('balls', {
          'id': b.id,
          'document': jsonEncode(b.toJson()),
        });
      }
      for (final a in data.alleys) {
        await txn.insert('alleys', {
          'id': a.id,
          'document': jsonEncode(a.toJson()),
        });
      }
      for (final s in data.sessions) {
        await txn.insert('sessions', {
          'id': s.id,
          'alley_id': s.alleyId,
          'document': jsonEncode(s.toJson()),
        });
      }
      for (final g in data.games) {
        await txn.insert('games', {
          'id': g.id,
          'session_id': g.sessionId,
          'document': jsonEncode(g.toJson()),
        });
      }
    });
  }

  String backup(BowlData data) => const JsonEncoder.withIndent('  ').convert({
    'format': 'tallybowl',
    'version': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'data': data.toJson(),
  });
  static BowlData readBackup(String source) {
    try {
      final envelope = jsonDecode(source) as Map<String, dynamic>;
      if (envelope['format'] != 'tallybowl' || envelope['version'] != 1) {
        throw const FormatException('Unsupported TallyBowl backup format.');
      }
      return BowlData.fromJson(
        Map<String, dynamic>.from(envelope['data'] as Map),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('This file is not a valid TallyBowl backup.');
    }
  }

  Future<void> close() => database.close();
}
