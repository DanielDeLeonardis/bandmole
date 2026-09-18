import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

abstract class SongFilePicker {
  Future<SongFile?> pickSongFile();
}
