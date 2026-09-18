import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongFile', () {
    test('detects ChordPro source files by extension', () {
      expect(const SongFile(path: 'C:/music/song.cho').isChordPro, isTrue);
      expect(const SongFile(path: 'C:/music/song.crd').isChordPro, isTrue);
      expect(const SongFile(path: 'C:/music/song.txt').isChordPro, isFalse);
      expect(const SongFile(path: 'C:/music/song').isChordPro, isFalse);
    });
  });
}
