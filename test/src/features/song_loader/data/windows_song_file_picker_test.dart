import 'package:bandmole/src/features/song_loader/data/windows_song_file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows song picker shows a single combined filter for allowed files',
      () {
    expect(chordProSongFileFilters, hasLength(1));
    expect(
      chordProSongFileFilters,
      containsPair(
        'Song Files',
        '*.cho;*.crd;*.chopro;*.chordpro;*.pro;*.txt',
      ),
    );
  });
}
