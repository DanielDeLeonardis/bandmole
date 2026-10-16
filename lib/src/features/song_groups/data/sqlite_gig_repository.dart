import 'dart:convert';

import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';

typedef GigDatabasePathProvider = Future<String> Function();

class SqliteGigRepository implements GigRepository {
  static const legacyStorageKey = 'bandmole_gigs_store';
  static const _legacyMigrationKey = 'legacy_preferences_gigs_v1';

  SqliteGigRepository({
    required DatabaseFactory databaseFactory,
    required GigDatabasePathProvider databasePath,
    SharedPreferences? preferences,
  }) : this._(databaseFactory, databasePath, preferences);

  SqliteGigRepository._(
    this._databaseFactory,
    this._databasePath,
    this._preferences,
  );

  final DatabaseFactory _databaseFactory;
  final GigDatabasePathProvider _databasePath;
  final SharedPreferences? _preferences;
  Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  Future<SharedPreferences> get _asyncPreferences async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<Database> _openDatabase() async {
    final database = await _databaseFactory.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
      ),
    );

    try {
      await _migrateLegacyPreferences(database);
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE gigs (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        date TEXT,
        venue TEXT,
        notes TEXT,
        start_time TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE song_sets (
        id TEXT PRIMARY KEY NOT NULL,
        gig_id TEXT NOT NULL REFERENCES gigs(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        title TEXT NOT NULL,
        UNIQUE (gig_id, position)
      )
    ''');
    await database.execute('''
      CREATE TABLE gig_songs (
        id TEXT PRIMARY KEY NOT NULL,
        set_id TEXT NOT NULL REFERENCES song_sets(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        relative_path TEXT NOT NULL,
        is_broken INTEGER NOT NULL DEFAULT 0,
        broken_reason TEXT,
        UNIQUE (set_id, position)
      )
    ''');
    await database.execute('''
      CREATE TABLE repository_metadata (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateLegacyPreferences(Database database) async {
    final preferences = await _asyncPreferences;
    final legacyJson = preferences.getString(legacyStorageKey);
    if (legacyJson == null) return;

    final decoded = jsonDecode(legacyJson);
    if (decoded is! List) {
      throw const FormatException('Legacy gig data must be a JSON list.');
    }

    final gigs = <Gig>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        throw const FormatException('Legacy gig entries must be JSON objects.');
      }
      gigs.add(Gig.fromJson(Map<String, dynamic>.from(entry)));
    }

    await database.transaction((transaction) async {
      final migration = await transaction.query(
        'repository_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_legacyMigrationKey],
        limit: 1,
      );
      if (migration.isNotEmpty) return;

      for (final gig in gigs) {
        await _insertGig(transaction, gig);
      }
      await transaction.insert('repository_metadata', {
        'key': _legacyMigrationKey,
        'value': 'complete',
      });
    });

    await preferences.remove(legacyStorageKey);
  }

  Future<void> _insertGig(DatabaseExecutor executor, Gig gig) async {
    await executor.insert('gigs', {
      'id': gig.id,
      'title': gig.title,
      'date': gig.date?.toIso8601String(),
      'venue': gig.venue,
      'notes': gig.notes,
      'start_time': gig.startTime,
    });

    for (var setIndex = 0; setIndex < gig.sets.length; setIndex++) {
      final set = gig.sets[setIndex];
      await executor.insert('song_sets', {
        'id': set.id,
        'gig_id': gig.id,
        'position': setIndex,
        'title': set.title,
      });

      for (var songIndex = 0; songIndex < set.songs.length; songIndex++) {
        final song = set.songs[songIndex];
        await executor.insert('gig_songs', {
          'id': song.id,
          'set_id': set.id,
          'position': songIndex,
          'relative_path': song.relativePath,
          'is_broken': song.isBroken ? 1 : 0,
          'broken_reason': song.brokenReason,
        });
      }
    }
  }

  @override
  Future<List<Gig>> loadGigs() async {
    final database = await _database;
    final gigRows = await database.query(
      'gigs',
      orderBy: 'title COLLATE NOCASE, id',
    );
    final gigs = <Gig>[];

    for (final gigRow in gigRows) {
      final gigId = gigRow['id']! as String;
      final setRows = await database.query(
        'song_sets',
        where: 'gig_id = ?',
        whereArgs: [gigId],
        orderBy: 'position',
      );
      final sets = <SongSet>[];

      for (final setRow in setRows) {
        final setId = setRow['id']! as String;
        final songRows = await database.query(
          'gig_songs',
          where: 'set_id = ?',
          whereArgs: [setId],
          orderBy: 'position',
        );
        sets.add(
          SongSet(
            id: setId,
            title: setRow['title']! as String,
            songs: songRows
                .map(
                  (row) => GigSong(
                    id: row['id']! as String,
                    relativePath: row['relative_path']! as String,
                    isBroken: row['is_broken'] == 1,
                    brokenReason: row['broken_reason'] as String?,
                  ),
                )
                .toList(growable: false),
          ),
        );
      }

      final date = gigRow['date'] as String?;
      gigs.add(
        Gig(
          id: gigId,
          title: gigRow['title']! as String,
          date: date == null ? null : DateTime.tryParse(date),
          venue: gigRow['venue'] as String?,
          notes: gigRow['notes'] as String?,
          startTime: gigRow['start_time'] as String?,
          sets: sets,
        ),
      );
    }

    return gigs;
  }

  @override
  Future<void> saveGig(Gig gig) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete('gigs', where: 'id = ?', whereArgs: [gig.id]);
      await _insertGig(transaction, gig);
    });
  }

  @override
  Future<void> deleteGig(String gigId) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete('gigs', where: 'id = ?', whereArgs: [gigId]);
    });
  }

  Future<void> close() async {
    final databaseFuture = _databaseFuture;
    if (databaseFuture == null) return;
    try {
      await (await databaseFuture).close();
    } finally {
      _databaseFuture = null;
    }
  }
}