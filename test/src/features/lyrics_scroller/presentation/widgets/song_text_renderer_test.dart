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

  testWidgets('renders defined chord diagrams in the preview header', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    final song = SongFormatter.parse(
      '{define: Am7 frets 0 0 2 0 1 0}\n[C]Hello',
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

    expect(
      find.byKey(const ValueKey<String>('chord-diagram-Am7')),
      findsOneWidget,
    );
    expect(find.text('Am7'), findsOneWidget);
  });

  testWidgets('renders the define directive chord diagrams from the preview header', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    final song = SongFormatter.parse(
      '{define: [F#/G#] base-fret 1 frets  4-x-4-3-2-2}\n'
      '{define: C#/G# base-fret 1 frets 4-x-6-6-6-4}\n'
      '{define: D#m/G# base-fret 1 frets 4-x-4-3-4-x}\n'
      '{define: G#m7 base-fret 1 frets 4-6-4-4-4-4}\n[C]Hello',
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

    expect(find.byKey(const ValueKey<String>('chord-diagram-F#/G#')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chord-diagram-C#/G#')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chord-diagram-D#m/G#')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chord-diagram-G#m7')), findsOneWidget);
    expect(find.text('F#/G#'), findsOneWidget);
    expect(find.text('G#m7'), findsOneWidget);
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

  testWidgets('single-column mode stays narrow on wide screens', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1700, 1000));

    final song = SongFormattingResult(
      rawText: '',
      hasRichFormatting: true,
      sections: const [
        SongSection(type: SongSectionType.verse, lines: [SongLine(segments: [SongLineSegment(lyric: 'One')])]),
        SongSection(type: SongSectionType.chorus, lines: [SongLine(segments: [SongLineSegment(lyric: 'Two')])]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: SongTextRenderer(
              song: song,
              fontSize: 18,
              allowMultiColumnLayout: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('song_text_renderer_narrow_layout')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('song_text_renderer_wide_layout')), findsNothing);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
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
