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
    expect(
      ChordProDocument('a\r\nb\nc').lines,
      ['a', 'b', 'c'],
    );
    expect(
      ChordProDocument('a\r\nb\nc').withLineEnding('\r\n'),
      'a\r\nb\r\nc',
    );
    expect(ChordProDocument('a\r\nb\nc').offsetForLine(0), 0);
    expect(ChordProDocument('a\r\nb\nc').offsetForLine(1), 3);
    expect(ChordProDocument('a\r\nb\nc').offsetForLine(2), 5);
    expect(ChordProDocument('a\r\nb\nc').offsetForLine(99), 6);
  });

  test('indexes repeated, whitespace-separated, and negated-selector directives', () {
    final entries = ChordProDocument(
      '{Title First}\n{title: Second}\n{define-guitar!: Am frets x 0 2 2 1 0}\n# comment',
    ).directives;
    expect(entries.map((entry) => entry.value), [
      'First',
      'Second',
      'Am frets x 0 2 2 1 0',
    ]);
    expect(entries.first.normalizedName, 'title');
  });

  test('supports all Release 3 directives and builds valid templates', () {
    expect(ChordProDocument.supportedDirectives, containsAll([
      'album',
      'arranger',
      'artist',
      'capo',
      'chord',
      'chordfont',
      'chordsize',
      'chordcolour',
      'chorus',
      'composer',
      'define',
      'diagrams',
      'duration',
      'end_of_bridge',
      'end_of_chorus',
      'end_of_verse',
      'key',
      'lyricist',
      'scroll_speed',
      'start_of_bridge',
      'start_of_chorus',
      'start_of_verse',
      'subtitle',
      'tempo',
      'time',
      'title',
      'titlefont',
      'titlesize',
      'titlecolour',
      'transpose',
      'year',
    ]));

    expect(
      ChordProDocument.directiveTemplate('start_of_verse').text,
      '{start_of_verse}\n\n{end_of_verse}',
    );
    expect(
      ChordProDocument.directiveTemplate('start_of_chorus').text,
      '{start_of_chorus}\n\n{end_of_chorus}',
    );
    expect(
      ChordProDocument.directiveTemplate('start_of_bridge').text,
      '{start_of_bridge}\n\n{end_of_bridge}',
    );
    expect(
      ChordProDocument.directiveTemplate('end_of_verse').text,
      '{end_of_verse}',
    );
    expect(ChordProDocument.directiveTemplate('chorus').text, '{chorus}');
    expect(
      ChordProDocument.directiveTemplate('scroll_speed').text,
      '{scroll_speed: 5}',
    );
    expect(
      ChordProDocument.directiveTemplate('define').text,
      contains('{define:'),
    );
    expect(
      ChordProDocument.directiveTemplate('chord').text,
      contains('{chord:'),
    );
    expect(
      ChordProDocument.directiveTemplate('diagrams').text,
      '{diagrams: top}',
    );
    expect(ChordProDocument.directiveTemplate('title').text, '{title: }');
  });

  test('normalizes and validates custom directive names', () {
    expect(ChordProDocument.normalizeDirectiveName('  My_Tag  '), 'my_tag');
    expect(ChordProDocument.isValidCustomDirectiveName('my_tag'), isTrue);
    expect(ChordProDocument.isValidCustomDirectiveName('my tag'), isFalse);
    expect(ChordProDocument.isValidCustomDirectiveName('1bad'), isFalse);
    expect(ChordProDocument.isBuiltInDirective('Title'), isTrue);
    expect(ChordProDocument.isBuiltInDirective('sov'), isTrue);
    expect(ChordProDocument.isBuiltInDirective('my_tag'), isFalse);
  });

  test('reads custom scroll speed across case and meta forms and defaults to five', () {
    expect(ChordProDocument('lyrics').scrollSpeed, 5);
    expect(ChordProDocument('{scroll_speed: 12}').scrollSpeed, 12);
    expect(ChordProDocument('{SCROLL_SPEED: 8}').scrollSpeed, 8);
    expect(ChordProDocument('{x_scroll_speed: 9}').scrollSpeed, 9);
    expect(ChordProDocument('{meta: scroll_speed 14}').scrollSpeed, 14);
    expect(ChordProDocument('{scroll_speed: 200}').scrollSpeed, 5);
  });

  test('extracts unique used chords ignoring comments and directives', () {
    final doc = ChordProDocument(
      '# [Em]ignored\n{title: [F]Ignored}\n[G]Hello [C]world [G]again',
    );
    expect(doc.usedChords, ['G', 'C']);
  });

  test('converts aligned, trailing, separate-line, and extended chords conservatively', () {
    const source = 'C     G\r\nHello world\r\nMaybe a verse\r\n';
    expect(
      ChordProDocument.convert(source).text,
      '[C]Hello [G]world\r\nMaybe a verse\r\n',
    );

    expect(
      ChordProDocument.convert('C   G   Am   F\n\nC7sus4   Cm7b5').text,
      '[C] [G] [Am] [F]\n\n[C7sus4] [Cm7b5]',
    );

    expect(
      ChordProDocument.convert('C     G     Am\nHello world').text,
      '[C]Hello [G]world [Am]',
    );

    expect(
      ChordProDocument.convert('[Chorus]\nG7#9   Cmin7\nSing along').text,
      '{start_of_chorus: Chorus}\n[G7#9]Sing al[Cmin7]ong\n{end_of_chorus}',
    );

    expect(
      ChordProDocument.convert('Verse 1:\nC  G\nLine one\nBridge:\nAm  F\nLine two').text,
      '{start_of_verse: Verse 1}\n[C]Lin[G]e one\n{end_of_verse}\n{start_of_bridge: Bridge}\n[Am]Line[F] two\n{end_of_bridge}',
    );
  });

  test('converts clear inline chords without corrupting English prose or comments', () {
    expect(
      ChordProDocument.convert('C Hello G world').text,
      '[C]Hello [G]world',
    );
    expect(
      ChordProDocument.convert('A beautiful day').text,
      'A beautiful day',
    );
    expect(
      ChordProDocument.convert('A boy and A girl').text,
      'A boy and A girl',
    );
    expect(
      ChordProDocument.convert('Am I a fool, A lonely soul').text,
      'Am I a fool, A lonely soul',
    );
    expect(
      ChordProDocument.convert('A song in C major').text,
      'A song in C major',
    );
    expect(
      ChordProDocument.convert('# A note in Am').text,
      '# A note in Am',
    );
  });

  test('outlines short-form, case-insensitive, single-quoted, and unclosed sections', () {
    final sections = ChordProDocument(
      "{SOV: label='Verse 1' flush='left'}\n[C]Hello\n{EOV}\n{start_of_chorus}\n[G]Open chorus",
    ).sections;
    expect(sections, hasLength(2));
    expect(sections.first.label, 'Verse 1');
    expect(sections.first.isClosed, isTrue);
    expect(sections.last.label, 'Chorus');
    expect(sections.last.isClosed, isFalse);
  });

  test('moves sections cleanly without stranding blank separator lines', () {
    const source =
        '{start_of_verse}\nOne\n{end_of_verse}\n\n{start_of_chorus}\nTwo\n{end_of_chorus}';
    final moved = ChordProDocument(source).moveSection(0, 1);
    expect(
      moved.text,
      '{start_of_chorus}\nTwo\n{end_of_chorus}\n\n{start_of_verse}\nOne\n{end_of_verse}',
    );
    expect(moved.moveSection(0, 0).text, moved.text);
    expect(moved.moveSection(-1, 1).text, moved.text);
  });
}
