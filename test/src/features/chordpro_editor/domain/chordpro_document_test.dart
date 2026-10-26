import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves unknown directives, comments, whitespace and CRLF', () {
    const source = '# note\r\n{unknown: value}\r\n  [C]lyric  \r\n';
    final document = ChordProDocument(source);
    expect(document.text, source);
    expect(document.directives.single.name, 'unknown');
    expect(
      document.insert(source.length, '{title: Song}').text,
      '$source{title: Song}',
    );
    expect(document.lineEnding, '\r\n');
  });

  test('indexes repeated and whitespace-separated directives', () {
    final entries = ChordProDocument(
      '{title First}\n{title: Second}\n# comment',
    ).directives;
    expect(entries.map((entry) => entry.value), ['First', 'Second']);
  });
  test('supports define directives in the palette and outline', () {
    expect(ChordProDocument.supportedDirectives, contains('define'));
    expect(ChordProDocument.supportedDirectives, contains('end_of_bridge'));
    expect(ChordProDocument.supportedDirectives, contains('end_of_chorus'));
    expect(ChordProDocument.supportedDirectives, contains('end_of_verse'));
    expect(
      ChordProDocument('{define: Am7 frets 0 0 2 0 1 0}').directives.single.name,
      'define',
    );
  });
  test('reads custom scroll speed and defaults to five', () {
    expect(ChordProDocument('lyrics').scrollSpeed, 5);
    expect(ChordProDocument('{scroll_speed: 12}').scrollSpeed, 12);
    expect(ChordProDocument('{scroll_speed: 200}').scrollSpeed, 5);
  });

  test('converts only confidently aligned chord lines', () {
    const source = 'C     G\r\nHello world\r\nMaybe a verse\r\n';
    final result = ChordProDocument.convert(source);
    expect(result.text, '[C]Hello [G]world\r\nMaybe a verse\r\n');
  });

  test(
    'converts clear inline chords but leaves ambiguous lyrics unchanged',
    () {
      expect(
        ChordProDocument.convert('C Hello G world').text,
        '[C]Hello [G]world',
      );
      expect(
        ChordProDocument.convert('A beautiful day').text,
        'A beautiful day',
      );
    },
  );
  test('outlines short-form section directives and labels', () {
    final sections = ChordProDocument('{sov: label="Verse 1"}\n[C]Hello\n{eov}')
        .sections;
    expect(sections.single.label, 'Verse 1');
  });
  test('moves closed sections without rewriting their contents', () {
    const source =
        '{start_of_verse}\nOne\n{end_of_verse}\n{start_of_chorus}\nTwo\n{end_of_chorus}';
    final moved = ChordProDocument(source).moveSection(0, 1);
    expect(moved.text.startsWith('{start_of_chorus}'), isTrue);
    expect(moved.text, contains('{start_of_verse}\nOne\n{end_of_verse}'));
  });
}

