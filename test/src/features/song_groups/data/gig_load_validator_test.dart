import 'dart:io';

import 'package:bandmole/src/features/song_groups/data/gig_load_validator.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses an injected existence check and clears stale broken metadata', () {
    final gig = _gig(
      const GigSong(
        id: 'song-1',
        relativePath: 'songs/one.txt',
        isBroken: true,
        brokenReason: 'Old failure',
      ),
    );

    final valid = GigLoadValidator.validateGig(
      gig,
      fileExistsCheck: (path) => path == 'songs/one.txt',
    );
    final missing = GigLoadValidator.validateGig(
      gig,
      fileExistsCheck: (_) => false,
    );

    expect(valid.sets.single.songs.single.isBroken, isFalse);
    expect(valid.sets.single.songs.single.brokenReason, isNull);
    expect(missing.sets.single.songs.single.isBroken, isTrue);
    expect(
      missing.sets.single.songs.single.brokenReason,
      'Song file missing from disk: songs/one.txt',
    );
  });

  test('matches normalized paths from the available library set', () {
    final gig = _gig(
      const GigSong(id: 'song-1', relativePath: r'Songs\ONE.TXT'),
    );

    final validated = GigLoadValidator.validateGig(
      gig,
      availableRelativePaths: {'songs/one.txt'},
    );

    expect(validated.sets.single.songs.single.isBroken, isFalse);
  });

  test('checks song files under a root directory', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bandmole_gig_validator',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}${Platform.pathSeparator}one.txt')
        .writeAsString('Lyrics');
    final gig = _gig(const GigSong(id: 'song-1', relativePath: 'one.txt'));

    final validated = GigLoadValidator.validateGig(
      gig,
      rootDirectory: directory.path,
    );

    expect(validated.sets.single.songs.single.isBroken, isFalse);
  });

  test('marks a song broken when no root or available paths are supplied', () {
    final gig = _gig(const GigSong(id: 'song-1', relativePath: 'one.txt'));

    final validated = GigLoadValidator.validateGig(gig);

    expect(validated.sets.single.songs.single.isBroken, isTrue);
  });

  test('returns missing when filesystem lookup rejects an invalid path', () {
    final gig = _gig(const GigSong(id: 'song-1', relativePath: '\u0000'));

    final validated = GigLoadValidator.validateGig(
      gig,
      rootDirectory: Directory.systemTemp.path,
    );

    expect(validated.sets.single.songs.single.isBroken, isTrue);
  });
}

Gig _gig(GigSong song) => Gig(
  id: 'gig-1',
  title: 'Show',
  sets: [SongSet(id: 'set-1', title: 'Set 1', songs: [song])],
);