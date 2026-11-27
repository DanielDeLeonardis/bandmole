import 'dart:convert';
import 'dart:io';
import 'package:bandmole/src/features/song_loader/data/io_song_file_reader.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads song bytes from a filesystem path', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bandmole_io_reader',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}song.txt');
    await file.writeAsString('Lyrics');

    final bytes = await const IoSongFileReader().readBytes(
      SongFile(path: file.path),
    );

    expect(utf8.decode(bytes), 'Lyrics');
  });

  test('reads song bytes through Android SAF for content URIs', () async {
    const channel = MethodChannel('bandmole/android_library');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'read');
      expect(call.arguments, {'uri': 'content://library/song-1'});
      return Uint8List.fromList(utf8.encode('SAF lyrics'));
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final bytes = await const IoSongFileReader().readBytes(
      const SongFile(path: 'content://library/song-1'),
    );

    expect(utf8.decode(bytes), 'SAF lyrics');
  });
}
