import 'package:bandmole/src/features/song_loader/data/windows_song_file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows song picker supports common ChordPro extensions', () {
    expect(chordProSongFileDefaultExtension, 'cho');
    expect(chordProSongFileFilters, containsPair('ChordPro Song (*.cho)', '*.cho'));
    expect(chordProSongFileFilters, containsPair('ChordPro Song (*.crd)', '*.crd'));
    expect(chordProSongFileFilters, containsPair('ChordPro Song (*.chopro)', '*.chopro'));
    expect(chordProSongFileFilters, containsPair('ChordPro Song (*.chordpro)', '*.chordpro'));
    expect(chordProSongFileFilters, containsPair('ChordPro Song (*.pro)', '*.pro'));
    expect(chordProSongFileFilters, containsPair('Text Document (*.txt)', '*.txt'));
  });
}
