import 'package:flutter/services.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';

class AndroidSafLibrary {
  static const _channel = MethodChannel('bandmole/android_library');

  const AndroidSafLibrary();

  Future<String?> pickRoot({String? initialUri}) async {
    return _channel.invokeMethod<String>('pickRoot', {
      'initialUri': initialUri,
    });
  }

  Future<List<SongFile>> scan(String treeUri) async {
    final entries = await _channel.invokeListMethod<Object?>('scan', {
      'treeUri': treeUri,
    });
    return (entries ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map((entry) {
          return SongFile(
            path: entry['uri']! as String,
            displayPath: entry['displayPath']! as String,
          );
        })
        .toList(growable: false);
  }

  Future<List<int>> readBytes(String documentUri) async {
    final bytes = await _channel.invokeMethod<Uint8List>('read', {
      'uri': documentUri,
    });
    return bytes ?? const <int>[];
  }

  Future<String> writeSong({
    String? uri,
    String? treeUri,
    String? relativePath,
    required String text,
  }) async {
    final savedUri = await _channel.invokeMethod<String>('writeSong', {
      'uri': uri,
      'treeUri': treeUri,
      'relativePath': relativePath,
      'text': text,
    });
    if (savedUri == null) {
      throw StateError('Android did not return the saved song URI.');
    }
    return savedUri;
  }
}
