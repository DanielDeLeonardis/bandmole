import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/data/io_chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/data/unsupported_chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates ChordPro beside source without altering original and supports overwrite', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_store');
    addTearDown(() => root.delete(recursive: true));
    final folder = Directory('${root.path}${Platform.pathSeparator}set');
    await folder.create();
    final source = File('${folder.path}${Platform.pathSeparator}song.txt');
    await source.writeAsString('Original lyrics');
    const store = IoChordProSongStore();

    final saved = await store.save(
      rootDirectory: root.path,
      fileName: 'song',
      text: '[C]Original lyrics',
      sourceFile: SongFile(path: source.path),
    );

    expect(saved.path, endsWith('song.chopro'));
    expect(await File(saved.path).readAsString(), '[C]Original lyrics');
    expect(await source.readAsString(), 'Original lyrics');

    await expectLater(
      () => store.save(
        rootDirectory: root.path,
        fileName: 'song',
        text: 'Duplicate',
        sourceFile: SongFile(path: source.path),
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.fileAlreadyExists,
        ),
      ),
    );

    final overwritten = await store.save(
      rootDirectory: root.path,
      fileName: 'song',
      text: '[G]Updated lyrics',
      sourceFile: SongFile(path: source.path),
      overwrite: true,
    );
    expect(overwritten.path, saved.path);
    expect(await File(overwritten.path).readAsString(), '[G]Updated lyrics');
  });

  test('falls back to direct write when atomic rename fails and cleans up temp file', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_fallback');
    addTearDown(() => root.delete(recursive: true));
    final existing = File('${root.path}${Platform.pathSeparator}song.chopro');
    await existing.writeAsString('Old');

    final store = IoChordProSongStore(
      renameFile: (_, _) async {
        throw const FileSystemException('Simulated Windows AV lock');
      },
    );

    await store.save(
      rootDirectory: root.path,
      fileName: 'ignored',
      text: 'New via fallback',
      sourceFile: SongFile(path: existing.path),
    );

    expect(await existing.readAsString(), 'New via fallback');
    final tmpFiles = root
        .listSync()
        .where((entity) => entity.path.endsWith('.tmp'))
        .toList();
    expect(tmpFiles, isEmpty);

    // Non-FileSystemException in rename wraps as writeFailed and cleans up temp
    final failingStore = IoChordProSongStore(
      renameFile: (_, _) async {
        throw StateError('Unexpected rename error');
      },
    );
    await expectLater(
      () => failingStore.save(
        rootDirectory: root.path,
        fileName: 'ignored',
        text: 'Should fail',
        sourceFile: SongFile(path: existing.path),
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.writeFailed,
        ),
      ),
    );
  });

  test('allows filenames containing double dots when not a traversal segment', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_dots');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}${Platform.pathSeparator}Wait..What.txt');
    await source.writeAsString('Hello');

    final saved = await const IoChordProSongStore().save(
      rootDirectory: root.path,
      fileName: 'Wait..What',
      text: '[C]Hello',
      sourceFile: SongFile(path: source.path),
    );

    expect(saved.displayPath, 'Wait..What.chopro');
    expect(await File(saved.path).readAsString(), '[C]Hello');
  });

  test('edits an existing ChordPro file atomically without changing its path', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_edit');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}${Platform.pathSeparator}song.chopro');
    await file.writeAsString('# note\r\n{unknown: value}\r\n');
    final saved = await const IoChordProSongStore().save(
      rootDirectory: root.path,
      fileName: 'ignored',
      text: '# note\r\n{unknown: changed}\r\n',
      sourceFile: SongFile(path: file.path),
    );
    expect(saved.path, file.path);
    expect(await file.readAsString(), '# note\r\n{unknown: changed}\r\n');
  });

  test('rejects unsafe filenames, missing folders, and outside-library sources', () async {
    final root = await Directory.systemTemp.createTemp('chordpro_name');
    addTearDown(() => root.delete(recursive: true));

    for (final badName in ['../escape', '', 'con.foo', 'aux', 'bad:name']) {
      await expectLater(
        () => const IoChordProSongStore().save(
          rootDirectory: root.path,
          fileName: badName,
          text: 'lyrics',
        ),
        throwsA(
          isA<ChordProSaveException>().having(
            (e) => e.code,
            'code',
            ChordProSaveErrorCode.invalidFilename,
          ),
        ),
      );
    }

    await expectLater(
      () => const IoChordProSongStore().save(
        rootDirectory: root.path,
        fileName: 'song',
        text: 'lyrics',
        sourceFile: const SongFile(path: '/outside/library/song.txt'),
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.outsideLibrary,
        ),
      ),
    );

    await expectLater(
      () => const IoChordProSongStore().save(
        rootDirectory: '${root.path}${Platform.pathSeparator}missing_dir',
        fileName: 'song',
        text: 'lyrics',
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.folderUnavailable,
        ),
      ),
    );

    await expectLater(
      () => const IoChordProSongStore().save(
        rootDirectory: root.path,
        fileName: 'ignored',
        text: 'lyrics',
        sourceFile: SongFile(
          path:
              '${root.path}${Platform.pathSeparator}missing${Platform.pathSeparator}song.chopro',
        ),
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.folderUnavailable,
        ),
      ),
    );
  });

  test('saves and maps errors through Android SAF library', () async {
    final fakeSaf = _FakeSafLibrary();
    final store = IoChordProSongStore(safLibrary: fakeSaf);

    final created = await store.save(
      rootDirectory: 'content://library/tree',
      fileName: 'New Song',
      text: '[C]Hello',
      sourceFile: const SongFile(
        path: 'content://library/doc/1',
        displayPath: 'Set1/New Song.txt',
      ),
    );
    expect(created.path, 'content://library/doc/saved');
    expect(created.displayPath, 'Set1/New Song.chopro');
    expect(fakeSaf.lastRelativePath, 'Set1/New Song.chopro');
    expect(fakeSaf.lastOverwrite, isFalse);

    final edited = await store.save(
      rootDirectory: 'content://library/tree',
      fileName: 'ignored',
      text: '[G]Updated',
      sourceFile: const SongFile(
        path: 'content://library/doc/2',
        displayPath: 'Set1/existing.chopro',
      ),
    );
    expect(edited.path, 'content://library/doc/2');
    expect(fakeSaf.lastUri, 'content://library/doc/2');

    fakeSaf.errorToThrow = PlatformException(code: 'EXISTS', message: 'exists');
    await expectLater(
      () => store.save(
        rootDirectory: 'content://library/tree',
        fileName: 'New Song',
        text: '[C]Hello',
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.fileAlreadyExists,
        ),
      ),
    );

    fakeSaf.errorToThrow = PlatformException(code: 'PERMISSION', message: 'denied');
    await expectLater(
      () => store.save(
        rootDirectory: 'content://library/tree',
        fileName: 'New Song',
        text: '[C]Hello',
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.writePermissionDenied,
        ),
      ),
    );

    fakeSaf.errorToThrow = PlatformException(code: 'WRITE', message: 'io');
    await expectLater(
      () => store.save(
        rootDirectory: 'content://library/tree',
        fileName: 'ignored',
        text: '[G]Updated',
        sourceFile: const SongFile(
          path: 'content://library/doc/2',
          displayPath: 'existing.chopro',
        ),
      ),
      throwsA(
        isA<ChordProSaveException>().having(
          (e) => e.code,
          'code',
          ChordProSaveErrorCode.writeFailed,
        ),
      ),
    );
  });

  test('UnsupportedChordProSongStore throws UnsupportedError', () {
    expect(
      () => const UnsupportedChordProSongStore().save(
        rootDirectory: 'lib',
        fileName: 'song',
        text: 'hello',
      ),
      throwsUnsupportedError,
    );
  });
}

class _FakeSafLibrary extends AndroidSafLibrary {
  String? lastUri;
  String? lastTreeUri;
  String? lastRelativePath;
  bool? lastOverwrite;
  PlatformException? errorToThrow;

  @override
  Future<String> writeSong({
    String? uri,
    String? treeUri,
    String? relativePath,
    required String text,
    bool overwrite = false,
  }) async {
    lastUri = uri;
    lastTreeUri = treeUri;
    lastRelativePath = relativePath;
    lastOverwrite = overwrite;
    if (errorToThrow != null) throw errorToThrow!;
    return uri ?? 'content://library/doc/saved';
  }
}
