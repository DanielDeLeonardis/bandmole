import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/data/chordpro_song_store.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates ChordPro beside source without altering original', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_store');
    addTearDown(() => root.delete(recursive: true));
    final folder = Directory('${root.path}${Platform.pathSeparator}set');
    await folder.create();
    final source = File('${folder.path}${Platform.pathSeparator}song.txt');
    await source.writeAsString('Original lyrics');
    final store = ChordProSongStore();

    final saved = await store.save(
      rootDirectory: root.path,
      fileName: 'song',
      text: '[C]Original lyrics',
      sourceFile: SongFile(path: source.path),
    );

    expect(saved.path, endsWith('song.chopro'));
    expect(await File(saved.path).readAsString(), '[C]Original lyrics');
    expect(await source.readAsString(), 'Original lyrics');
    expect(
      () => store.save(
        rootDirectory: root.path,
        fileName: 'song',
        text: 'Duplicate',
        sourceFile: SongFile(path: source.path),
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('edits an existing ChordPro file without changing its path', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_edit');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}${Platform.pathSeparator}song.chopro');
    await file.writeAsString('# note\r\n{unknown: value}\r\n');
    final saved = await const ChordProSongStore().save(
      rootDirectory: root.path,
      fileName: 'ignored',
      text: '# note\r\n{unknown: changed}\r\n',
      sourceFile: SongFile(path: file.path),
    );
    expect(saved.path, file.path);
    expect(await file.readAsString(), '# note\r\n{unknown: changed}\r\n');
  });

  test('rejects unsafe filenames', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_name');
    addTearDown(() => root.delete(recursive: true));
    expect(
      () => const ChordProSongStore().save(
        rootDirectory: root.path,
        fileName: '../escape',
        text: 'lyrics',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
