import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';

typedef EditorDatabasePathProvider = Future<String> Function();

class SqliteChordProPreferencesRepository
    implements ChordProPreferencesRepository {
  static const legacyCustomDirectivesKey = 'chordpro_custom_directives';
  static const hintDismissedKey = 'chordpro_editor_hint_dismissed';
  static const _legacyMigrationKey = 'legacy_preferences_custom_directives_v1';

  SqliteChordProPreferencesRepository({
    required DatabaseFactory databaseFactory,
    required EditorDatabasePathProvider databasePath,
    SharedPreferences? preferences,
  }) : this._(databaseFactory, databasePath, preferences);

  SqliteChordProPreferencesRepository._(
    this._databaseFactory,
    this._databasePath,
    this._preferences,
  );

  final DatabaseFactory _databaseFactory;
  final EditorDatabasePathProvider _databasePath;
  final SharedPreferences? _preferences;
  Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  Future<SharedPreferences> get _asyncPreferences async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<Database> _openDatabase() async {
    final database = await _databaseFactory.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(version: 1, onCreate: _createSchema),
    );
    try {
      await _migrateLegacyDirectives(database);
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE custom_directives (
        name TEXT PRIMARY KEY NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE editor_metadata (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateLegacyDirectives(Database database) async {
    final preferences = await _asyncPreferences;
    final legacy = preferences.getStringList(legacyCustomDirectivesKey);
    if (legacy == null) return;

    await database.transaction((transaction) async {
      final migrated = await transaction.query(
        'editor_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_legacyMigrationKey],
        limit: 1,
      );
      if (migrated.isNotEmpty) return;

      for (final raw in legacy) {
        final normalized = ChordProDocument.normalizeDirectiveName(raw);
        if (ChordProDocument.isValidCustomDirectiveName(normalized)) {
          await transaction.insert(
            'custom_directives',
            {'name': normalized},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      await transaction.insert('editor_metadata', {
        'key': _legacyMigrationKey,
        'value': 'complete',
      });
    });

    await preferences.remove(legacyCustomDirectivesKey);
  }

  @override
  Future<List<String>> loadGlobalCustomDirectives() async {
    final database = await _database;
    final rows = await database.query(
      'custom_directives',
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((row) => row['name']! as String).toList(growable: false);
  }

  @override
  Future<void> addGlobalCustomDirective(String name) async {
    final normalized = ChordProDocument.normalizeDirectiveName(name);
    final database = await _database;
    await database.insert(
      'custom_directives',
      {'name': normalized},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> removeGlobalCustomDirective(String name) async {
    final normalized = ChordProDocument.normalizeDirectiveName(name);
    final database = await _database;
    await database.delete(
      'custom_directives',
      where: 'name = ?',
      whereArgs: [normalized],
    );
  }

  @override
  Future<bool> isHintDismissed() async {
    final preferences = await _asyncPreferences;
    return preferences.getBool(hintDismissedKey) ?? false;
  }

  @override
  Future<void> setHintDismissed(bool dismissed) async {
    final preferences = await _asyncPreferences;
    await preferences.setBool(hintDismissedKey, dismissed);
  }

  Future<void> close() async {
    final future = _databaseFuture;
    if (future == null) return;
    try {
      await (await future).close();
    } finally {
      _databaseFuture = null;
    }
  }
}

class SharedPreferencesChordProPreferencesRepository
    implements ChordProPreferencesRepository {
  SharedPreferencesChordProPreferencesRepository({
    SharedPreferences? preferences,
  }) : this._(preferences);

  SharedPreferencesChordProPreferencesRepository._(this._preferences);

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _asyncPreferences async =>
      _preferences ?? await SharedPreferences.getInstance();

  @override
  Future<List<String>> loadGlobalCustomDirectives() async {
    final preferences = await _asyncPreferences;
    final names =
        preferences.getStringList(
          SqliteChordProPreferencesRepository.legacyCustomDirectivesKey,
        ) ??
        const <String>[];
    final sorted = names
        .map(ChordProDocument.normalizeDirectiveName)
        .toSet()
        .toList()
      ..sort();
    return sorted;
  }

  @override
  Future<void> addGlobalCustomDirective(String name) async {
    final normalized = ChordProDocument.normalizeDirectiveName(name);
    final current = await loadGlobalCustomDirectives();
    if (current.contains(normalized)) return;
    final updated = [...current, normalized]..sort();
    final preferences = await _asyncPreferences;
    await preferences.setStringList(
      SqliteChordProPreferencesRepository.legacyCustomDirectivesKey,
      updated,
    );
  }

  @override
  Future<void> removeGlobalCustomDirective(String name) async {
    final normalized = ChordProDocument.normalizeDirectiveName(name);
    final current = await loadGlobalCustomDirectives();
    final updated = current.where((item) => item != normalized).toList();
    final preferences = await _asyncPreferences;
    await preferences.setStringList(
      SqliteChordProPreferencesRepository.legacyCustomDirectivesKey,
      updated,
    );
  }

  @override
  Future<bool> isHintDismissed() async {
    final preferences = await _asyncPreferences;
    return preferences.getBool(
          SqliteChordProPreferencesRepository.hintDismissedKey,
        ) ??
        false;
  }

  @override
  Future<void> setHintDismissed(bool dismissed) async {
    final preferences = await _asyncPreferences;
    await preferences.setBool(
      SqliteChordProPreferencesRepository.hintDismissedKey,
      dismissed,
    );
  }
}
