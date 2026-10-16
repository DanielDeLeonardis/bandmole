import 'dart:io';

import 'package:bandmole/src/features/song_groups/data/sqlite_gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gig_repository_provider.dart';
import 'package:bandmole/src/features/song_groups/presentation/views/gigs_panel_view.dart';
import 'package:bandmole/src/features/song_loader/presentation/views/main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
    }
  });

  testWidgets(
    'Release 2 creates, orders, and restores a gig and its songs from SQLite',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'bandmole_release_2_integration',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final library = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}songs',
      );
      await library.create();
      for (final name in ['opening.txt', 'encore.txt']) {
        await File('${library.path}${Platform.pathSeparator}$name')
            .writeAsString('Lyrics for $name');
      }

      final databasePath =
          '${temporaryDirectory.path}${Platform.pathSeparator}gigs.db';
      var repository = _repository(databasePath);
      addTearDown(() => repository.close());

      Future<void> pumpApp(SqliteGigRepository gigRepository) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gigRepositoryProvider.overrideWithValue(gigRepository),
            ],
            child: MaterialApp(
              home: MainView(directoryPicker: () async => library.path),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpApp(repository);
      await tester.tap(find.byTooltip('Choose song library folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('gigs_tab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('create_gig_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Release Two');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await _waitForGig(repository, tester, (gig) => gig.title == 'Release Two');
      await tester.pumpAndSettle();
      expect(find.text('Release Two'), findsOneWidget);
      expect(find.byType(GigsPanelView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('add_set_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Encore');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      var gig = await _waitForGig(
        repository,
        tester,
        (gig) => gig.sets.any((set) => set.title == 'Encore'),
      );

      for (final name in ['opening.txt', 'encore.txt']) {
        final songPath = '${library.path}${Platform.pathSeparator}$name';
        await tester.tap(
          find.byKey(ValueKey<String>('add_song_btn_$songPath')),
        );
        await tester.pumpAndSettle();
        gig = await _waitForGig(
          repository,
          tester,
          (gig) => gig.allSongs.any((song) => song.displayName == name),
        );
      }

      final encoreSet = gig.sets.singleWhere((set) => set.title == 'Encore');
      final encoreSongs = encoreSet.songs;
      expect(encoreSongs.map((song) => song.displayName), [
        'opening.txt',
        'encore.txt',
      ]);

      final secondSongRow = find.byKey(
        ValueKey<String>('gig_song_${encoreSongs[1].id}'),
      );
      final gigsScrollable = find.descendant(
        of: find.byType(GigsPanelView),
        matching: find.byType(Scrollable),
      ).first;
      await tester.scrollUntilVisible(
        secondSongRow,
        300,
        scrollable: gigsScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: secondSongRow,
          matching: find.byIcon(Icons.arrow_upward),
        ),
      );
      await tester.pumpAndSettle();

      gig = await _waitForGig(
        repository,
        tester,
        (gig) =>
            gig.sets
                .singleWhere((set) => set.title == 'Encore')
                .songs
                .first
                .displayName ==
            'encore.txt',
      );

      final encoreSetCard = find.byKey(
        ValueKey<String>('set_card_${encoreSet.id}'),
      );
      await tester.scrollUntilVisible(
        encoreSetCard,
        300,
        scrollable: gigsScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: encoreSetCard,
          matching: find.byIcon(Icons.arrow_upward),
        ).first,
      );
      await tester.pumpAndSettle();
      gig = await _waitForGig(
        repository,
        tester,
        (gig) => gig.sets.first.title == 'Encore',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await repository.close();
      repository = _repository(databasePath);
      await pumpApp(repository);
      await tester.tap(find.byKey(const ValueKey<String>('gigs_tab')));
      await tester.pumpAndSettle();

      expect(find.text('Release Two'), findsOneWidget);
      expect(find.text('Set 1: Encore'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GigsPanelView),
          matching: find.text('encore.txt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GigsPanelView),
          matching: find.text('opening.txt'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Release 2 gig and set creation supports keyboard-only use', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 900));
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'bandmole_release_2_keyboard',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final repository = _repository(
      '${temporaryDirectory.path}${Platform.pathSeparator}gigs.db',
    );
    addTearDown(() => repository.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gigRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: MainView()),
      ),
    );
    await tester.pumpAndSettle();

    await _tabUntilGigsSelected(tester);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      isNot(0),
    );

    final createGigButton = find.byKey(
      const ValueKey<String>('create_gig_button'),
    );
    await _tabUntilFocused(tester, createGigButton);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Keyboard Show');
    await _tabUntilFocused(
      tester,
      find.widgetWithText(ElevatedButton, 'Save'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await _waitForGig(repository, tester, (gig) => gig.title == 'Keyboard Show');
    await tester.pumpAndSettle();

    final addSetButton = find.byKey(const ValueKey<String>('add_set_button'));
    await _tabUntilFocused(tester, addSetButton);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Keyboard Encore');
    await _tabUntilFocused(
      tester,
      find.widgetWithText(ElevatedButton, 'Save'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await _waitForGig(
      repository,
      tester,
      (gig) => gig.sets.any((set) => set.title == 'Keyboard Encore'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Show'), findsOneWidget);
    expect(find.text('Set 2: Keyboard Encore'), findsOneWidget);
    expect((await repository.loadGigs()).single.sets, hasLength(2));
  });
}

Future<Gig> _waitForGig(
  SqliteGigRepository repository,
  WidgetTester tester,
  bool Function(Gig) condition,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final gigs = await repository.loadGigs();
    for (final gig in gigs) {
      if (condition(gig)) return gig;
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
  throw TestFailure('The requested gig state was not persisted.');
}

Future<void> _tabUntilGigsSelected(WidgetTester tester) async {
  final tabBarFinder = find.byType(TabBar);
  final tabBar = tester.widget<TabBar>(tabBarFinder);
  final gigsIndex = tabBar.tabs.indexWhere(
    (tab) => tab.key == const ValueKey<String>('gigs_tab'),
  );
  if (gigsIndex < 0) {
    throw TestFailure('The Gigs tab is not present in the current layout.');
  }

  for (var attempt = 0; attempt < 24; attempt++) {
    if (tester.widget<TabBar>(tabBarFinder).controller!.index == gigsIndex) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  throw TestFailure('Tab traversal did not select the Gigs panel.');
}

SqliteGigRepository _repository(String databasePath) => SqliteGigRepository(
  databaseFactory: Platform.isAndroid || Platform.isIOS
      ? databaseFactorySqflitePlugin
      : databaseFactoryFfi,
  databasePath: () async => databasePath,
);

Future<void> _tabUntilFocused(WidgetTester tester, Finder finder) async {
  final focusHistory = <String>[];
  for (var attempt = 0; attempt < 80; attempt++) {
    final primaryContext = tester.binding.focusManager.primaryFocus?.context;
    if (primaryContext != null) {
      final focusPath = <String>[];
      primaryContext.visitAncestorElements((ancestor) {
        focusPath.add(ancestor.widget.runtimeType.toString());
        return focusPath.length < 10;
      });
      final currentFocus = focusPath.join(' <- ');
      if (focusHistory.isEmpty || focusHistory.last != currentFocus) {
        focusHistory.add(currentFocus);
      }
      final matchingElements = finder.evaluate().toSet();
      var matches = false;
      primaryContext.visitAncestorElements((ancestor) {
        if (matchingElements.contains(ancestor)) {
          matches = true;
          return false;
        }
        return true;
      });
      if (matches) return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail(
    'Could not focus $finder using keyboard traversal. Focus history: '
    '${focusHistory.join(' | ')}',
  );
}