import 'dart:convert';

import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/data/song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';

class SongRepositoryImpl implements SongRepository {
  final SongFilePicker picker;
  final SongFileReader fileReader;

  SongRepositoryImpl({
    required this.picker,
    required this.fileReader,
  });

  @override
  Future<SongFile?> pickSongFile() {
    return picker.pickSongFile();
  }

  @override
  Future<Song> loadSong(SongFile file) async {
    var isMalformed = false;
    String? songText;

    final bytes = await fileReader.readBytes(file);

    try {
      songText = utf8.decode(bytes);
    } catch (_) {
      try {
        songText = utf8.decode(bytes, allowMalformed: true);
        isMalformed = true;
      } catch (_) {
        isMalformed = true;
      }
    }

    return Song(
      file: file,
      text: songText,
      isMalformed: isMalformed,
    );
  }
}
