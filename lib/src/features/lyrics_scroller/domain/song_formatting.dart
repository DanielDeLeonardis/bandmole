enum SongSectionType { freeform, verse, chorus, bridge, intro, outro, tag }

class SongFormattingResult {
  const SongFormattingResult({
    required this.rawText,
    required this.hasRichFormatting,
    required this.sections,
    this.title,
    this.subtitle,
    this.artist,
    this.key,
    this.capo,
  });

  final String rawText;
  final bool hasRichFormatting;
  final String? title;
  final String? subtitle;
  final String? artist;
  final String? key;
  final int? capo;
  final List<SongSection> sections;
}

class SongSection {
  const SongSection({required this.type, required this.lines, this.label});

  final SongSectionType type;
  final String? label;
  final List<SongLine> lines;
}

class SongLine {
  const SongLine({required this.segments});

  final List<SongLineSegment> segments;

  bool get hasChords => segments.any(
    (segment) => segment.chord != null && segment.chord!.isNotEmpty,
  );

  bool get isBlank =>
      segments.isEmpty || segments.every((segment) => segment.lyric.isEmpty);

  String get plainText => segments.map((segment) => segment.lyric).join();
}

class SongLineSegment {
  const SongLineSegment({required this.lyric, this.chord});

  final String? chord;
  final String lyric;
}

class SongFormatter {
  static const List<String> _sharpNotes = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const List<String> _flatNotes = <String>[
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static final RegExp _directiveRegExp = RegExp(
    r'^\{([^:}]+)(?::\s*([^}]*))?\}$',
  );
  static final RegExp _noteRegExp = RegExp(r'^([A-G])([#b]?)(.*)$');

  static SongFormattingResult parse(
    String rawText, {
    int transposeSemitones = 0,
  }) {
    final normalizedText = rawText.replaceAll('\r\n', '\n');
    final lines = normalizedText.split('\n');
    final sections = <SongSection>[];
    final builder = _SongSectionBuilder();
    String? title;
    String? subtitle;
    String? artist;
    String? key;
    int? capo;
    var hasRichFormatting = false;

    void flushSection() {
      final section = builder.build();
      if (section != null) {
        sections.add(section);
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        flushSection();
        builder.reset();
        continue;
      }

      final directiveMatch = _directiveRegExp.firstMatch(line.trim());
      if (directiveMatch != null) {
        final directive = directiveMatch.group(1)?.trim().toLowerCase();
        final value = directiveMatch.group(2)?.trim();

        switch (directive) {
          case 'title':
            title = value;
            hasRichFormatting = true;
            continue;
          case 'subtitle':
            subtitle = value;
            hasRichFormatting = true;
            continue;
          case 'artist':
            artist = value;
            hasRichFormatting = true;
            continue;
          case 'key':
            key = value;
            hasRichFormatting = true;
            continue;
          case 'capo':
            capo = int.tryParse(value ?? '');
            hasRichFormatting = true;
            continue;
          case 'soc':
          case 'start_of_chorus':
            flushSection();
            builder.reset(type: SongSectionType.chorus, label: 'Chorus');
            hasRichFormatting = true;
            continue;
          case 'eoc':
          case 'end_of_chorus':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'start_of_verse':
          case 'sov':
            flushSection();
            builder.reset(type: SongSectionType.verse, label: 'Verse');
            hasRichFormatting = true;
            continue;
          case 'end_of_verse':
          case 'eov':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'start_of_bridge':
            flushSection();
            builder.reset(type: SongSectionType.bridge, label: 'Bridge');
            hasRichFormatting = true;
            continue;
          case 'end_of_bridge':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'start_of_intro':
            flushSection();
            builder.reset(type: SongSectionType.intro, label: 'Intro');
            hasRichFormatting = true;
            continue;
          case 'end_of_intro':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'start_of_outro':
            flushSection();
            builder.reset(type: SongSectionType.outro, label: 'Outro');
            hasRichFormatting = true;
            continue;
          case 'end_of_outro':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'start_of_tab':
            flushSection();
            builder.reset(type: SongSectionType.tag, label: 'Tab');
            hasRichFormatting = true;
            continue;
          case 'end_of_tab':
            flushSection();
            builder.reset();
            hasRichFormatting = true;
            continue;
          case 'comment':
            builder.addLine(
              _SongFormatterLineParser.parsePlainText(value ?? '').line,
            );
            hasRichFormatting = true;
            continue;
        }
      }

      final parsedLine = _SongFormatterLineParser.parseLine(
        line,
        transposeSemitones: transposeSemitones,
      );
      if (parsedLine.hasChords || parsedLine.hasWrappedDirective) {
        hasRichFormatting = true;
      }
      builder.addLine(parsedLine.line);
    }

    flushSection();

    if (sections.isEmpty) {
      sections.add(
        SongSection(type: SongSectionType.freeform, lines: const []),
      );
    }

    return SongFormattingResult(
      rawText: normalizedText,
      hasRichFormatting: hasRichFormatting,
      title: title,
      subtitle: subtitle,
      artist: artist,
      key: key,
      capo: capo,
      sections: sections,
    );
  }

  static String transposeChord(String chord, int semitones) {
    if (semitones % 12 == 0) {
      return chord;
    }

    final trimmed = chord.trim();
    final slashIndex = trimmed.indexOf('/');
    final rootPart = slashIndex == -1
        ? trimmed
        : trimmed.substring(0, slashIndex);
    final bassPart = slashIndex == -1
        ? null
        : trimmed.substring(slashIndex + 1);

    final transposedRoot = _transposeChordRoot(rootPart, semitones);
    if (transposedRoot == null) {
      return chord;
    }

    final transposedBass = bassPart == null
        ? null
        : _transposeChordRoot(bassPart, semitones);
    final suffix = rootPart.substring(_rootLength(rootPart));

    if (bassPart == null || transposedBass == null) {
      return '$transposedRoot$suffix';
    }

    return '$transposedRoot$suffix/$transposedBass';
  }

  static String? _transposeChordRoot(String note, int semitones) {
    final parsed = _noteRegExp.firstMatch(note);
    if (parsed == null) {
      return null;
    }

    final base = '${parsed.group(1)!}${parsed.group(2) ?? ''}';
    final noteIndex = _noteIndex(base);
    if (noteIndex == null) {
      return null;
    }

    final preferFlats = base.contains('b');
    final transposedIndex = (noteIndex + semitones) % 12;
    final normalizedIndex = transposedIndex < 0
        ? transposedIndex + 12
        : transposedIndex;
    return preferFlats
        ? _flatNotes[normalizedIndex]
        : _sharpNotes[normalizedIndex];
  }

  static int _rootLength(String chord) {
    final parsed = _noteRegExp.firstMatch(chord);
    if (parsed == null) {
      return 0;
    }

    return '${parsed.group(1)!}${parsed.group(2) ?? ''}'.length;
  }

  static int? _noteIndex(String note) {
    final sharpIndex = _sharpNotes.indexOf(note);
    if (sharpIndex != -1) {
      return sharpIndex;
    }

    return _flatNotes.indexOf(note);
  }
}

class _SongSectionBuilder {
  _SongSectionBuilder() : _label = null, _type = SongSectionType.freeform;

