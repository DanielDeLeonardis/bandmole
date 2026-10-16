import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

enum SongGroupErrorCode {
  gigTitleRequired,
  duplicateGigTitle,
  setTitleRequired,
  duplicateSetTitle,
  duplicateSongInGig,
  unsupportedSongFile,
  gigMustHaveAtLeastOneSet,
  setNotFound,
}

class SongGroupException implements Exception {
  final SongGroupErrorCode code;

  const SongGroupException(this.code);

  @override
  String toString() => code.name;
}

class SongGroupUtils {
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String canonicalKey(String input) {
    return normalizeWhitespace(input).toLowerCase();
  }

  static bool areTitlesEqual(String a, String b) {
    return canonicalKey(a) == canonicalKey(b);
  }

  static String normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }

  static bool arePathsEqual(String a, String b) {
    return normalizePath(a).toLowerCase() == normalizePath(b).toLowerCase();
  }

  static void validateGigTitle(
    String title,
    Iterable<String> existingTitles, {
    String? excludeTitle,
  }) {
    final normalized = normalizeWhitespace(title);
    if (normalized.isEmpty) {
      throw const SongGroupException(SongGroupErrorCode.gigTitleRequired);
    }

    final targetKey = canonicalKey(normalized);
    final excludeKey = excludeTitle != null ? canonicalKey(excludeTitle) : null;

    final hasDuplicate = existingTitles.any((existing) {
      final key = canonicalKey(existing);
      if (excludeKey != null && key == excludeKey) {
        return false;
      }
      return key == targetKey;
    });

    if (hasDuplicate) {
      throw const SongGroupException(SongGroupErrorCode.duplicateGigTitle);
    }
  }

  static void validateSetTitle(
    String title,
    Iterable<String> existingTitlesInGig, {
    String? excludeTitle,
  }) {
    final normalized = normalizeWhitespace(title);
    if (normalized.isEmpty) {
      throw const SongGroupException(SongGroupErrorCode.setTitleRequired);
    }

    final targetKey = canonicalKey(normalized);
    final excludeKey = excludeTitle != null ? canonicalKey(excludeTitle) : null;

    final hasDuplicate = existingTitlesInGig.any((existing) {
      final key = canonicalKey(existing);
      if (excludeKey != null && key == excludeKey) {
        return false;
      }
      return key == targetKey;
    });

    if (hasDuplicate) {
      throw const SongGroupException(SongGroupErrorCode.duplicateSetTitle);
    }
  }

  static void validateSongNotInGig(
    String relativeSongPath,
    Iterable<String> existingPathsInGig, {
    String? excludeSongPath,
  }) {
    final excludeNorm = excludeSongPath != null
        ? normalizePath(excludeSongPath).toLowerCase()
        : null;

    final hasDuplicate = existingPathsInGig.any((existing) {
      final norm = normalizePath(existing).toLowerCase();
      if (excludeNorm != null && norm == excludeNorm) {
        return false;
      }
      return arePathsEqual(norm, relativeSongPath);
    });

    if (hasDuplicate) {
      throw const SongGroupException(SongGroupErrorCode.duplicateSongInGig);
    }
  }

  static void validateSupportedSongPath(String relativeSongPath) {
    if (!SongFile(path: relativeSongPath).isSupportedExtension) {
      throw const SongGroupException(SongGroupErrorCode.unsupportedSongFile);
    }
  }
}
