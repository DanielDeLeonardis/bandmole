import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

enum ChordProSaveErrorCode {
  invalidFilename,
  outsideLibrary,
  folderUnavailable,
  fileAlreadyExists,
  writePermissionDenied,
  writeFailed,
}

class ChordProSaveException implements Exception {
  const ChordProSaveException(
    this.code, {
    this.targetPath,
    this.detail,
  });

  final ChordProSaveErrorCode code;
  final String? targetPath;
  final String? detail;

  @override
  String toString() => detail ?? code.name;
}

abstract interface class ChordProSongStore {
  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
    bool overwrite = false,
  });
}
