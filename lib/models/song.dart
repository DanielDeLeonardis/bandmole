import 'dart:io';

class Song {
  final File file;
  final String? text;
  final bool isMalformed;

  Song({
    required this.file,
    required this.text,
    required this.isMalformed,
  });
}
