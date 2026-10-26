import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:filepicker_windows/filepicker_windows.dart';

const Map<String, String> chordProSongFileFilters = {
  'Song Files': '*.cho;*.crd;*.chopro;*.chordpro;*.pro;*.txt',
};

class WindowsSongFilePicker implements SongFilePicker {
  WindowsSongFilePicker({this.selectSongPath});

  final String? Function()? selectSongPath;

  @override
  Future<SongFile?> pickSongFile() async {
    final configuredPath = selectSongPath;
    final String? selectedPath;
    if (configuredPath != null) {
      selectedPath = configuredPath();
    } else {
      final filePicker = OpenFilePicker()
        ..filterSpecification = chordProSongFileFilters
        ..title = 'Select a song file';
      selectedPath = filePicker.getFile()?.path;
    }
    if (selectedPath == null) {
      return null;
    }

    return SongFile(path: selectedPath);
  }
}
