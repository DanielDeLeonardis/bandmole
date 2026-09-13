import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class Song {
  final SongFile file;
  final String? text;
  final bool isMalformed;

  Song({
    required this.file,
    required this.text,
    required this.isMalformed,
  });
}
