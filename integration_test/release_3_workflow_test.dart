import 'dart:io';

import 'package:bandmole/src/features/chordpro_editor/presentation/views/chordpro_editor_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Release 3 converts, saves, and reopens a desktop song', (
    tester,
  ) async {
    if (Platform.isAndroid || Platform.isIOS) return;
    SharedPreferences.setMockInitialValues({});
    final root = await Directory.systemTemp.createTemp('bandmole_editor_flow');
    addTearDown(() => root.delete(recursive: true));
    final original = File('${root.path}${Platform.pathSeparator}song.txt');
    await original.writeAsString('C     G\nHello world');
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          request: ChordProEditorRequest(
            rootDirectory: root.path,
            song: Song(
              file: SongFile(path: original.path),
              text: await original.readAsString(),
              isMalformed: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convert to ChordPro'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('chordpro_save')));
    await tester.pumpAndSettle();

    final converted = File('${root.path}${Platform.pathSeparator}song.chopro');
    expect(await original.readAsString(), 'C     G\nHello world');
    expect(await converted.readAsString(), '[C]Hello [G]world');

    await tester.pumpWidget(
      MaterialApp(
        home: ChordProEditorView(
          key: const ValueKey<String>('reopened_editor'),
          request: ChordProEditorRequest(
            rootDirectory: root.path,
            song: Song(
              file: SongFile(path: converted.path),
              text: await converted.readAsString(),
              isMalformed: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('chordpro_source')),
          )
          .controller!
          .text,
      '[C]Hello [G]world',
    );
  });
}
