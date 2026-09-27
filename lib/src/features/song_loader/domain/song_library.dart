import 'dart:io';

import 'song_file.dart';

class SongLibrary {
  static const Set<String> supportedExtensions = {
    '.cho',
    '.crd',
    '.chopro',
    '.chordpro',
    '.pro',
    '.txt',
  };

  static List<SongFile> scanDirectory(String rootPath) {
    final directory = Directory(rootPath);
    if (!directory.existsSync()) {
      return const <SongFile>[];
    }

    final files =
        directory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => SongFile(path: file.path).isSupportedExtension)
            .map((file) => SongFile(path: file.path))
            .toList()
          ..sort(
            (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
          );

    return files;
  }
}
