import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/services.dart';

typedef AtomicRenameFile = Future<void> Function(File tempFile, String targetPath);

class IoChordProSongStore implements ChordProSongStore {
  const IoChordProSongStore({
    this.safLibrary = const AndroidSafLibrary(),
    this.renameFile,
  });

  final AndroidSafLibrary safLibrary;
  final AtomicRenameFile? renameFile;

  @override
  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
    bool overwrite = false,
  }) async {
    if (sourceFile?.isChordPro == true) {
      final source = sourceFile!;
      if (source.path.startsWith('content://')) {
        try {
          await safLibrary.writeSong(
            uri: source.path,
            text: text,
            overwrite: true,
          );
        } on PlatformException catch (error) {
          throw _mapSafError(error, targetPath: source.namePath);
        }
      } else {
        await _writeFileAtomically(File(source.path), text);
      }
      return source;
    }

    final baseName = _safeBaseName(fileName);
    final relativeDirectory = _relativeDirectory(rootDirectory, sourceFile);
    final relativePath = [
      if (relativeDirectory.isNotEmpty) relativeDirectory,
      '$baseName.chopro',
    ].join('/');

    if (rootDirectory.startsWith('content://')) {
      try {
        final uri = await safLibrary.writeSong(
          treeUri: rootDirectory,
          relativePath: relativePath,
          text: text,
          overwrite: overwrite,
        );
        return SongFile(path: uri, displayPath: relativePath);
      } on PlatformException catch (error) {
        throw _mapSafError(error, targetPath: relativePath);
      }
    }

    final folder = relativeDirectory.isEmpty
        ? Directory(rootDirectory)
        : Directory(
            '$rootDirectory${Platform.pathSeparator}${relativeDirectory.replaceAll('/', Platform.pathSeparator)}',
          );
    if (!await folder.exists()) {
      throw ChordProSaveException(
        ChordProSaveErrorCode.folderUnavailable,
        targetPath: folder.path,
      );
    }

    final output = File(
      '${folder.path}${Platform.pathSeparator}$baseName.chopro',
    );
    if (!overwrite && await output.exists()) {
      throw ChordProSaveException(
        ChordProSaveErrorCode.fileAlreadyExists,
        targetPath: relativePath,
      );
    }

    if (overwrite && await output.exists()) {
      await _writeFileAtomically(output, text);
    } else {
      try {
        await output.create(exclusive: !overwrite);
      } on PathExistsException {
        throw ChordProSaveException(
          ChordProSaveErrorCode.fileAlreadyExists,
          targetPath: relativePath,
        );
      }
      try {
        await output.writeAsString(text);
      } catch (error) {
        if (await output.exists()) {
          await output.delete();
        }
        throw ChordProSaveException(
          ChordProSaveErrorCode.writeFailed,
          targetPath: relativePath,
          detail: error.toString(),
        );
      }
    }

    return SongFile(path: output.path, displayPath: relativePath);
  }

  Future<void> _writeFileAtomically(File target, String text) async {
    final parent = target.parent;
    if (!await parent.exists()) {
      throw ChordProSaveException(
        ChordProSaveErrorCode.folderUnavailable,
        targetPath: parent.path,
      );
    }
    final temp = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temp.writeAsString(text, flush: true);
      try {
        final doRename = renameFile;
        if (doRename != null) {
          await doRename(temp, target.path);
        } else {
          await temp.rename(target.path);
        }
      } on FileSystemException {
        await target.writeAsString(text, flush: true);
        if (await temp.exists()) {
          await temp.delete();
        }
      }
    } catch (error) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      throw ChordProSaveException(
        ChordProSaveErrorCode.writeFailed,
        targetPath: target.path,
        detail: error.toString(),
      );
    }
  }

  ChordProSaveException _mapSafError(
    PlatformException error, {
    String? targetPath,
  }) {
    if (error.code == 'EXISTS') {
      return ChordProSaveException(
        ChordProSaveErrorCode.fileAlreadyExists,
        targetPath: targetPath,
        detail: error.message,
      );
    }
    if (error.code == 'PERMISSION') {
      return ChordProSaveException(
        ChordProSaveErrorCode.writePermissionDenied,
        targetPath: targetPath,
        detail: error.message,
      );
    }
    return ChordProSaveException(
      ChordProSaveErrorCode.writeFailed,
      targetPath: targetPath,
      detail: error.message ?? error.code,
    );
  }

  String _relativeDirectory(String root, SongFile? source) {
    if (source == null) return '';
    final path =
        source.displayPath?.replaceAll('\\', '/') ??
        source.path.replaceAll('\\', '/');
    final normalizedRoot = root
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    final insideRoot = path
        .toLowerCase()
        .startsWith('${normalizedRoot.toLowerCase()}/');
    final relative = path.startsWith('content://')
        ? path
        : insideRoot
        ? path.substring(normalizedRoot.length + 1)
        : path;
    final segments = relative.split('/');
    final hasTraversalSegment = segments.any(
      (segment) => segment == '..' || segment == '.',
    );
    if (relative.startsWith('/') ||
        hasTraversalSegment ||
        relative.startsWith('content://') ||
        (source.displayPath == null && !insideRoot)) {
      throw const ChordProSaveException(ChordProSaveErrorCode.outsideLibrary);
    }
    final separator = relative.lastIndexOf('/');
    return separator < 0 ? '' : relative.substring(0, separator);
  }

  String _safeBaseName(String value) {
    final base = value
        .trim()
        .replaceFirst(
          RegExp(r'\.(chopro|chordpro|cho|crd|pro|txt)$', caseSensitive: false),
          '',
        )
        .trim();
    final stem = base.split('.').first;
    if (base.isEmpty ||
        base == '.' ||
        base == '..' ||
        RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(base) ||
        base.endsWith('.') ||
        RegExp(
          r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
          caseSensitive: false,
        ).hasMatch(stem)) {
      throw const ChordProSaveException(ChordProSaveErrorCode.invalidFilename);
    }
    return base;
  }
}
