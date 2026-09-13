import 'package:bandmole/src/features/song_loader/data/song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:filepicker_windows/filepicker_windows.dart';

class WindowsSongFilePicker implements SongFilePicker {
  WindowsSongFilePicker();

  @override
  Future<SongFile?> pickSongFile() async {
    final filePicker = OpenFilePicker()
      ..filterSpecification = {
        'Text Document (*.txt)': '*.txt',
      }
      ..defaultFilterIndex = 0
      ..defaultExtension = 'txt'
      ..title = 'Select a song text file';

    final selectedFile = filePicker.getFile();
    if (selectedFile == null) {
      return null;
    }

    return SongFile(path: selectedFile.path);
  }
}
