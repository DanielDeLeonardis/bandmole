import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:bandmole/src/features/song_loader/presentation/views/main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MainView navigates to SongView after loading a song',
      (WidgetTester tester) async {
    final selectedFile = const SongFile(path: 'C:/music/song.txt');
    final loadedSong = Song(
      file: selectedFile,
      text: 'Sample song lyrics',
      isMalformed: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songRepositoryProvider.overrideWithValue(
            _FakeSongRepository(
              selectedFile: selectedFile,
              songToLoad: loadedSong,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MainView(),
        ),
      ),
    );

    await tester.tap(find.text('Open song'));
    await tester.pumpAndSettle();

    expect(find.byType(SongView), findsOneWidget);
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('Sample song lyrics'), findsOneWidget);
  });
}

class _FakeSongRepository implements SongRepository {
  _FakeSongRepository({
    this.selectedFile,
    this.songToLoad,
  });

  final SongFile? selectedFile;
  final Song? songToLoad;

  @override
  Future<Song> loadSong(SongFile file) async {
    return songToLoad!;
  }

  @override
  Future<SongFile?> pickSongFile() async {
    return selectedFile;
  }
}
