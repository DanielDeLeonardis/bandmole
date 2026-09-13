import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:filepicker_windows/filepicker_windows.dart';

const Map<String, String> chordProSongFileFilters = {
  'ChordPro Song (*.cho)': '*.cho',
  'ChordPro Song (*.crd)': '*.crd',
  'ChordPro Song (*.chopro)': '*.chopro',
  'ChordPro Song (*.chordpro)': '*.chordpro',
  'ChordPro Song (*.pro)': '*.pro',
  'Text Document (*.txt)': '*.txt',
};

const String chordProSongFileDefaultExtension = 'cho';

class WindowsSongFilePicker implements SongFilePicker {
  WindowsSongFilePicker();

  @override
  Future<SongFile?> pickSongFile() async {
    final filePicker = OpenFilePicker()
      ..filterSpecification = chordProSongFileFilters
      ..defaultFilterIndex = 0
      ..defaultExtension = chordProSongFileDefaultExtension
      ..title = 'Select a song file';

    final selectedFile = filePicker.getFile();
    if (selectedFile == null) {
      return null;
    }

    return SongFile(path: selectedFile.path);
  }
}
