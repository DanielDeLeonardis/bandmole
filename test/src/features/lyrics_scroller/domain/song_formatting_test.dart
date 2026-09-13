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
}
