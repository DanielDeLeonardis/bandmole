import 'dart:io';

import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class ChordProSongStore {
  const ChordProSongStore({this.safLibrary = const AndroidSafLibrary()});

  final AndroidSafLibrary safLibrary;

  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
  }) async {
    if (sourceFile?.isChordPro == true) {
      final source = sourceFile!;
      if (source.path.startsWith('content://')) {
        await safLibrary.writeSong(uri: source.path, text: text);
      } else {
        await File(source.path).writeAsString(text);
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
      final uri = await safLibrary.writeSong(
        treeUri: rootDirectory,
        relativePath: relativePath,
        text: text,
      );
      return SongFile(path: uri, displayPath: relativePath);
    }

    final folder = relativeDirectory.isEmpty
        ? Directory(rootDirectory)
        : Directory(
            '$rootDirectory${Platform.pathSeparator}${relativeDirectory.replaceAll('/', Platform.pathSeparator)}',
          );
    if (!await folder.exists()) {
      throw FileSystemException('Song folder is unavailable', folder.path);
    }
    final output = File(
      '${folder.path}${Platform.pathSeparator}$baseName.chopro',
    );
    await output.create(exclusive: true);
    try {
      await output.writeAsString(text);
    } catch (_) {
      await output.delete();
      rethrow;
    }
    return SongFile(path: output.path, displayPath: relativePath);
  }

  String _relativeDirectory(String root, SongFile? source) {
    if (source == null) return '';
    final path =
        source.displayPath?.replaceAll('\\', '/') ??
        source.path.replaceAll('\\', '/');
    final normalizedRoot = root
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    final relative = path.startsWith('content://')
        ? path
        : path.toLowerCase().startsWith('${normalizedRoot.toLowerCase()}/')
        ? path.substring(normalizedRoot.length + 1)
        : path;
    if (relative.startsWith('/') ||
        relative.contains('..') ||
        relative.startsWith('content://') ||
        (source.displayPath == null &&
            !path.toLowerCase().startsWith(
              '${normalizedRoot.toLowerCase()}/',
            ))) {
      throw const FormatException('Song must be inside the selected library.');
    }
    final separator = relative.lastIndexOf('/');
    return separator < 0 ? '' : relative.substring(0, separator);
  }

  String _safeBaseName(String value) {
    final base = value.trim().replaceFirst(
      RegExp(r'\.(chopro|chordpro|cho|crd|pro|txt)$', caseSensitive: false),
      '',
    );
    if (base.isEmpty ||
        base == '.' ||
        base == '..' ||
        RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(base) ||
        base.endsWith('.') ||
        RegExp(
          r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
          caseSensitive: false,
        ).hasMatch(base)) {
      throw const FormatException('Enter a valid song filename.');
    }
    return base;
  }
}
