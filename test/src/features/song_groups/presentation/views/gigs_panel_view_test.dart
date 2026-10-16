import 'dart:io';

import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gig_repository_provider.dart';
import 'package:bandmole/src/features/song_groups/presentation/views/gigs_panel_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
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

  testWidgets('MainView exposes the Gigs tab and confirms gig deletion', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryGigRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gigRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: MainView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gigs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('create_gig_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Friday Show');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Friday Show'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Gig'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('cancel_delete_gig_button')),
    );
    await tester.pumpAndSettle();

    expect(repository.gigs, hasLength(1));
    expect(find.text('Friday Show'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Gig'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm_delete_gig_button')),
    );
    await tester.pumpAndSettle();
    expect(repository.gigs, isEmpty);
  });

  testWidgets('dragging a library song adds it to a gig set', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final library = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'bandmole_gig_drag_test',
      );
      await File('${directory.path}${Platform.pathSeparator}song.txt')
          .writeAsString('A song');
      return directory;
    }))!;
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final repository = _MemoryGigRepository([
      Gig.create(id: 'gig-1', title: 'Show'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gigRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MainView(directoryPicker: () async => library.path),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose song library folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gigs'));
    await tester.pumpAndSettle();

    final songTile = find.byKey(
      ValueKey<String>('song:${library.path}${Platform.pathSeparator}song.txt'),
    );
    final setCard = find.byKey(const ValueKey<String>('set_card_gig-1_set_1'));
    expect(songTile, findsOneWidget);
    expect(setCard, findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('select_set_gig-1_set_1')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(songTile).onTap, isNotNull);
    await tester.timedDragFrom(
      tester.getCenter(songTile),
      tester.getCenter(setCard) - tester.getCenter(songTile),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(repository.gigs.single.allSongPaths, ['song.txt']);
    expect(
      find.descendant(
        of: find.byType(GigsPanelView),
        matching: find.text('song.txt'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('library add action persists new songs and localizes duplicates', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final library = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'bandmole_add_current_song_test',
      );
      for (final name in ['assigned.txt', 'new.txt']) {
        await File('${directory.path}${Platform.pathSeparator}$name')
            .writeAsString('Lyrics for $name');
      }
      return directory;
    });
    addTearDown(() => tester.runAsync(() => library!.delete(recursive: true)));
    final repository = _MemoryGigRepository([
      Gig(
        id: 'gig-1',
        title: 'Show',
        sets: const [
          SongSet(
            id: 'set-1',
            title: 'Opening',
            songs: [GigSong(id: 'song-1', relativePath: 'assigned.txt')],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gigRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MainView(directoryPicker: () async => library!.path),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose song library folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('gigs_tab')));
    await tester.pumpAndSettle();

    final newSongPath = '${library!.path}${Platform.pathSeparator}new.txt';
    await tester.tap(find.byKey(ValueKey<String>('add_song_btn_$newSongPath')));
    await tester.pumpAndSettle();
    expect(repository.gigs.single.allSongPaths, contains('new.txt'));

    final assignedSongPath =
        '${library.path}${Platform.pathSeparator}assigned.txt';
    await tester.tap(
      find.byKey(ValueKey<String>('add_song_btn_$assignedSongPath')),
    );
    await tester.pumpAndSettle();
    expect(find.text('This song is already in this gig.'), findsOneWidget);
  });

  testWidgets('opening a gig song locks the library until the set is closed', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final library = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'bandmole_close_open_set_test',
      );
      await File('${directory.path}${Platform.pathSeparator}song.txt')
          .writeAsString('A song');
      return directory;
    }))!;
    addTearDown(() => tester.runAsync(() => library.delete(recursive: true)));
    final repository = _MemoryGigRepository([
      Gig(
        id: 'gig-1',
        title: 'Show',
        sets: const [
          SongSet(
            id: 'set-1',
            title: 'Set 1',
            songs: [GigSong(id: 'song-1', relativePath: 'song.txt')],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gigRepositoryProvider.overrideWithValue(repository),
          songRepositoryProvider.overrideWithValue(_SongRepository()),
        ],
        child: MaterialApp(
          home: MainView(directoryPicker: () async => library.path),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose song library folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gigs'));
    await tester.pumpAndSettle();

    final librarySong = find.byKey(
      ValueKey<String>('song:${library.path}${Platform.pathSeparator}song.txt'),
    );
    expect(tester.widget<ListTile>(librarySong).onTap, isNotNull);

    await tester.tap(find.byKey(const ValueKey<String>('gig_song_song-1')));
    await tester.pumpAndSettle();

    expect(tester.widget<ListTile>(librarySong).onTap, isNull);
    expect(find.text('Close set'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('close_gig_set_button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('close_gig_set_button')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey<String>('close_gig_set_button')),
          )
          .onPressed,
      isNull,
    );
    expect(tester.widget<ListTile>(librarySong).onTap, isNotNull);
  });

  testWidgets('shows broken links and allows adding a selected library song', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryGigRepository([
      Gig(
        id: 'gig-1',
        title: 'Show',
        sets: const [
          SongSet(
            id: 'set-1',
            title: 'Set 1',
            songs: [GigSong(id: 'missing-song', relativePath: 'missing.txt')],
          ),
        ],
      ),
    ]);
    const availableSong = SongFile(path: 'library/available.cho');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gigRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: GigsPanelView(
                librarySongs: const [availableSong],
                selectedLibrarySong: availableSong,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final brokenLink = find.byKey(
      const ValueKey<String>('broken_tooltip_missing-song'),
    );
    expect(brokenLink, findsOneWidget);
    expect(
      tester.widget<Tooltip>(brokenLink).message,
      'Song file missing from disk: missing.txt',
    );

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.text('available.cho'), findsOneWidget);
    expect(
      repository.gigs.single.allSongPaths,
      contains('library/available.cho'),
    );

    final songs = repository.gigs.single.sets.single.songs;
    final availableAssignment = songs.singleWhere(
      (song) => song.relativePath == 'library/available.cho',
    );
    final missingAssignment = songs.singleWhere(
      (song) => song.relativePath == 'missing.txt',
    );
    await tester.timedDragFrom(
      tester.getCenter(
        find.byKey(ValueKey<String>('song_drag_${availableAssignment.id}')),
      ),
      tester.getCenter(
            find.byKey(ValueKey<String>('song_drag_${missingAssignment.id}')),
          ) -
          tester.getCenter(
            find.byKey(ValueKey<String>('song_drag_${availableAssignment.id}')),
          ),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(repository.gigs.single.allSongPaths, [
      'library/available.cho',
      'missing.txt',
    ]);
  });

  testWidgets(
    'gig panel edits metadata and manages sets and broken songs',
    (WidgetTester tester) async {
      final repository = _MemoryGigRepository([
        Gig(
          id: 'gig-1',
          title: 'Original Show',
          date: DateTime(2026, 10, 2),
          venue: 'The Hall',
          notes: 'Doors at seven',
          startTime: '19:30',
          sets: const [
            SongSet(
              id: 'set-1',
              title: 'Opening',
              songs: [
                GigSong(
                  id: 'missing-song',
                  relativePath: 'missing.txt',
                  isBroken: true,
                  brokenReason: 'Song file missing from disk: missing.txt',
                ),
              ],
            ),
            SongSet(id: 'set-2', title: 'Second'),
          ],
        ),
      ]);
      const newSong = SongFile(path: 'library/new.txt');
      const replacementSong = SongFile(path: 'library/replacement.cho');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [gigRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 750,
                child: GigsPanelView(
                  librarySongs: const [newSong, replacementSong],
                  rootDirectory: 'library',
                  selectedLibrarySong: newSong,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026-10-02 • 19:30 • The Hall'), findsOneWidget);
      expect(find.text('Doors at seven'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('edit_gig_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Updated Show');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.gigs.single.title, 'Updated Show');

      await tester.tap(find.byKey(const ValueKey<String>('add_set_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Finale');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final finaleSet = repository.gigs.single.sets.last;

      final secondSetCard = find.byKey(
        const ValueKey<String>('set_card_set-2'),
      );
      await tester.tap(
        find.descendant(
          of: secondSetCard,
          matching: find.byTooltip('Rename Set'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Encore');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.gigs.single.sets[1].title, 'Encore');

      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey<String>('set_card_${finaleSet.id}')),
          matching: find.byIcon(Icons.arrow_upward),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.gigs.single.sets[1].title, 'Finale');

      final movedFinale = repository.gigs.single.sets[1];
      final finaleCard = find.byKey(
        ValueKey<String>('set_card_${movedFinale.id}'),
      );
      await tester.tap(
        find.descendant(of: finaleCard, matching: find.byType(OutlinedButton)),
      );
      await tester.pumpAndSettle();
      expect(repository.gigs.single.findSongById(
        repository.gigs.single.sets[1].songs.single.id,
      )?.relativePath, 'new.txt');

      await tester.tap(find.byTooltip('Re-link Song'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ListTile),
        ).last,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final relinked = repository.gigs.single.findSongById('missing-song');
      expect(relinked?.relativePath, 'replacement.cho');
      expect(relinked?.isBroken, isFalse);
      expect(relinked?.brokenReason, isNull);
    },
  );

  testWidgets('SongView keeps a stable root when switching songs in a set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SongView(
              key: const ValueKey<String>('song_view_active'),
              text: 'Verse 1\nA\nB',
              embedded: true,
              canGoPrevious: true,
              canGoNext: true,
              gigInfo: 'Set 1 • 1/2',
              onPreviousSong: () {},
              onNextSong: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('gig_prev_song_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('gig_next_song_button')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SongView(
              key: const ValueKey<String>('song_view_active'),
              text: 'Verse 2\nC\nD',
              embedded: true,
              canGoPrevious: true,
              canGoNext: true,
              gigInfo: 'Set 1 • 2/2',
              onPreviousSong: () {},
              onNextSong: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('gig_prev_song_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('gig_next_song_button')),
      findsOneWidget,
    );
    expect(find.textContaining('Verse 2'), findsOneWidget);
  });
}

class _MemoryGigRepository implements GigRepository {
  _MemoryGigRepository([List<Gig> gigs = const []]) : gigs = List.of(gigs);

  final List<Gig> gigs;

  @override
  Future<List<Gig>> loadGigs() async => List<Gig>.of(gigs);

  @override
  Future<void> saveGig(Gig gig) async {
    final index = gigs.indexWhere((existing) => existing.id == gig.id);
    if (index < 0) {
      gigs.add(gig);
    } else {
      gigs[index] = gig;
    }
  }

  @override
  Future<void> deleteGig(String gigId) async {
    gigs.removeWhere((gig) => gig.id == gigId);
  }
}

class _SongRepository implements SongRepository {
  @override
  Future<SongFile?> pickSongFile() async => null;

  @override
  Future<Song> loadSong(SongFile file) async =>
      Song(file: file, text: 'A song', isMalformed: false);
}
