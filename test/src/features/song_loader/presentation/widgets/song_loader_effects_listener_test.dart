import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:bandmole/src/features/song_loader/presentation/widgets/song_loader_effects_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows cancellation feedback only after an active selection', (
    tester,
  ) async {
    final repository = _FakeSongRepository();
    final container = await _pumpListener(tester, repository);
    addTearDown(container.dispose);

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();

    expect(find.text('No song selected.'), findsOneWidget);
  });

  testWidgets('distinguishes unsupported selection from other errors', (
    tester,
  ) async {
    final unsupportedRepository = _FakeSongRepository(
      pickError: UnsupportedError('Picker unavailable'),
    );
    final container = await _pumpListener(tester, unsupportedRepository);
    addTearDown(container.dispose);

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();
    expect(
      find.text('Song selection is not supported on this platform.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SongLoaderEffectsListener(onSongLoaded: (_) {}),
          ),
        ),
      ),
    );
    unsupportedRepository
      ..pickError = null
      ..selectedFile = const SongFile(path: 'song.txt')
      ..loadError = StateError('Read failed');

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();
    expect(find.text('Unable to load song.'), findsOneWidget);
  });

  testWidgets('reports null song content and does not call success callback', (
    tester,
  ) async {
    var loaded = false;
    final repository = _FakeSongRepository(
      selectedFile: const SongFile(path: 'song.txt'),
      song: Song(
        file: const SongFile(path: 'song.txt'),
        text: null,
        isMalformed: false,
      ),
    );
    final container = await _pumpListener(
      tester,
      repository,
      onSongLoaded: (_) => loaded = true,
    );
    addTearDown(container.dispose);

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();

    expect(find.text('Unable to load song.'), findsOneWidget);
    expect(loaded, isFalse);
  });

  testWidgets('shows malformed text warning and resets transpose for plain text', (
    tester,
  ) async {
    Song? loaded;
    const file = SongFile(path: 'song.txt');
    final repository = _FakeSongRepository(
      selectedFile: file,
      song: Song(file: file, text: 'Lyrics', isMalformed: true),
    );
    final container = await _pumpListener(
      tester,
      repository,
      onSongLoaded: (song) => loaded = song,
    );
    addTearDown(container.dispose);
    container.read(songTransposeProvider.notifier).transposeUp();
    expect(container.read(songTransposeProvider), 1);

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();

    expect(find.text('Song contents has encoding issues. Please review.'), findsOneWidget);
    expect(container.read(songTransposeProvider), 0);
    expect(loaded?.text, 'Lyrics');
  });

  testWidgets('does not reset transpose for a transposable song', (
    tester,
  ) async {
    const file = SongFile(path: 'song.cho');
    final repository = _FakeSongRepository(
      selectedFile: file,
      song: Song(file: file, text: '[C]Lyrics', isMalformed: false),
    );
    final container = await _pumpListener(tester, repository);
    addTearDown(container.dispose);
    container.read(songTransposeProvider.notifier).transposeUp();

    await container
        .read(songLoaderControllerProvider.notifier)
        .pickAndLoadSong();
    await tester.pumpAndSettle();

    expect(container.read(songTransposeProvider), 1);
  });
}

Future<ProviderContainer> _pumpListener(
  WidgetTester tester,
  _FakeSongRepository repository, {
  ValueChanged<Song>? onSongLoaded,
}) async {
  final container = ProviderContainer(
    overrides: [songRepositoryProvider.overrideWithValue(repository)],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SongLoaderEffectsListener(onSongLoaded: onSongLoaded ?? (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

class _FakeSongRepository implements SongRepository {
  _FakeSongRepository({this.selectedFile, this.song, this.pickError, this.loadError});

  SongFile? selectedFile;
  Song? song;
  Object? pickError;
  Object? loadError;

  @override
  Future<SongFile?> pickSongFile() async {
    if (pickError case final error?) throw error;
    return selectedFile;
  }

  @override
  Future<Song> loadSong(SongFile file) async {
    if (loadError case final error?) throw error;
    return song!;
  }
}