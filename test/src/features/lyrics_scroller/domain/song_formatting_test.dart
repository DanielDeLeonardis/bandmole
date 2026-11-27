import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SongFormatter preserves plain lyrics without rich formatting', () {
    const rawText = 'Sample song lyrics text line 1\nLine 2';

    final result = SongFormatter.parse(rawText);

    expect(result.hasRichFormatting, isFalse);
    expect(result.rawText, rawText);
    expect(result.sections, hasLength(1));
    expect(result.sections.single.lines, hasLength(2));
    expect(result.sections.single.lines.first.plainText, 'Sample song lyrics text line 1');
  });

  test('SongFormatter parses ChordPro metadata, sections, and chords', () {
    const rawText = '''
{title: Amazing Grace}
{key: G}
{start_of_verse}
[G]Amazing [C]grace
how [D]sweet the [G]sound

{start_of_chorus}
[D]Praise [G]God
''';

    final result = SongFormatter.parse(rawText);

    expect(result.hasRichFormatting, isTrue);
    expect(result.title, 'Amazing Grace');
    expect(result.key, 'G');
    expect(result.sections, hasLength(2));

    final verse = result.sections.first;
    expect(verse.label, 'Verse');
    expect(verse.lines, hasLength(2));
    expect(verse.lines.first.hasChords, isTrue);
    expect(verse.lines.first.segments.first.chord, 'G');
    expect(verse.lines.first.segments.first.lyric, 'Amazing ');
    expect(verse.lines.first.segments[1].chord, 'C');
    expect(verse.lines.first.segments[1].lyric, 'grace');

    final chorus = result.sections.last;
    expect(chorus.label, 'Chorus');
    expect(chorus.lines.single.segments.first.chord, 'D');
  });

  test('SongFormatter does not render define directives as lyrics', () {
    final result = SongFormatter.parse(
      '{define: Am7 frets 0 0 2 0 1 0}\n{define: D7 base-fret 3 frets x 3 2 3 1 x}\n[C]Hello',
    );
    expect(result.hasRichFormatting, isTrue);
    expect(result.chordDefinitions, hasLength(2));
    expect(result.chordDefinitions.first.name, 'Am7');
    expect(result.chordDefinitions.first.frets, ['0', '0', '2', '0', '1', '0']);
    expect(result.chordDefinitions.last.baseFret, 3);
    expect(result.sections.single.lines.single.plainText, 'Hello');
  });

  test('SongFormatter parses selector-style define directives', () {
    final result = SongFormatter.parse(
      '{define-guitar: Am7 frets 0 0 2 0 1 0 fingers 0 0 2 0 1 0}\n[C]Hello',
    );

    expect(result.chordDefinitions, hasLength(1));
    expect(result.chordDefinitions.single.name, 'Am7');
    expect(result.chordDefinitions.single.fingers, ['0', '0', '2', '0', '1', '0']);
  });

  test('SongFormatter parses bracketed slash chords with hyphenated frets', () {
    final result = SongFormatter.parse(
      '{define: [F#/G#] base-fret 1 frets  4-x-4-3-2-2}\n'
      '{define: C#/G# base-fret 1 frets 4-x-6-6-6-4}\n'
      '{define: D#m/G# base-fret 1 frets 4-x-4-3-4-x}\n'
      '{define: G#m7 base-fret 1 frets 4-6-4-4-4-4}\n[C]Hello',
    );

    expect(result.chordDefinitions, hasLength(4));
    expect(result.chordDefinitions.first.name, 'F#/G#');
    expect(result.chordDefinitions.first.frets, ['4', 'x', '4', '3', '2', '2']);
    expect(result.chordDefinitions[1].name, 'C#/G#');
    expect(result.chordDefinitions[2].name, 'D#m/G#');
    expect(result.chordDefinitions.last.name, 'G#m7');
    expect(result.chordDefinitions.last.frets, ['4', '6', '4', '4', '4', '4']);
    expect(result.sections.single.lines.single.plainText, 'Hello');
  });

  test('SongFormatter copies chord diagrams from earlier definitions', () {
    final result = SongFormatter.parse(
      '{define: Am7 frets 0 0 2 0 1 0 fingers 0 0 2 0 1 0}\n{define: Am7sus4 copy Am7 frets 0 0 2 2 1 0}\n[C]Hello',
    );

    expect(result.chordDefinitions, hasLength(2));
    expect(result.chordDefinitions.last.name, 'Am7sus4');
    expect(result.chordDefinitions.last.frets, ['0', '0', '2', '2', '1', '0']);
    expect(result.chordDefinitions.last.fingers, ['0', '0', '2', '0', '1', '0']);
  });

  test('SongFormatter uses a labeled section in the preview', () {
    final result = SongFormatter.parse(
      '{sov: label="Verse 1"}\n[C]Hello\n{eov}',
    );
    expect(result.sections.single.label, 'Verse 1');
  });

  test('SongFormatter.transposeChord preserves suffixes and slash chords', () {
    expect(SongFormatter.transposeChord('Bbmaj7/F', 2), 'Cmaj7/G');
    expect(SongFormatter.transposeChord('Gm7', -2), 'Fm7');
    expect(SongFormatter.transposeChord('N.C.', 2), 'N.C.');
  });

  test('SongFormatter parses supported metadata, section aliases, and comments', () {
    const rawText = '''
{subtitle: Live version}
{artist: The Band}
{capo: 3}
{soc}
[C]Chorus
{eoc}
{sov}
Verse
{eov}
{start_of_bridge}
Bridge
{end_of_bridge}
{start_of_intro}
Intro
{end_of_intro}
{start_of_outro}
Outro
{end_of_outro}
{start_of_tab}
Tab
{end_of_tab}
{comment: Repeat the chorus}
''';

    final result = SongFormatter.parse(rawText);

    expect(result.subtitle, 'Live version');
    expect(result.artist, 'The Band');
    expect(result.capo, 3);
    expect(result.sections.map((section) => section.type), [
      SongSectionType.chorus,
      SongSectionType.verse,
      SongSectionType.bridge,
      SongSectionType.intro,
      SongSectionType.outro,
      SongSectionType.tag,
      SongSectionType.freeform,
    ]);
    expect(result.sections.last.lines.single.plainText, 'Repeat the chorus');
  });

  test('SongFormatter handles invalid capo and empty or malformed chord tokens', () {
    final invalidCapo = SongFormatter.parse('{capo:unknown}\nLyrics');
    expect(invalidCapo.capo, isNull);

    final empty = SongFormatter.parse('{title: No lyrics}');
    expect(empty.sections.single.type, SongSectionType.freeform);
    expect(empty.sections.single.lines, isEmpty);

    final malformedChord = SongFormatter.parse('[]plain [C]lyric[]tail');
    expect(
      malformedChord.sections.single.lines.single.plainText,
      '[]plain lyric[]tail',
    );
    final emptyChordTokens = SongFormatter.parse('[]plain');
    expect(emptyChordTokens.sections.single.lines.single.plainText, '[]plain');
    expect(
      SongFormatter.transposeChord('C/H', 2),
      'D',
    );
    expect(SongFormatter.transposeChord('Hmaj7', 2), 'Hmaj7');
  });

  test('SongFormatter supports all Release 3 metadata, styling, chorus recall, transpose, diagrams, and inline chords', () {
    const rawText = '''
# ChordPro comment
{t: Anthem}
{st: Acoustic}
{subtitle: Live}
{artist: Artist One}
{artist: Artist Two}
{composer: Comp A}
{composer: Comp B}
{lyricist: Lyr A}
{arranger: Arr A}
{album: Greatest Hits}
{year: 2026}
{duration: 3:45}
{tempo: 120}
{time: 4/4}
{key: G}
{transpose: 2}
{diagrams: bottom}
{titlefont: Serif}
{titlesize: 32}
{titlecolour: #ff0000}
{chordfont: Courier}
{chordsize: 110%}
{chordcolour: blue}
{define: Am base-fret 1 frets -1 0 2 2 1 0}
{define: Ckeys keys 0 4 7}
{start_of_verse: label='Verse 1'}
[G]Line one

[C]Line two after blank
{end_of_verse}
{soc}
[D]Chorus line
{eoc}
{chorus: Chorus Again}
{chord: Am}
{c: Plain note}
{ci: Italic note}
{cb: Boxed note}
[C][G][Am]
''';

    final result = SongFormatter.parse(rawText);

    expect(result.title, 'Anthem');
    expect(result.subtitles, ['Acoustic', 'Live']);
    expect(result.artists, ['Artist One', 'Artist Two']);
    expect(result.composers, ['Comp A', 'Comp B']);
    expect(result.lyricists, ['Lyr A']);
    expect(result.arrangers, ['Arr A']);
    expect(result.album, 'Greatest Hits');
    expect(result.year, '2026');
    expect(result.duration, '3:45');
    expect(result.tempo, '120');
    expect(result.time, '4/4');
    expect(result.key, 'A');
    expect(result.diagramsPlacement, SongDiagramsPlacement.bottom);
    expect(result.titleFont, 'Serif');
    expect(result.titleSize?.resolve(28), 32);
    expect(result.titleColourArgb, 0xFFFF0000);
    expect(result.chordFont, 'Courier');
    expect(result.chordSize?.resolve(20), 22);
    expect(result.chordColourArgb, 0xFF1565C0);

    expect(result.chordDefinitions.first.frets, ['-1', '0', '2', '2', '1', '0']);
    expect(result.chordDefinitions.last.keys, [0, 4, 7]);

    final verse = result.sections.first;
    expect(verse.type, SongSectionType.verse);
    expect(verse.label, 'Verse 1');
    expect(verse.lines, hasLength(3));
    expect(verse.lines.first.segments.first.chord, 'A');

    final recalledChorus = result.sections[2];
    expect(recalledChorus.type, SongSectionType.chorus);
    expect(recalledChorus.label, 'Chorus Again');
    expect(recalledChorus.lines.single.plainText, 'Chorus line');

    final tail = result.sections.last;
    expect(tail.lines[0].inlineChord?.name, 'Am');
    expect(tail.lines[1].style, SongLineStyle.comment);
    expect(tail.lines[2].style, SongLineStyle.commentItalic);
    expect(tail.lines[3].style, SongLineStyle.commentBox);
    expect(tail.lines[4].isBlank, isFalse);
    expect(tail.lines[4].hasChords, isTrue);
  });

  test('SongFormatter strips hash comments in chord-only ChordPro files and handles meta/diagrams off', () {
    final result = SongFormatter.parse('# hidden comment\n[C]Hello');
    expect(result.sections.single.lines, hasLength(1));
    expect(result.sections.single.lines.single.plainText, 'Hello');

    final metaResult = SongFormatter.parse(
      '{meta: artist Meta Band}\n{diagrams: off}\n{chorus}\n{sog}\n| C | G |\n{eog}',
    );
    expect(metaResult.artist, 'Meta Band');
    expect(metaResult.diagramsPlacement, SongDiagramsPlacement.none);
    expect(metaResult.sections.first.type, SongSectionType.chorus);
    expect(metaResult.sections.last.label, 'Grid');
    expect(metaResult.sections.last.isDefaultLabel, isTrue);
  });

  test('SongFormatter interpolates %{meta}, transposes inline chords, and scopes mid-song chord styles', () {
    const rawText = '''
{title: Amazing Grace}
{artist: Traditional}
{key: G}
{transpose: 2}
{subtitle: Performed by %{artist} in %{key}}
{define: G frets 3 2 0 0 0 3}
{chord: G}
{c: Song: %{title}}
{chordcolour: red}
[G]Red chord line
{chordcolour}
[C]Reset chord line
''';

    final result = SongFormatter.parse(rawText);
    expect(result.subtitle, 'Performed by Traditional in A');
    final section = result.sections.single;
    expect(section.lines[0].inlineChord?.label, 'A');
    expect(section.lines[1].plainText, 'Song: Amazing Grace');
    expect(section.lines[2].chordColourArgb, 0xFFD32F2F);
    expect(section.lines[3].chordColourArgb, isNull);
  });
}
