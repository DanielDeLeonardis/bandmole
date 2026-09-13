import 'package:bandmole/main.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyApp navigates to SongView after loading a song',
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
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open song'));
    await tester.pumpAndSettle();

    expect(find.byType(SongView), findsOneWidget);
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('Sample song lyrics'), findsOneWidget);
  });

  testWidgets('MyApp navigates to PreferencesView from the main screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(PreferenceView), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
  });

  testWidgets('MyApp shows a snackbar when song selection is cancelled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songRepositoryProvider.overrideWithValue(
            _FakeSongRepository(selectedFile: null),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open song'));
    await tester.pumpAndSettle();

    expect(find.text('No song selected.'), findsOneWidget);
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
