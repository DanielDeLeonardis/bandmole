import 'package:bandmole/src/features/song_loader/data/windows_song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
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

  test('returns null when the native picker is cancelled', () async {
    final picker = WindowsSongFilePicker(selectSongPath: () => null);

    expect(await picker.pickSongFile(), isNull);
  });

  test('returns the selected native path', () async {
    final picker = WindowsSongFilePicker(
      selectSongPath: () => r'C:\Music\song.cho',
    );

    expect((await picker.pickSongFile())?.path, r'C:\Music\song.cho');
  });
}
