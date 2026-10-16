import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('bandmole/android_library');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('passes the previous tree URI to the root picker', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickRoot');
      expect(call.arguments, {'initialUri': 'content://library/root'});
      return 'content://library/new-root';
    });

    expect(
      await const AndroidSafLibrary().pickRoot(
        initialUri: 'content://library/root',
      ),
      'content://library/new-root',
    );
  });

  test('returns no scanned songs when the platform returns null', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await const AndroidSafLibrary().scan('content://library/root'), isEmpty);
    expect(await const AndroidSafLibrary().readBytes('content://song/one'), isEmpty);
  });

  test('maps scanned documents to SongFile paths', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'scan');
      return [
        {
          'uri': 'content://library/document/one',
          'displayPath': 'Setlist/one.cho',
        },
      ];
    });

    final songs = await const AndroidSafLibrary().scan('content://library/root');

    expect(songs, hasLength(1));
    expect(songs.single.path, 'content://library/document/one');
    expect(songs.single.displayPath, 'Setlist/one.cho');
  });
}