  SongSectionType _type;
  String? _label;
  final List<SongLine> _lines = <SongLine>[];

  void reset({SongSectionType type = SongSectionType.freeform, String? label}) {
    _type = type;
    _label = label;
    _lines.clear();
  }

  void addLine(SongLine line) {
    _lines.add(line);
  }

  SongSection? build() {
    if (_lines.isEmpty) {
      return null;
    }

    return SongSection(
      type: _type,
      label: _label,
      lines: List<SongLine>.unmodifiable(_lines),
    );
  }
}

class _SongFormatterLineParser {
  static final RegExp _chordTokenRegExp = RegExp(r'\[([^\]]+)\]');

  static _ParsedLine parseLine(
    String rawLine, {
    required int transposeSemitones,
  }) {
    final matches = _chordTokenRegExp
        .allMatches(rawLine)
        .toList(growable: false);
    if (matches.isEmpty) {
      return parsePlainText(rawLine);
    }

    final segments = <SongLineSegment>[];
    var cursor = 0;

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final chord = match.group(1)?.trim();
      if (chord == null || chord.isEmpty) {
        continue;
      }

      final lyricEnd = index + 1 < matches.length
          ? matches[index + 1].start
          : rawLine.length;
      final leadingText = rawLine.substring(cursor, match.start);
      final lyricText = rawLine.substring(match.end, lyricEnd);

      if (segments.isEmpty && leadingText.isNotEmpty) {
        segments.add(SongLineSegment(lyric: leadingText));
      }

      segments.add(
        SongLineSegment(
          chord: SongFormatter.transposeChord(chord, transposeSemitones),
          lyric: lyricText,
        ),
      );

      cursor = lyricEnd;
    }

    if (segments.isEmpty) {
      return parsePlainText(rawLine);
    }

    if (cursor < rawLine.length) {
      final trailingText = rawLine.substring(cursor);
      if (trailingText.isNotEmpty) {
        final lastSegment = segments.removeLast();
        segments.add(
          SongLineSegment(
            chord: lastSegment.chord,
            lyric: '${lastSegment.lyric}$trailingText',
          ),
        );
      }
    }

    return _ParsedLine(
      line: SongLine(segments: List<SongLineSegment>.unmodifiable(segments)),
      hasChords: segments.any((segment) => segment.chord != null),
      hasWrappedDirective: false,
    );
  }

  static _ParsedLine parsePlainText(String rawLine) {
    return _ParsedLine(
      line: SongLine(
        segments: List<SongLineSegment>.unmodifiable(<SongLineSegment>[
          SongLineSegment(lyric: rawLine),
        ]),
      ),
      hasChords: false,
      hasWrappedDirective: false,
    );
  }
}

class _ParsedLine {
  const _ParsedLine({
    required this.line,
    required this.hasChords,
    required this.hasWrappedDirective,
  });

  final SongLine line;
  final bool hasChords;
  final bool hasWrappedDirective;
}
