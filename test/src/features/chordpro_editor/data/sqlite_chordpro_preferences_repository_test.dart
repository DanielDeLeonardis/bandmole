import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'bandmole_editor_prefs_test',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  SqliteChordProPreferencesRepository createRepo() {
    return SqliteChordProPreferencesRepository(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async =>
          '${temporaryDirectory.path}${Platform.pathSeparator}editor.db',
    );
  }

  test('persists global custom directives and hint dismissal across reopen', () async {
    final repo = createRepo();
    expect(await repo.loadGlobalCustomDirectives(), isEmpty);
    expect(await repo.isHintDismissed(), isFalse);

    await repo.addGlobalCustomDirective('  Stage_Cue ');
    await repo.addGlobalCustomDirective('aaa_intro');
    await repo.setHintDismissed(true);
    expect(await repo.loadGlobalCustomDirectives(), ['aaa_intro', 'stage_cue']);
    await repo.close();

    final reopened = createRepo();
    expect(await reopened.loadGlobalCustomDirectives(), [
      'aaa_intro',
      'stage_cue',
    ]);
    expect(await reopened.isHintDismissed(), isTrue);

    await reopened.removeGlobalCustomDirective('STAGE_CUE');
    expect(await reopened.loadGlobalCustomDirectives(), ['aaa_intro']);
    await reopened.close();
  });

  test('migrates legacy SharedPreferences directives into SQLite once', () async {
    SharedPreferences.setMockInitialValues({
      SqliteChordProPreferencesRepository.legacyCustomDirectivesKey: [
        'Legacy_One',
        'bad name!',
        'legacy_two',
      ],
    });

    final repo = createRepo();
    expect(await repo.loadGlobalCustomDirectives(), [
      'legacy_one',
      'legacy_two',
    ]);
    await repo.close();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList(
        SqliteChordProPreferencesRepository.legacyCustomDirectivesKey,
      ),
      isNull,
    );
  });

  test('SharedPreferencesChordProPreferencesRepository persists directives and hint', () async {
    final repo = SharedPreferencesChordProPreferencesRepository();
    expect(await repo.loadGlobalCustomDirectives(), isEmpty);
    expect(await repo.isHintDismissed(), isFalse);

    await repo.addGlobalCustomDirective('My_Cue');
    await repo.addGlobalCustomDirective('my_cue');
    await repo.addGlobalCustomDirective('alpha');
    expect(await repo.loadGlobalCustomDirectives(), ['alpha', 'my_cue']);

    await repo.removeGlobalCustomDirective('ALPHA');
    expect(await repo.loadGlobalCustomDirectives(), ['my_cue']);

    await repo.setHintDismissed(true);
    expect(await repo.isHintDismissed(), isTrue);
  });
}
