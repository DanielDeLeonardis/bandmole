import 'dart:convert';
import 'dart:io';

import 'package:bandmole/src/features/song_groups/data/sqlite_gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
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
      'bandmole_sqlite_gigs_test',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('persists gig hierarchy and ordering across repository reopen', () async {
    final gig = _gig();
    final firstRepository = _repository(temporaryDirectory);

    await firstRepository.saveGig(gig);
    await firstRepository.close();

    final reopenedRepository = _repository(temporaryDirectory);
    expect(await reopenedRepository.loadGigs(), [gig]);
    await reopenedRepository.close();
  });

  test('migrates legacy preferences once and removes them after commit', () async {
    final preferences = await SharedPreferences.getInstance();
    final gig = _gig();
    await preferences.setString(
      SqliteGigRepository.legacyStorageKey,
      jsonEncode([gig.toJson()]),
    );
    final repository = SqliteGigRepository(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => _databasePath(temporaryDirectory),
      preferences: preferences,
    );

    expect(await repository.loadGigs(), [gig]);
    expect(
      preferences.containsKey(SqliteGigRepository.legacyStorageKey),
      isFalse,
    );
    await repository.close();
  });

  test('retains corrupt legacy data instead of silently replacing it', () async {
    final preferences = await SharedPreferences.getInstance();
    const corruptData = '{not valid json';
    await preferences.setString(
      SqliteGigRepository.legacyStorageKey,
      corruptData,
    );
    final repository = SqliteGigRepository(
      databaseFactory: databaseFactoryFfi,
      databasePath: () async => _databasePath(temporaryDirectory),
      preferences: preferences,
    );

    await expectLater(
      repository.loadGigs(),
      throwsA(isA<FormatException>()),
    );
    expect(
      preferences.getString(SqliteGigRepository.legacyStorageKey),
      corruptData,
    );
  });

  test('rolls back a failed gig replacement without losing prior data', () async {
    final repository = _repository(temporaryDirectory);
    final original = _gig();
    await repository.saveGig(original);
    final invalidReplacement = Gig(
      id: original.id,
      title: 'Replacement',
      sets: const [
        SongSet(
          id: 'set-a',
          title: 'A',
          songs: [GigSong(id: 'duplicate-song', relativePath: 'one.txt')],
        ),
        SongSet(
          id: 'set-b',
          title: 'B',
          songs: [GigSong(id: 'duplicate-song', relativePath: 'two.txt')],
        ),
      ],
    );

    await expectLater(repository.saveGig(invalidReplacement), throwsA(anything));

    expect(await repository.loadGigs(), [original]);
    await repository.close();
  });
}

SqliteGigRepository _repository(Directory directory) => SqliteGigRepository(
  databaseFactory: databaseFactoryFfi,
  databasePath: () async => _databasePath(directory),
);

String _databasePath(Directory directory) =>
    '${directory.path}${Platform.pathSeparator}gigs.db';

Gig _gig() => Gig(
  id: 'gig-1',
  title: 'Friday Show',
  date: DateTime(2026, 10, 2),
  venue: 'The Hall',
  notes: 'Doors at seven',
  startTime: '19:30',
  sets: const [
    SongSet(
      id: 'set-1',
      title: 'Opening',
      songs: [
        GigSong(
          id: 'song-1',
          relativePath: 'openers/first.cho',
          isBroken: true,
          brokenReason: 'File missing',
        ),
      ],
    ),
    SongSet(id: 'set-2', title: 'Encore'),
  ],
);