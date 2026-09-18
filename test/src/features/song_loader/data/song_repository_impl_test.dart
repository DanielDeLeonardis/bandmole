import 'dart:convert';

import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/data/song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/data/song_repository_impl.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongRepositoryImpl', () {
    test('pickSongFile delegates to the configured picker', () async {
      final expectedFile = SongFile(path: 'C:/music/song.txt');
      final repository = SongRepositoryImpl(
        picker: _FakeSongFilePicker(expectedFile),
        fileReader: _FakeSongFileReader(const []),
      );

      final selectedFile = await repository.pickSongFile();

      expect(selectedFile, same(expectedFile));
    });

    test('loadSong decodes UTF-8 content', () async {
      final file = SongFile(path: 'C:/music/song.txt');
      final repository = SongRepositoryImpl(
        picker: _FakeSongFilePicker(file),
        fileReader: _FakeSongFileReader(utf8.encode('Hello\nWorld')),
      );

      final song = await repository.loadSong(file);

      expect(song.file, same(file));
      expect(song.text, equals('Hello\nWorld'));
      expect(song.isMalformed, isFalse);
    });

    test('loadSong marks malformed content when the bytes are invalid UTF-8',
        () async {
      final file = SongFile(path: 'C:/music/broken.txt');
      final repository = SongRepositoryImpl(
        picker: _FakeSongFilePicker(file),
        fileReader: _FakeSongFileReader([0xff, 0xfe, 0xfd]),
      );

      final song = await repository.loadSong(file);

      expect(song.file, same(file));
      expect(song.text, isNotNull);
      expect(song.isMalformed, isTrue);
    });
  });
}

class _FakeSongFilePicker implements SongFilePicker {
  _FakeSongFilePicker(this.songFile);

  final SongFile songFile;

  @override
  Future<SongFile?> pickSongFile() async {
    return songFile;
  }
}

class _FakeSongFileReader implements SongFileReader {
  _FakeSongFileReader(this.bytes);

  final List<int> bytes;

  @override
  Future<List<int>> readBytes(SongFile _) async {
    return bytes;
  }
}
