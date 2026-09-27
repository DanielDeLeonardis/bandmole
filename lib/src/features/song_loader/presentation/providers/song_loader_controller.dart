import 'dart:async';

import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final songLoaderControllerProvider =
    AsyncNotifierProvider<SongLoaderController, Song?>(
      SongLoaderController.new,
    );

class SongLoaderController extends AsyncNotifier<Song?> {
  @override
  FutureOr<Song?> build() {
    return null;
  }

  Future<void> pickAndLoadSong([SongFile? selectedFile]) async {
    state = const AsyncLoading<Song?>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(songRepositoryProvider);
      final fileToLoad = selectedFile ?? await repository.pickSongFile();
      if (fileToLoad == null) {
        return null;
      }

      return repository.loadSong(fileToLoad);
    });
  }
}
