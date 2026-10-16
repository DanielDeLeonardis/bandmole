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
