import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

abstract class SongFileReader {
  Future<List<int>> readBytes(SongFile file);
}
