import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class UnsupportedChordProSongStore implements ChordProSongStore {
  const UnsupportedChordProSongStore();

  @override
  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
    bool overwrite = false,
  }) {
    throw UnsupportedError(
      'Saving ChordPro songs is not supported on this platform.',
    );
  }
}
