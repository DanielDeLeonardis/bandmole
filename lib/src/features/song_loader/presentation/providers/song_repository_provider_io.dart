import 'dart:io' show Platform;

import 'package:bandmole/src/features/song_loader/data/io_song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/data/song_repository_impl.dart';
import 'package:bandmole/src/features/song_loader/data/unsupported_song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/data/windows_song_file_picker.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<SongRepository> songRepositoryProvider =
    Provider<SongRepository>((_) {
  final picker = Platform.isWindows
      ? WindowsSongFilePicker()
      : const UnsupportedSongFilePicker();

  return SongRepositoryImpl(
    picker: picker,
    fileReader: const IoSongFileReader(),
  );
});
