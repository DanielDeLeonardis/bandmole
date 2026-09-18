import 'dart:io';

import 'package:bandmole/src/features/song_loader/data/song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class IoSongFileReader implements SongFileReader {
  const IoSongFileReader();

  @override
  Future<List<int>> readBytes(SongFile file) {
    return File(file.path).readAsBytes();
  }
}
