import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

final Provider<ChordProPreferencesRepository>
chordProPreferencesRepositoryProvider =
    Provider<ChordProPreferencesRepository>((ref) {
      final isMobile = Platform.isAndroid || Platform.isIOS;
      final factory = isMobile
          ? databaseFactorySqflitePlugin
          : databaseFactoryFfi;
      if (!isMobile) {
        sqfliteFfiInit();
      }
      final repository = SqliteChordProPreferencesRepository(
        databaseFactory: factory,
        databasePath: _editorDatabasePath,
      );
      ref.onDispose(repository.close);
      return repository;
    });

Future<String> _editorDatabasePath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}databases',
  );
  await databaseDirectory.create(recursive: true);
  return '${databaseDirectory.path}${Platform.pathSeparator}bandmole_editor.db';
}
