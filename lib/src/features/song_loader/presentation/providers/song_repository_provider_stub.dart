import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<SongRepository> songRepositoryProvider =
    Provider<SongRepository>((_) {
  return _UnsupportedSongRepository();
});

class _UnsupportedSongRepository implements SongRepository {
  @override
  Future<Song> loadSong(SongFile file) {
    throw UnsupportedError(
      'Song loading is only supported on IO platforms in this build.',
    );
  }

  @override
  Future<SongFile?> pickSongFile() {
    throw UnsupportedError(
      'Song selection is only supported on IO platforms in this build.',
    );
  }
}
