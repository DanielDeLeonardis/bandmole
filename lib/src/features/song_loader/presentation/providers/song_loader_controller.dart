import 'dart:async';

import 'package:bandmole/src/features/song_loader/domain/song.dart';
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

  Future<void> pickAndLoadSong() async {
    state = const AsyncLoading<Song?>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(songRepositoryProvider);
      final selectedFile = await repository.pickSongFile();
      if (selectedFile == null) {
        return null;
      }

      return repository.loadSong(selectedFile);
    });
  }
}
