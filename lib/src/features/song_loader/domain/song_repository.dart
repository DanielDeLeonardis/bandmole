import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

abstract class SongRepository {
  Future<SongFile?> pickSongFile();

  Future<Song> loadSong(SongFile file);
}
