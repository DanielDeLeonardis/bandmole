import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/set_editor_dialog.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/song_relink_dialog.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('set editor validates required and duplicate titles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const SetEditorDialog(
                  otherSetTitles: ['Encore'],
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Set title is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), ' encore ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('A set with this title already exists in this gig.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Finale');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('set editor uses rename mode for an existing set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const SetEditorDialog(
                  existingSet: SongSet(id: 'set-1', title: 'Opening'),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Set'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
  });

  testWidgets('relink dialog rejects empty path and selects a normalized item', (
    tester,
  ) async {
    const song = GigSong(id: 'song-1', relativePath: 'missing/song.txt');
    const replacement = SongFile(path: r'C:\Songs\replacement.cho');
    String? selectedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedPath = await showDialog<String>(
                  context: context,
                  builder: (_) => const SongRelinkDialog(
                    song: song,
                    availableSongs: [replacement],
                    rootDirectory: r'C:\Songs',
                  ),
                );
              },
              child: const Text('Open relink'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open relink'));
    await tester.pumpAndSettle();
    expect(find.text('Current broken link:\nmissing/song.txt'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(selectedPath, 'replacement.cho');
  });

  testWidgets('relink dialog supports manual path when library is empty', (
    tester,
  ) async {
    const song = GigSong(id: 'song-1', relativePath: 'missing.txt');
    String? selectedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedPath = await showDialog<String>(
                  context: context,
                  builder: (_) => const SongRelinkDialog(song: song),
                );
              },
              child: const Text('Open relink'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open relink'));
    await tester.pumpAndSettle();
    expect(find.text('Or select from current library:'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'new/location.txt');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(selectedPath, 'new/location.txt');
  });
}