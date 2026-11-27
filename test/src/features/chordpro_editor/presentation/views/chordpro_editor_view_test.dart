import 'package:bandmole/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/views/chordpro_editor_view.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapEditor(Widget child) =>
    ProviderScope(child: MaterialApp(home: child));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'creates a song, inserts chords and directives, and previews ChordPro markup',
    (tester) async {
      final store = _RecordingSongStore();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: const ChordProEditorRequest(rootDirectory: 'test-library'),
            store: store,
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chordpro_chords')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_filename')),
        'New Song',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_source')),
        '{title: New Song}\nHello',
      );
      await tester.pump();

      // Tap a chord chip to insert [C]
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('chordpro_chords')),
          matching: find.text('C'),
        ),
      );
      await tester.pump();

      final preview = tester.widget<SongTextRenderer>(
        find.byType(SongTextRenderer),
      );
      expect(preview.song.title, 'New Song');
      expect(preview.song.sections.single.lines.single.hasChords, isTrue);

      await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
      await tester.pump();
      expect(store.savedText, '{title: New Song}\nHello[C]');
      expect(store.savedFileName, 'New Song');
      expect(store.savedSourceFile, isNull);
    },
  );

  testWidgets(
    'plain-text source is read-only until convert, surfaces ambiguity notice, and cancel keeps edits and focus',
    (tester) async {
      final store = _RecordingSongStore();
      final source = SongFile(path: 'test-library/song.txt');
      const originalText = 'C     G\nHello world\nA beautiful day';
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: ChordProEditorRequest(
              rootDirectory: 'test-library',
              song: Song(file: source, text: originalText, isMalformed: false),
            ),
            store: store,
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sourceField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('chordpro_source')),
      );
      expect(sourceField.readOnly, isTrue);
      expect(
        find.byKey(const ValueKey<String>('chordpro_readonly_notice')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_filename')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey<String>('chordpro_save')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Convert to ChordPro'));
      await tester.pumpAndSettle();

      expect(
        find.text('Converted with 1 line(s) left unchanged for review.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_source')),
            )
            .readOnly,
        isFalse,
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('chordpro_source')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_source')),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
      await tester.pump();
      expect(store.savedText, '[C]Hello [G]world\nA beautiful day');
      expect(store.savedSourceFile, same(source));
    },
  );

  testWidgets(
    'prompts explicit overwrite confirmation when file already exists',
    (tester) async {
      final store = _RecordingSongStore()..failFirstWithExists = true;
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: const ChordProEditorRequest(rootDirectory: 'test-library'),
            store: store,
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_filename')),
        'Existing',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_source')),
        '[G]Updated',
      );
      await tester.pump();

      // First attempt: cancel overwrite
      await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
      await tester.pumpAndSettle();
      expect(find.text('Overwrite existing file?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.savedOverwrite, isNull);

      // Second attempt: confirm overwrite
      await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('chordpro_confirm_overwrite')),
      );
      await tester.pumpAndSettle();
      expect(store.savedOverwrite, isTrue);
      expect(store.savedText, '[G]Updated');
    },
  );

  testWidgets(
    'supports custom chords, global and per-song custom directives, and hint dismissal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: const ChordProEditorRequest(rootDirectory: 'test-library'),
            store: _RecordingSongStore(),
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dismiss hint and verify persistence
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chordpro_editor_hint_dismissed'), isTrue);

      // Reject empty custom chord
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_chord_chip')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a chord name.'), findsOneWidget);

      // Add custom chord
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_chord_chip')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom_chord_input')),
        'Cadd9',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_source')),
            )
            .controller!
            .text,
        contains('[Cadd9]'),
      );

      // Add global custom directive
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_directive_chip')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom_directive_input')),
        '  Stage_Cue  ',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('chordpro_custom_directives'), ['stage_cue']);

      // Add per-song custom directive (not saved globally)
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_directive_chip')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom_directive_input')),
        'solo_note',
      );
      await tester.tap(find.text('This song only'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('chordpro_custom_directives'), ['stage_cue']);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_source')),
            )
            .controller!
            .text,
        contains('{solo_note: }'),
      );

      // Reject duplicate custom directive
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_directive_chip')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom_directive_input')),
        'STAGE_CUE',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(
        find.text('A directive with this name already exists.'),
        findsOneWidget,
      );

      // Reject invalid custom directive name
      await tester.tap(
        find.byKey(const ValueKey<String>('add_custom_directive_chip')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom_directive_input')),
        'bad name!',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Use a new lowercase directive name.'), findsOneWidget);
    },
  );

  testWidgets(
    'outline reorders sections via keyboard buttons and displays original extension',
    (tester) async {
      const songText =
          '{start_of_verse}\nOne\n{end_of_verse}\n\n{start_of_chorus}\nTwo\n{end_of_chorus}';
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: ChordProEditorRequest(
              rootDirectory: 'test-library',
              song: Song(
                file: const SongFile(path: 'test-library/demo.cho'),
                text: songText,
                isMalformed: false,
              ),
            ),
            store: _RecordingSongStore(),
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('chordpro_filename')),
            )
            .decoration!
            .suffixText,
        '.cho',
      );

      await tester.tap(find.byKey(const ValueKey<String>('section_down_0')));
      await tester.pump();
      final updated = tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chordpro_source')),
          )
          .controller!
          .text;
      expect(updated.startsWith('{start_of_chorus}'), isTrue);
    },
  );

  testWidgets(
    'supports drag-and-drop, Ctrl+S shortcut, and localized save errors',
    (tester) async {
      final store = _RecordingSongStore()
        ..errorToThrow = const ChordProSaveException(
          ChordProSaveErrorCode.writePermissionDenied,
        );
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrapEditor(
          ChordProEditorView(
            request: const ChordProEditorRequest(rootDirectory: 'test-library'),
            store: store,
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_source')),
        'Hello world',
      );
      await tester.pump();

      // Drag chord chip onto editor
      final chordFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('chordpro_chords')),
        matching: find.text('G'),
      );
      final editorFinder = find.byKey(
        const ValueKey<String>('chordpro_source'),
      );
      final gesture = await tester.startGesture(tester.getCenter(chordFinder));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(editorFinder));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(
        tester.widget<TextField>(editorFinder).controller!.text,
        contains('[G]'),
      );

      // Trigger Ctrl+S -> shows localized write-permission error
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Write permission is required. Choose the song library folder again.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('palettes wrap on wide screens and scroll on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrapEditor(
        ChordProEditorView(
          request: const ChordProEditorRequest(rootDirectory: 'test-library'),
          store: _RecordingSongStore(),
          preferencesRepository:
              SharedPreferencesChordProPreferencesRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chordpro_directives')),
        matching: find.byType(Wrap),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chordpro_chords')),
        matching: find.byType(Wrap),
      ),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          key: const ValueKey<String>('narrow_app'),
          home: ChordProEditorView(
            request: const ChordProEditorRequest(rootDirectory: 'test-library'),
            store: _RecordingSongStore(),
            preferencesRepository:
                SharedPreferencesChordProPreferencesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chordpro_directives')),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'handles narrow outline jumps, deleting global directives, discard/save on close, and save error codes',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'chordpro_custom_directives': ['aaa_tag'],
        'chordpro_editor_hint_dismissed': true,
      });
      await tester.binding.setSurfaceSize(const Size(480, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = _RecordingSongStore();
      final prefsRepo = SharedPreferencesChordProPreferencesRepository();
      SongFile? returnedFile;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedFile = await Navigator.of(context).push<SongFile>(
                    MaterialPageRoute<SongFile>(
                      builder: (_) => ChordProEditorView(
                        request: const ChordProEditorRequest(
                          rootDirectory: 'test-library',
                        ),
                        store: store,
                        preferencesRepository: prefsRepo,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Remove global custom directive (sorted first alphabetically)
      await tester.tap(find.byTooltip('Remove custom directive'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('chordpro_custom_directives'), isEmpty);

      // Enter text with section and directive, switch to Outline tab, tap directive -> switches back to Editor tab
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_source')),
        '{title: Jump}\n{start_of_verse}\n[C]Hello\n{end_of_verse}',
      );
      await tester.pump();
      await tester.tap(find.text('Outline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verse'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('chordpro_source')),
        findsOneWidget,
      );

      await tester.tap(find.text('Outline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('title'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('chordpro_source')),
        findsOneWidget,
      );

      // Verify localized save errors
      for (final entry in <(Object, String)>[
        (
          const ChordProSaveException(ChordProSaveErrorCode.invalidFilename),
          'Enter a valid song filename.',
        ),
        (
          const ChordProSaveException(ChordProSaveErrorCode.outsideLibrary),
          'Song must be inside the selected library.',
        ),
        (
          const ChordProSaveException(ChordProSaveErrorCode.folderUnavailable),
          'The destination song folder is unavailable.',
        ),
        (
          const ChordProSaveException(
            ChordProSaveErrorCode.writeFailed,
            detail: 'disk full',
          ),
          'Unable to save song: disk full',
        ),
        (StateError('boom'), 'Unable to save song: Bad state: boom'),
      ]) {
        store.errorToThrow = entry.$1;
        await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
        await tester.pumpAndSettle();
        expect(find.text(entry.$2), findsOneWidget);
      }

      // Close via Discard
      store.errorToThrow = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(returnedFile, isNull);

      // Re-open, edit, and close via Save in unsaved-changes dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_filename')),
        'SavedOnClose',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('chordpro_source')),
        '[G]Goodbye',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Save'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(returnedFile?.path, 'test-library/SavedOnClose.chopro');
    },
  );
}

class _RecordingSongStore implements ChordProSongStore {
  String? savedText;
  String? savedFileName;
  SongFile? savedSourceFile;
  bool? savedOverwrite;
  bool failFirstWithExists = false;
  Object? errorToThrow;

  @override
  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
    bool overwrite = false,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (failFirstWithExists && !overwrite) {
      throw ChordProSaveException(
        ChordProSaveErrorCode.fileAlreadyExists,
        targetPath: '$fileName.chopro',
      );
    }
    savedText = text;
    savedFileName = fileName;
    savedSourceFile = sourceFile;
    savedOverwrite = overwrite;
    return SongFile(path: '$rootDirectory/$fileName.chopro');
  }
}
