import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders plain lyrics without the rich layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SongTextRenderer(
            song: SongFormattingResult(
              rawText: 'Plain lyrics',
              hasRichFormatting: false,
              sections: [],
            ),
            fontSize: 18,
          ),
        ),
      ),
    );

    expect(find.text('Plain lyrics'), findsOneWidget);
    expect(find.text('Verse'), findsNothing);
  });

  testWidgets('renders rich metadata, blank lines, chords, and three columns', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1700, 1000));

    final song = SongFormattingResult(
      rawText: '',
      hasRichFormatting: true,
      title: 'Title',
      subtitle: 'Subtitle',
      artist: 'Artist',
      key: 'G',
      capo: 2,
      sections: const [
        SongSection(
          type: SongSectionType.verse,
          label: 'Verse 1',
          lines: [
            SongLine(segments: []),
            SongLine(segments: [SongLineSegment(lyric: 'Plain line')]),
            SongLine(
              segments: [
                SongLineSegment(lyric: 'before '),
                SongLineSegment(chord: 'G', lyric: 'chord'),
                SongLineSegment(chord: '', lyric: 'tail'),
              ],
            ),
          ],
        ),
        SongSection(
          type: SongSectionType.chorus,
          lines: [SongLine(segments: [SongLineSegment(lyric: 'No label')])],
        ),
        SongSection(
          type: SongSectionType.bridge,
          label: 'Bridge',
          lines: [SongLine(segments: [SongLineSegment(lyric: 'Bridge line')])],
        ),
        SongSection(
          type: SongSectionType.outro,
          label: 'Outro',
          lines: [SongLine(segments: [SongLineSegment(lyric: 'Outro line')])],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: SongTextRenderer(song: song, fontSize: 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.text('Key: G'), findsOneWidget);
    expect(find.text('Capo: 2'), findsOneWidget);
    expect(find.text('Artist: Artist'), findsOneWidget);
    expect(find.text('Verse 1'), findsOneWidget);
    expect(find.text('Plain line'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('Bridge line'), findsOneWidget);
    expect(find.text('Outro line'), findsOneWidget);
    expect(find.byType(Wrap), findsWidgets);
  });

  testWidgets('wide layout falls back for zero or one section', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    Widget render(List<SongSection> sections) => MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: SongTextRenderer(
            song: SongFormattingResult(
              rawText: '',
              hasRichFormatting: true,
              sections: sections,
            ),
            fontSize: 18,
          ),
        ),
      ),
    );

    await tester.pumpWidget(render(const []));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      render(const [
        SongSection(
          type: SongSectionType.freeform,
          lines: [SongLine(segments: [SongLineSegment(lyric: 'One section')])],
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('One section'), findsOneWidget);
  });
}