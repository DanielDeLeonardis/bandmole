import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SongSet equality distinguishes identical and different instances', () {
    const first = SongSet(id: 'set-1', title: 'Set 1');
    const sameValues = SongSet(id: 'set-1', title: 'Set 1');
    const differentTitle = SongSet(id: 'set-1', title: 'Set 2');

    expect(first == first, isTrue);
    expect(first == sameValues, isTrue);
    expect(first == differentTitle, isFalse);
  });

  test('SongSet.fromJson accepts missing song lists', () {
    final song = GigSong(id: 'song-1', relativePath: 'opening.txt');
    final set = SongSet.fromJson({
      'id': 'set-1',
      'title': 'Set 1',
      'songs': [song.toJson()],
    });

    expect(set.songs, [song]);
    expect(SongSet.fromJson({'id': 'set-2', 'title': 'Set 2'}).songs, isEmpty);
  });
}
