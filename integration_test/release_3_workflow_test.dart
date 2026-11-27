import 'dart:io';

import 'package:bandmole/main.dart';
import 'package:bandmole/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/providers/chordpro_preferences_provider.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gig_repository_provider.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gigs_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Release 3 converts, saves, overwrites, uses keyboard actions, persists directives, and clears gig broken links',
    (tester) async {
      if (Platform.isAndroid || Platform.isIOS) return;

      sqfliteFfiInit();
      final root = await Directory.systemTemp.createTemp(
        'bandmole_editor_flow',
      );
      addTearDown(() => root.delete(recursive: true));
      final dbDir = await Directory.systemTemp.createTemp('bandmole_editor_db');
      addTearDown(() => dbDir.delete(recursive: true));

      final original = File('${root.path}${Platform.pathSeparator}song.txt');
      await original.writeAsString('C     G\nHello world');

      SharedPreferences.setMockInitialValues({
        'song_root_directory': root.path,
      });

      final gigRepository = _MemoryGigRepository([
        Gig(
          id: 'gig-1',
          title: 'Show',
          sets: const [
            SongSet(
              id: 'set-1',
              title: 'Set 1',
              songs: [
                GigSong(
                  id: 'missing-1',
                  relativePath: 'song.chopro',
                  isBroken: true,
                ),
              ],
            ),
          ],
        ),
      ]);

      SqliteChordProPreferencesRepository createPrefsRepo() =>
          SqliteChordProPreferencesRepository(
            databaseFactory: databaseFactoryFfi,
            databasePath: () async =>
                '${dbDir.path}${Platform.pathSeparator}editor.db',
          );

      final firstPrefsRepo = createPrefsRepo();
      addTearDown(firstPrefsRepo.close);

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gigRepositoryProvider.overrideWithValue(gigRepository),
              chordProPreferencesRepositoryProvider.overrideWithValue(
                firstPrefsRepo,
              ),
            ],
            child: const MyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Load gigs: song.chopro is initially missing (broken)
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MyApp)),
          listen: false,
        );
        await container
            .read(gigsControllerProvider.notifier)
            .loadGigs(
              rootDirectory: root.path,
              availableRelativePaths: {'song.txt'},
            );
        await tester.pumpAndSettle();
        expect(
          container
              .read(gigsControllerProvider)
              .gigs
              .single
              .sets
              .single
              .songs
              .single
              .isBroken,
          isTrue,
        );

        // Select plain-text song and open editor via MainView
        await tester.tap(find.text('song.txt'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('edit_chordpro_button')),
        );
        await tester.pumpAndSettle();

        // Source is read-only until explicit Convert
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey<String>('chordpro_source')),
              )
              .readOnly,
          isTrue,
        );

        // Dismiss hint and persist
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Convert to ChordPro'));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey<String>('chordpro_source')),
          '{title: Converted}\n{scroll_speed: 8}\n{start_of_verse}\n[C]Hello\n{end_of_verse}\n\n{start_of_chorus}\n[G]World\n{end_of_chorus}',
        );
        await tester.pump();

        // Reorder sections via keyboard-accessible move-down button
        await tester.tap(find.byKey(const ValueKey<String>('section_down_0')));
        await tester.pump();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey<String>('chordpro_source')),
              )
              .controller!
              .text,
          contains('{start_of_chorus}\n[G]World\n{end_of_chorus}'),
        );

        // Add a global custom directive persisted in SQLite
        await tester.tap(
          find.byKey(const ValueKey<String>('add_custom_directive_chip')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey<String>('custom_directive_input')),
          'stage_note',
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('custom_directive_add')),
        );
        for (var attempt = 0; attempt < 50; attempt++) {
          final directives = await firstPrefsRepo.loadGlobalCustomDirectives();
          await tester.pump(const Duration(milliseconds: 50));
          if (directives.contains('stage_note')) break;
        }
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey<String>('chordpro_source')),
              )
              .controller!
              .text,
          contains('{stage_note: }'),
        );
        expect(find.text('stage_note'), findsWidgets);

        // Save via Ctrl+S keyboard shortcut
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        for (var attempt = 0; attempt < 20; attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Song saved.').evaluate().isNotEmpty) break;
        }
        await tester.pumpAndSettle();
        expect(find.text('Song saved.'), findsOneWidget);

        final converted = File(
          '${root.path}${Platform.pathSeparator}song.chopro',
        );
        expect(await original.readAsString(), 'C     G\nHello world');
        expect(await converted.readAsString(), contains('{stage_note: }'));

        // Close editor via Escape shortcut -> gig broken link is automatically cleared
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('song.chopro'), findsOneWidget);
        expect(find.text('8', skipOffstage: false), findsOneWidget);
        expect(
          container
              .read(gigsControllerProvider)
              .gigs
              .single
              .sets
              .single
              .songs
              .single
              .isBroken,
          isFalse,
        );

        // Re-open with a fresh SQLite repository instance to verify persistence
        await firstPrefsRepo.close();
        final reopenedPrefsRepo = createPrefsRepo();
        addTearDown(reopenedPrefsRepo.close);
        expect(await reopenedPrefsRepo.loadGlobalCustomDirectives(), [
          'stage_note',
        ]);
        expect(await reopenedPrefsRepo.isHintDismissed(), isTrue);

        // Re-open plain-text song, convert again, and verify explicit overwrite dialog
        await tester.tap(find.text('song.txt'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('edit_chordpro_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Convert to ChordPro'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
        await tester.pumpAndSettle();

        expect(find.text('Overwrite existing file?'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('chordpro_confirm_overwrite')),
        );
        for (var attempt = 0; attempt < 20; attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Song saved.').evaluate().isNotEmpty) break;
        }
        await tester.pumpAndSettle();
        expect(find.text('Song saved.'), findsOneWidget);
        expect(await converted.readAsString(), '[C]Hello [G]world');
      } finally {
        semantics.dispose();
      }
    },
  );
}

class _MemoryGigRepository implements GigRepository {
  _MemoryGigRepository(List<Gig> initial) : _gigs = List.of(initial);

  final List<Gig> _gigs;

  @override
  Future<List<Gig>> loadGigs() async => List.of(_gigs);

  @override
  Future<void> saveGig(Gig gig) async {
    _gigs.removeWhere((item) => item.id == gig.id);
    _gigs.add(gig);
  }

  @override
  Future<void> deleteGig(String gigId) async {
    _gigs.removeWhere((item) => item.id == gigId);
  }
}
