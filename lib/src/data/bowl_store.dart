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
  static const _tables = ['balls', 'alleys', 'sessions', 'games'];
  Map<String, List<Map<String, Object?>>>? _persisted;
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
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            for (final table in _tables) {
              await db.execute(
                'ALTER TABLE $table ADD COLUMN position INTEGER NOT NULL DEFAULT 0',
              );
              await db.execute('UPDATE $table SET position = rowid');
            }
          }
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE balls (id TEXT PRIMARY KEY, document TEXT NOT NULL, position INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE alleys (id TEXT PRIMARY KEY, document TEXT NOT NULL, position INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE sessions (id TEXT PRIMARY KEY, alley_id TEXT NOT NULL REFERENCES alleys(id), document TEXT NOT NULL, position INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE games (id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(id), document TEXT NOT NULL, position INTEGER NOT NULL)',
          );
        },
      ),
    );
    return BowlStore(db);
  }

  Future<Map<String, List<Map<String, Object?>>>> _readRows(
    DatabaseExecutor db,
  ) async => {
    'settings': await db.query('settings'),
    for (final table in _tables)
      table: await db.query(table, orderBy: 'position, rowid'),
  };

  Future<BowlData> load() async {
    final rows = await _readRows(database);
    final settings = {
      for (final row in rows['settings']!)
        row['key'] as String: jsonDecode(row['value'] as String),
    };
    List<dynamic> read(String table) => [
      for (final row in rows[table]!) jsonDecode(row['document'] as String),
    ];
    final data = BowlData.fromJson({
      'profile': settings['profile'] ?? const BowlerProfile().toJson(),
      'draft': settings['draft'],
      for (final table in _tables) table: read(table),
    });
    _persisted = rows;
    return data;
  }

  /// Only changed rows are written. Draft keystrokes must not rewrite years of
  /// game history. Cache serialized rows (not mutable model objects) and advance
  /// the cache only after commit, so a failed transaction remains retryable.
  /// BowlStore owns writes on its connection; external writers are unsupported.
  Future<void> save(BowlData data) async {
    data.validate();
    List<Map<String, Object?>> records(
      Iterable<Map<String, dynamic>> documents, {
      String? foreignKey,
      String? column,
    }) {
      var position = 0;
      return [
        for (final document in documents)
          {
            'id': document['id'],
            'document': jsonEncode(document),
            'position': position++,
            if (foreignKey != null) column!: document[foreignKey],
          },
      ];
    }

    final next = <String, List<Map<String, Object?>>>{
      'settings': [
        {'key': 'profile', 'value': jsonEncode(data.profile.toJson())},
        if (data.draft != null)
          {'key': 'draft', 'value': jsonEncode(data.draft)},
      ],
      'balls': records(data.balls.map((b) => b.toJson())),
      'alleys': records(data.alleys.map((a) => a.toJson())),
      'sessions': records(
        data.sessions.map((s) => s.toJson()),
        foreignKey: 'alleyId',
        column: 'alley_id',
      ),
      'games': records(
        data.games.map((g) => g.toJson()),
        foreignKey: 'sessionId',
        column: 'session_id',
      ),
    };
    await database.transaction((txn) async {
      final previous = _persisted ?? await _readRows(txn);
      final batch = txn.batch();
      // Add parents before children, then remove children before parents. This
      // also permits restoring snapshots that change existing record references.
      for (final table in ['settings', ..._tables]) {
        final key = table == 'settings' ? 'key' : 'id';
        final old = {for (final row in previous[table]!) row[key]: row};
        for (final row in next[table]!) {
          final prior = old[row[key]];
          if (prior == null) {
            batch.insert(table, row);
          } else if (row.entries.any((e) => prior[e.key] != e.value)) {
            batch.update(table, row, where: '$key = ?', whereArgs: [row[key]]);
          }
        }
      }
      for (final table in [..._tables.reversed, 'settings']) {
        final key = table == 'settings' ? 'key' : 'id';
        final keep = next[table]!.map((r) => r[key]).toSet();
        for (final row in previous[table]!) {
          if (!keep.contains(row[key])) {
            batch.delete(table, where: '$key = ?', whereArgs: [row[key]]);
          }
        }
      }
      await batch.commit(noResult: true);
    });
    _persisted = next;
  }

  String backup(BowlData data) => encodeBackup(data);
  static String encodeBackup(BowlData data) {
    final document = data.toJson();
    if (data.draft != null) {
      document['draft'] = Map<String, dynamic>.from(data.draft!)
        ..remove('sourcePath')
        ..remove('pendingPhotoReview');
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'tallybowl',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': document,
    });
  }

  static BowlData readBackup(String source) {
    try {
      final envelope = jsonDecode(source) as Map<String, dynamic>;
      if (envelope['format'] != 'tallybowl' || envelope['version'] != 1) {
        throw const FormatException('Unsupported TallyBowl backup format.');
      }
      final document = Map<String, dynamic>.from(envelope['data'] as Map);
      if (document['draft'] is Map) {
        document['draft'] = Map<String, dynamic>.from(document['draft'] as Map)
          ..remove('sourcePath')
          ..remove('pendingPhotoReview');
      }
      return BowlData.fromJson(document);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('This file is not a valid TallyBowl backup.');
    }
  }

  Future<void> close() => database.close();
}
