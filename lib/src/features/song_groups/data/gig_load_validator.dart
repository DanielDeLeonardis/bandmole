import 'dart:io';

import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';

typedef FileExistsPredicate = bool Function(String relativePath);

class GigLoadValidator {
  static Gig validateGig(
    Gig gig, {
    String? rootDirectory,
    Set<String>? availableRelativePaths,
    FileExistsPredicate? fileExistsCheck,
  }) {
    final validatedSets = <SongSet>[];

    for (final set in gig.sets) {
      final validatedSongs = <GigSong>[];
      for (final song in set.songs) {
        final exists = _checkFileExists(
          song.relativePath,
          rootDirectory: rootDirectory,
          availableRelativePaths: availableRelativePaths,
          fileExistsCheck: fileExistsCheck,
        );

        if (exists) {
          validatedSongs.add(
            song.copyWith(isBroken: false, clearBrokenReason: true),
          );
        } else {
          validatedSongs.add(
            song.copyWith(
              isBroken: true,
              brokenReason: 'Song file missing from disk: ${song.relativePath}',
            ),
          );
        }
      }
      validatedSets.add(set.copyWith(songs: validatedSongs));
    }

    return gig.copyWith(sets: validatedSets);
  }

  static bool _checkFileExists(
    String relativePath, {
    String? rootDirectory,
    Set<String>? availableRelativePaths,
    FileExistsPredicate? fileExistsCheck,
  }) {
    if (fileExistsCheck != null) {
      return fileExistsCheck(relativePath);
    }

    if (availableRelativePaths != null) {
      final normalized = SongGroupUtils.normalizePath(relativePath)
          .toLowerCase();
      return availableRelativePaths.any(
        (p) => SongGroupUtils.normalizePath(p).toLowerCase() == normalized,
      );
    }

    if (rootDirectory == null || rootDirectory.isEmpty) {
      return false;
    }

    try {
      final fullPath =
          rootDirectory.endsWith('/') || rootDirectory.endsWith('\\')
          ? '$rootDirectory$relativePath'
          : '$rootDirectory${Platform.pathSeparator}$relativePath';
      return File(fullPath).existsSync();
    } catch (_) {
      return false;
    }
  }
}
