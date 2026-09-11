import 'dart:io';

import 'package:filepicker_windows/filepicker_windows.dart';

class FilePicker {
  late OpenFilePicker file;

  FilePicker() {
    file = OpenFilePicker()
      ..filterSpecification = {
        'Text Document (*.txt)': '*.txt',
      }
      ..defaultFilterIndex = 0
      ..defaultExtension = 'txt'
      ..title = 'Select a song text file';
  }

  File? getFile() {
    return file.getFile();
  }
}
