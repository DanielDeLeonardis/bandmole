import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class UnsupportedSongFilePicker implements SongFilePicker {
  const UnsupportedSongFilePicker();

  @override
  Future<SongFile?> pickSongFile() async {
    throw UnsupportedError(
      'Song selection is only supported on Windows in this build.',
    );
  }
}
