import 'dart:io';

import 'package:bandmole/src/features/song_loader/data/song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class IoSongFileReader implements SongFileReader {
  const IoSongFileReader({this.safLibrary = const AndroidSafLibrary()});

  final AndroidSafLibrary safLibrary;

  @override
  Future<List<int>> readBytes(SongFile file) {
    if (file.path.startsWith('content://')) {
      return safLibrary.readBytes(file.path);
    }
    return File(file.path).readAsBytes();
  }
}
