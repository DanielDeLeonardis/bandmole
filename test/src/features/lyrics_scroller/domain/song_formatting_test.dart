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
}
