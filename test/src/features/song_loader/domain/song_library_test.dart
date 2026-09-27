import 'dart:io';

import 'package:bandmole/src/features/song_loader/domain/song_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongLibrary', () {
    test('scanDirectory returns supported song files recursively', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'bandmole_song_library_test',
      );

      final a = File('${tempDir.path}/songs/one.cho');
      final b = File('${tempDir.path}/songs/inside/two.TXT');
      final c = File('${tempDir.path}/songs/ignore.md');

      await a.parent.create(recursive: true);
      await b.parent.create(recursive: true);
      await a.writeAsString('{title: One}');
      await b.writeAsString('Two');
      await c.writeAsString('skip');

      final files = SongLibrary.scanDirectory(tempDir.path);

      final canonicalPaths = files
          .map((song) => song.path.replaceAll('\\', '/'))
          .toList();
      expect(
        canonicalPaths,
        containsAll([
          a.path.replaceAll('\\', '/'),
          b.path.replaceAll('\\', '/'),
        ]),
      );
      expect(files, hasLength(2));
      expect(files.every((song) => song.isSupportedExtension), isTrue);
    });
  });
}
