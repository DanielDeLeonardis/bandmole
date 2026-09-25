import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('SongLoaderController', () {
    test('pickAndLoadSong loads a song through the repository', () async {
      final selectedFile = const SongFile(path: 'C:/music/song.txt');
      final loadedSong = Song(
        file: selectedFile,
        text: 'Hello\nWorld',
        isMalformed: false,
      );
      final repository = _FakeSongRepository(
        selectedFile: selectedFile,
        songToLoad: loadedSong,
      );
      final container = ProviderContainer(
        overrides: [
          songRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(songLoaderControllerProvider.notifier).pickAndLoadSong();

      final state = container.read(songLoaderControllerProvider);
      expect(state, isA<AsyncData<Song?>>());
      expect(state.value, same(loadedSong));
      expect(repository.pickSongFileCalls, equals(1));
      expect(repository.loadSongCalls, equals(1));
    });

    test('pickAndLoadSong leaves the state empty when no file is selected',
        () async {
      final repository = _FakeSongRepository(selectedFile: null);
      final container = ProviderContainer(
        overrides: [
          songRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(songLoaderControllerProvider.notifier).pickAndLoadSong();

      final state = container.read(songLoaderControllerProvider);
      expect(state, isA<AsyncData<Song?>>());
      expect(state.value, isNull);
      expect(repository.pickSongFileCalls, equals(1));
      expect(repository.loadSongCalls, equals(0));
    });

    test('pickAndLoadSong surfaces repository failures as AsyncError',
        () async {
      final repository = _FakeSongRepository(
        pickError: UnsupportedError('Song selection is unavailable.'),
      );
      final container = ProviderContainer(
        overrides: [
          songRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(songLoaderControllerProvider.notifier).pickAndLoadSong();

      final state = container.read(songLoaderControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<UnsupportedError>());
      expect(repository.pickSongFileCalls, equals(1));
      expect(repository.loadSongCalls, equals(0));
    });

    test('pickAndLoadSong surfaces song loading failures as AsyncError',
        () async {
      final repository = _FakeSongRepository(
        selectedFile: const SongFile(path: 'C:/music/song.txt'),
        loadError: UnsupportedError('Song loading is unavailable.'),
      );
      final container = ProviderContainer(
        overrides: [
          songRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(songLoaderControllerProvider.notifier).pickAndLoadSong();

      final state = container.read(songLoaderControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<UnsupportedError>());
      expect(repository.pickSongFileCalls, equals(1));
      expect(repository.loadSongCalls, equals(1));
    });
  });
}

class _FakeSongRepository implements SongRepository {
  _FakeSongRepository({
    this.selectedFile,
    this.songToLoad,
    this.pickError,
    this.loadError,
  });

  final SongFile? selectedFile;
  final Song? songToLoad;
  final Object? pickError;
  final Object? loadError;

  int pickSongFileCalls = 0;
  int loadSongCalls = 0;

  @override
  Future<Song> loadSong(SongFile file) async {
    loadSongCalls++;
    if (loadError != null) {
      throw loadError!;
    }
    return songToLoad!;
  }

  @override
  Future<SongFile?> pickSongFile() async {
    pickSongFileCalls++;
    if (pickError != null) {
      throw pickError!;
    }
    return selectedFile;
  }
}
