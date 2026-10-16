import 'dart:io';

import 'package:bandmole/src/features/song_groups/data/sqlite_gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

final gigRepositoryProvider = Provider<GigRepository>((ref) {
  final databaseFactory = Platform.isAndroid || Platform.isIOS
      ? databaseFactorySqflitePlugin
      : databaseFactoryFfi;
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
  }

  return SqliteGigRepository(
    databaseFactory: databaseFactory,
    databasePath: _gigDatabasePath,
  );
});

Future<String> _gigDatabasePath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}databases',
  );
  await databaseDirectory.create(recursive: true);
  return '${databaseDirectory.path}${Platform.pathSeparator}bandmole.db';
}
