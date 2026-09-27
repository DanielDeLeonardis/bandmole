import 'dart:io';

import 'package:bandmole/main.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:bandmole/src/features/song_loader/presentation/views/main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MainView selects and persists the songs root directory', (
    WidgetTester tester,
  ) async {
    final library = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'bandmole_library_picker_test',
      );
      await File('${directory.path}${Platform.pathSeparator}song.txt')
          .writeAsString('A song');
      return directory;
    }))!;
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MainView(directoryPicker: () async => library.path),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose song library folder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('song.txt'), findsOneWidget);
    expect(find.text('Root: ${library.path}'), findsOneWidget);
    expect(
      tester.getRect(find.byTooltip('Choose song library folder')).center.dx,
      greaterThan(tester.getRect(find.text('Root: ${library.path}')).center.dx),
    );
    expect(
      tester.getRect(find.byTooltip('Preferences')).center.dy,
      closeTo(
        tester.getRect(find.byTooltip('Choose song library folder')).center.dy,
        1,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('song_root_directory'), library.path);
  });

  testWidgets(
    'MainView filters song names with configurable case sensitivity',
    (WidgetTester tester) async {
      final library = (await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'bandmole_library_search_test',
        );
        final folder = Directory(
          '${directory.path}${Platform.pathSeparator}girl',
        );
        await folder.create();
        await File('${folder.path}${Platform.pathSeparator}anthem.txt')
            .writeAsString('Lyrics');
        await File('${directory.path}${Platform.pathSeparator}GirlSong.txt')
            .writeAsString('Lyrics');
        await File('${directory.path}${Platform.pathSeparator}GIRL POWER.cho')
            .writeAsString('Lyrics');
        await File('${directory.path}${Platform.pathSeparator}instrumental.txt')
            .writeAsString('girl appears only in contents');
        return directory;
      }))!;
      addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainView(directoryPicker: () async => library.path),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Choose song library folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'girl');
      await tester.pump();
      expect(find.text('aA'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('folder-title:girl')),
        findsOneWidget,
      );
      expect(find.text('anthem.txt'), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('folder-title:girl')));
      await tester.pumpAndSettle();
      expect(find.text('anthem.txt'), findsOneWidget);
      expect(find.text('GirlSong.txt'), findsOneWidget);
      expect(find.text('GIRL POWER.cho'), findsOneWidget);
      expect(find.text('instrumental.txt'), findsNothing);

      await tester.tap(find.byTooltip('Case-sensitive search off'));
      await tester.pump();
      expect(find.text('anthem.txt'), findsOneWidget);
      expect(find.text('GirlSong.txt'), findsNothing);
      expect(find.text('GIRL POWER.cho'), findsNothing);

      await tester.enterText(searchField, 'GIRL');
      await tester.pump();
      expect(find.text('GIRL POWER.cho'), findsOneWidget);
      expect(find.text('anthem.txt'), findsNothing);

      await tester.tap(find.byTooltip('Case-sensitive search on'));
      await tester.pump();
      expect(find.text('anthem.txt'), findsOneWidget);
      expect(find.text('GirlSong.txt'), findsOneWidget);
      expect(find.text('GIRL POWER.cho'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('folder-title:girl')));
      await tester.pumpAndSettle();
      expect(find.text('anthem.txt'), findsNothing);

      await tester.enterText(searchField, 'anthem');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('folder-title:girl')),
        findsOneWidget,
      );
      expect(find.text('anthem.txt'), findsOneWidget);
    },
  );

  testWidgets('MainView expands and collapses persisted song folders', (
    WidgetTester tester,
  ) async {
    final library = await _createSongLibrary(tester, {
      'Rehearsal/closing-song.txt': 'A song',
    });
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    const folderPath = 'Rehearsal';
    const folderKey = ValueKey<String>('folder-title:$folderPath');

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainView())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(folderKey), findsOneWidget);
    expect(find.text('closing-song.txt'), findsNothing);
    await tester.tap(find.byKey(folderKey));
    await tester.pumpAndSettle();
    expect(find.text('closing-song.txt'), findsOneWidget);

    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('expanded_song_folders'),
      contains(folderPath),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainView())),
    );
    await tester.pumpAndSettle();
    expect(find.text('closing-song.txt'), findsOneWidget);

    await tester.tap(find.byKey(folderKey));
    await tester.pumpAndSettle();
    expect(find.text('closing-song.txt'), findsNothing);

    preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('expanded_song_folders'),
      isNot(contains(folderPath)),
    );
  });

  testWidgets('MyApp shows a selected song in the Song panel', (
    WidgetTester tester,
  ) async {
    final library = await _createSongLibrary(tester, {'song.txt': 'A song'});
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final selectedFile = SongFile(
      path: '${library.path}${Platform.pathSeparator}song.txt',
    );
    final loadedSong = Song(
      file: selectedFile,
      text: 'Sample song lyrics',
      isMalformed: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songRepositoryProvider.overrideWithValue(
            _FakeSongRepository(
              selectedFile: selectedFile,
              songToLoad: loadedSong,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('song.txt'));
    await tester.pumpAndSettle();

    expect(find.byType(MainView), findsOneWidget);
    expect(find.byType(SongView), findsOneWidget);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Song'), findsOneWidget);
    expect(find.text('Sample song lyrics'), findsOneWidget);

    final transposeDownButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.remove_circle_outline,
    );
    final transposeResetButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.restart_alt,
    );
    final transposeUpButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.add_circle_outline,
    );

    expect(
      tester.widget<ElevatedButton>(transposeDownButton).onPressed,
      isNull,
    );
    expect(
      tester.widget<ElevatedButton>(transposeResetButton).onPressed,
      isNull,
    );
    expect(tester.widget<ElevatedButton>(transposeUpButton).onPressed, isNull);

    await tester.tap(find.text('Songs'));
    await tester.pumpAndSettle();
    expect(find.text('song.txt'), findsOneWidget);
    await tester.tap(find.text('song.txt'));
    await tester.pumpAndSettle();
    expect(find.text('Sample song lyrics'), findsOneWidget);
  });

  testWidgets('Selecting another song opens its lyrics at the top', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final firstFile = const SongFile(path: 'first.txt');
    final secondFile = const SongFile(path: 'second.txt');
    final firstText = List.generate(
      40,
      (index) => 'First line $index',
    ).join('\n');
    final secondText = List.generate(
      40,
      (index) => 'Second line $index',
    ).join('\n');
    final repository = _FakeSongRepository(
      selectedFile: firstFile,
      songToLoad: Song(file: firstFile, text: firstText, isMalformed: false),
    );
    final library = await _createSongLibrary(tester, {
      'first.txt': firstText,
      'second.txt': secondText,
    });
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [songRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('first.txt'));
    await tester.pumpAndSettle();
    final lyricsScrollable = find.descendant(
      of: find.byType(AutoScrollableTextWidget),
      matching: find.byType(Scrollable),
    );
    await tester.drag(lyricsScrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(lyricsScrollable).position.pixels,
      greaterThan(0),
    );

    repository.songToLoad = Song(
      file: secondFile,
      text: secondText,
      isMalformed: false,
    );
    await tester.tap(find.text('second.txt'));
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(lyricsScrollable).position.pixels, 0);
  });

  testWidgets('MainView keeps both panels side by side when wide', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final library = await _createSongLibrary(tester, {'song.txt': 'A song'});
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final selectedFile = SongFile(
      path: '${library.path}${Platform.pathSeparator}song.txt',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songRepositoryProvider.overrideWithValue(
            _FakeSongRepository(
              selectedFile: selectedFile,
              songToLoad: Song(
                file: selectedFile,
                text: 'Selected song content',
                isMalformed: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MainView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('song.txt'));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Songs'), findsNothing);
    expect(find.text('song.txt'), findsOneWidget);
    expect(find.text('Selected song content'), findsOneWidget);
    expect(
      tester.getRect(find.text('Root: ${library.path}')).center.dx,
      lessThan(tester.getRect(find.text('Selected song content')).center.dx),
    );
  });

  testWidgets('MyApp resets transpose state when opening plain text songs', (
    WidgetTester tester,
  ) async {
    final library = await _createSongLibrary(tester, {
      'song.cho': '{title: Transpose Example}\n[Bb]Hello [F]world',
      'song.txt': 'Plain text song',
    });
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final chordFile = SongFile(
      path: '${library.path}${Platform.pathSeparator}song.cho',
    );
    final plainTextFile = SongFile(
      path: '${library.path}${Platform.pathSeparator}song.txt',
    );
    final repository = _FakeSongRepository(
      selectedFile: chordFile,
      songToLoad: Song(
        file: chordFile,
        text: '''
{title: Transpose Example}
{start_of_verse}
[Bb]Hello [F]world
''',
        isMalformed: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [songRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('song.cho'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('+1', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Songs'));
    await tester.pumpAndSettle();

    repository
      ..selectedFile = plainTextFile
      ..songToLoad = Song(
        file: plainTextFile,
        text: 'Plain text song',
        isMalformed: false,
      );

    await tester.tap(find.text('song.txt'));
    await tester.pumpAndSettle();

    expect(find.text('0', skipOffstage: false), findsOneWidget);

    final transposeDownButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.remove_circle_outline,
    );
    final transposeResetButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.restart_alt,
    );
    final transposeUpButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.add_circle_outline,
    );

    expect(
      tester.widget<ElevatedButton>(transposeDownButton).onPressed,
      isNull,
    );
    expect(
      tester.widget<ElevatedButton>(transposeResetButton).onPressed,
      isNull,
    );
    expect(tester.widget<ElevatedButton>(transposeUpButton).onPressed, isNull);
  });

  testWidgets('MyApp enables transpose controls for ChordPro files', (
    WidgetTester tester,
  ) async {
    final library = await _createSongLibrary(tester, {'song.cho': 'A song'});
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final selectedFile = SongFile(
      path: '${library.path}${Platform.pathSeparator}song.cho',
    );
    final loadedSong = Song(
      file: selectedFile,
      text: 'Sample chord song',
      isMalformed: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songRepositoryProvider.overrideWithValue(
            _FakeSongRepository(
              selectedFile: selectedFile,
              songToLoad: loadedSong,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('song.cho'));
    await tester.pumpAndSettle();

    final transposeDownButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.remove_circle_outline,
    );
    final transposeResetButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.restart_alt,
    );
    final transposeUpButton = find.widgetWithIcon(
      ElevatedButton,
      Icons.add_circle_outline,
    );

    expect(
      tester.widget<ElevatedButton>(transposeDownButton).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<ElevatedButton>(transposeResetButton).onPressed,
      isNull,
    );
    expect(
      tester.widget<ElevatedButton>(transposeUpButton).onPressed,
      isNotNull,
    );
  });

  testWidgets('MyApp navigates to PreferencesView from the main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(PreferenceView), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
  });

  testWidgets('MainView remains unchanged when root selection is cancelled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: MainView(directoryPicker: () async => null)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose song library folder'));
    await tester.pumpAndSettle();

    expect(find.text('No songs found.'), findsOneWidget);
    expect(find.text('Open song'), findsNothing);
  });
}

Future<Directory> _createSongLibrary(
  WidgetTester tester,
  Map<String, String> songs,
) async {
  final library = (await tester.runAsync(() async {
    final directory = await Directory.systemTemp.createTemp(
      'bandmole_navigation_test',
    );
    for (final entry in songs.entries) {
      final file = File(
        '${directory.path}${Platform.pathSeparator}${entry.key}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
    return directory;
  }))!;

  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('song_root_directory', library.path);
  return library;
}

class _FakeSongRepository implements SongRepository {
  _FakeSongRepository({this.selectedFile, this.songToLoad});

  SongFile? selectedFile;
  Song? songToLoad;

  @override
  Future<Song> loadSong(SongFile file) async {
    return songToLoad!;
  }

  @override
  Future<SongFile?> pickSongFile() async {
    return selectedFile;
  }
}
