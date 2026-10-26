import 'package:bandmole/src/features/chordpro_editor/data/chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/views/chordpro_editor_view.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('creates a song and previews ChordPro markup', (tester) async {
    final store = _RecordingSongStore();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          request: const ChordProEditorRequest(rootDirectory: 'test-library'),
          store: store,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('chordpro_filename')),
      'New Song',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('chordpro_source')),
      '{title: New Song}\n[C]Hello',
    );
    await tester.pump();
    final preview = tester.widget<SongTextRenderer>(
      find.byType(SongTextRenderer),
    );
    expect(preview.song.title, 'New Song');
    expect(preview.song.sections.single.lines.single.hasChords, isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
    await tester.pump();
    expect(store.savedText, '{title: New Song}\n[C]Hello');
    expect(store.savedFileName, 'New Song');
    expect(store.savedSourceFile, isNull);
  });

  testWidgets('plain-text conversion is explicit and cancel keeps edits', (
    tester,
  ) async {
    final store = _RecordingSongStore();
    final source = SongFile(path: 'test-library/song.txt');
    const originalText = 'C     G\nHello world';
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          request: ChordProEditorRequest(
            rootDirectory: 'test-library',
            song: Song(
              file: source,
              text: originalText,
              isMalformed: false,
            ),
          ),
          store: store,
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey<String>('chordpro_save')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Convert to ChordPro'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('chordpro_source')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
    await tester.pump();
    expect(store.savedText, '[C]Hello [G]world');
    expect(store.savedSourceFile, same(source));
  });

  testWidgets('directive palette wraps on wide screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          request: const ChordProEditorRequest(rootDirectory: 'test-library'),
          store: _RecordingSongStore(),
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
  });

  testWidgets('directive palette scrolls on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          request: const ChordProEditorRequest(rootDirectory: 'test-library'),
          store: _RecordingSongStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('chordpro_directives')),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
    );
  });

}


class _RecordingSongStore extends ChordProSongStore {
  String? savedText;
  String? savedFileName;
  SongFile? savedSourceFile;

  @override
  Future<SongFile> save({
    required String rootDirectory,
    required String fileName,
    required String text,
    SongFile? sourceFile,
  }) async {
    savedText = text;
    savedFileName = fileName;
    savedSourceFile = sourceFile;
    return SongFile(path: '$rootDirectory/$fileName.chopro');
  }

}


