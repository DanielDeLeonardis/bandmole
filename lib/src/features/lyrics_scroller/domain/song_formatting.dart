enum SongSectionType { freeform, verse, chorus, bridge, intro, outro, tag }

enum SongDiagramsPlacement { top, bottom, none }

enum SongLineStyle { normal, comment, commentItalic, commentBox }

class SongFontSizeSpec {
  const SongFontSizeSpec({required this.value, this.isPercent = false});

  final double value;
  final bool isPercent;

  double resolve(double baseSize) => isPercent
      ? (baseSize * value / 100.0).clamp(8.0, 96.0)
      : value.clamp(8.0, 96.0);
}

class SongFormattingResult {
  const SongFormattingResult({
    required this.rawText,
    required this.hasRichFormatting,
    required this.sections,
    this.title,
    this.subtitle,
    this.subtitles = const [],
    this.artist,
    this.artists = const [],
    this.composers = const [],
    this.lyricists = const [],
    this.arrangers = const [],
    this.album,
    this.year,
    this.duration,
    this.tempo,
    this.time,
    this.key,
    this.capo,
    this.chordDefinitions = const [],
    this.diagramsPlacement = SongDiagramsPlacement.top,
    this.titleFont,
    this.titleSize,
    this.titleColourArgb,
    this.chordFont,
    this.chordSize,
    this.chordColourArgb,
  });

  final String rawText;
  final bool hasRichFormatting;
  final String? title;
  final String? subtitle;
  final List<String> subtitles;
  final String? artist;
  final List<String> artists;
  final List<String> composers;
  final List<String> lyricists;
  final List<String> arrangers;
  final String? album;
  final String? year;
  final String? duration;
  final String? tempo;
  final String? time;
  final String? key;
  final int? capo;
  final List<SongSection> sections;
  final List<SongChordDefinition> chordDefinitions;
  final SongDiagramsPlacement diagramsPlacement;
  final String? titleFont;
  final SongFontSizeSpec? titleSize;
  final int? titleColourArgb;
  final String? chordFont;
  final SongFontSizeSpec? chordSize;
  final int? chordColourArgb;
}

class SongSection {
  const SongSection({
    required this.type,
    required this.lines,
    this.label,
    this.isDefaultLabel = false,
  });

  final SongSectionType type;
  final String? label;
  final List<SongLine> lines;
  final bool isDefaultLabel;
}

class SongLine {
  const SongLine({
    required this.segments,
    this.style = SongLineStyle.normal,
    this.inlineChord,
    this.chordFont,
    this.chordSize,
    this.chordColourArgb,
  });

  final List<SongLineSegment> segments;
  final SongLineStyle style;
  final SongChordDefinition? inlineChord;
  final String? chordFont;
  final SongFontSizeSpec? chordSize;
  final int? chordColourArgb;

  bool get hasChords => segments.any(
    (segment) => segment.chord != null && segment.chord!.isNotEmpty,
  );

  bool get isBlank =>
      !hasChords &&
      inlineChord == null &&
      (segments.isEmpty || segments.every((segment) => segment.lyric.isEmpty));

  String get plainText => segments.map((segment) => segment.lyric).join();
}

class SongLineSegment {
  const SongLineSegment({required this.lyric, this.chord});

  final String? chord;
  final String lyric;
}

class SongChordDefinition {
  const SongChordDefinition({
    required this.name,
    required this.baseFret,
    required this.frets,
    required this.diagramEnabled,
    this.displayName,
    this.fingers = const [],
    this.keys = const [],
  });

  final String name;
  final String? displayName;
  final int baseFret;
  final List<String> frets;
  final List<String> fingers;
  final List<int> keys;
  final bool diagramEnabled;

  String get label {
    final display = displayName?.trim();
    return display == null || display.isEmpty ? name : display;
  }

  bool get hasDiagram =>
      diagramEnabled && (frets.isNotEmpty || keys.isNotEmpty);
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

  static const Map<String, int> _namedColours = <String, int>{
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'red': 0xFFD32F2F,
    'green': 0xFF2E7D32,
    'blue': 0xFF1565C0,
    'yellow': 0xFFF9A825,
    'orange': 0xFFEF6C00,
    'purple': 0xFF6A1B9A,
    'magenta': 0xFFC2185B,
    'cyan': 0xFF00838F,
    'teal': 0xFF00695C,
    'navy': 0xFF1A237E,
    'maroon': 0xFF880E4F,
    'gold': 0xFFFFB300,
    'gray': 0xFF757575,
    'grey': 0xFF757575,
  };

  static final RegExp _directiveRegExp = RegExp(
    r'^\{([^:}\s]+)(?:(?::\s*|\s+)(.*))?\}$',
  );
  static final RegExp _chordTokenQuickRegExp = RegExp(r'\[[^\]]+\]');
  static final RegExp _noteRegExp = RegExp(r'^([A-G])([#b]?)(.*)$');
  static final RegExp _defineTokenRegExp = RegExp("\"[^\"]*\"|'[^']*'|\\S+");
  static final RegExp _labelAttributeRegExp = RegExp(
    "label\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|(\\S+))",
    caseSensitive: false,
  );
  static final RegExp _signedIntRegExp = RegExp(r'^-?\d+$');
  static const Set<String> _defineKeywords = <String>{
    'base-fret',
    'base_fret',
    'frets',
    'fingers',
    'keys',
    'diagram',
    'display',
    'copy',
    'copyall',
    'format',
  };

  static SongFormattingResult parse(
    String rawText, {
    int transposeSemitones = 0,
  }) {
    final normalizedText = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final lines = normalizedText.split('\n');
    final hasChordProMarkers = lines.any(
      (line) =>
          _directiveRegExp.hasMatch(line.trim()) ||
          _chordTokenQuickRegExp.hasMatch(line),
    );

    final sections = <SongSection>[];
    final builder = _SongSectionBuilder();
    var insideExplicitSection = false;
    SongSection? lastChorus;

    String? title;
    final subtitles = <String>[];
    final artists = <String>[];
    final composers = <String>[];
    final lyricists = <String>[];
    final arrangers = <String>[];
    String? album;
    String? year;
    String? duration;
    String? tempo;
    String? time;
    String? rawKey;
    int? capo;
    var directiveTranspose = 0;
    var keyDirectiveTranspose = 0;
    var diagramsPlacement = SongDiagramsPlacement.top;
    String? titleFont;
    SongFontSizeSpec? titleSize;
    int? titleColourArgb;
    String? chordFont;
    SongFontSizeSpec? chordSize;
    int? chordColourArgb;

    var hasRichFormatting = false;
    final definedChords = <String, SongChordDefinition>{};
    final definedChordOrder = <String>[];

    void flushSection() {
      final section = builder.build();
      if (section != null) {
        sections.add(section);
        if (section.type == SongSectionType.chorus) {
          lastChorus = section;
        }
      }
    }

    String interpolateMeta(String input) {
      if (!input.contains('%{')) return input;
      final effectiveKey = rawKey == null
          ? null
          : (transposeSemitones + keyDirectiveTranspose) == 0
          ? rawKey
          : transposeChord(rawKey!, transposeSemitones + keyDirectiveTranspose);
      final metaMap = <String, String?>{
        'title': title,
        'subtitle': subtitles.isEmpty ? null : subtitles.first,
        'artist': artists.isEmpty ? null : artists.join(', '),
        'composer': composers.isEmpty ? null : composers.join(', '),
        'lyricist': lyricists.isEmpty ? null : lyricists.join(', '),
        'arranger': arrangers.isEmpty ? null : arrangers.join(', '),
        'album': album,
        'year': year,
        'duration': duration,
        'tempo': tempo,
        'time': time,
        'key': effectiveKey,
        'capo': capo?.toString(),
      };
      return input.replaceAllMapped(RegExp(r'%\{([^}]+)\}'), (match) {
        final keyName = match.group(1)!.trim().toLowerCase();
        return metaMap[keyName] ?? '';
      });
    }

    void applyMetadata(String keyName, String? rawValue) {
      final cleaned = rawValue?.trim();
      final interpolated = cleaned == null || cleaned.isEmpty
          ? null
          : interpolateMeta(cleaned);
      final nonEmpty = interpolated == null || interpolated.isEmpty
          ? null
          : interpolated;
      switch (keyName) {
        case 'title':
        case 't':
          title = nonEmpty;
          break;
        case 'subtitle':
        case 'st':
          if (nonEmpty != null) subtitles.add(nonEmpty);
          break;
        case 'artist':
          if (nonEmpty != null) artists.add(nonEmpty);
          break;
        case 'composer':
          if (nonEmpty != null) composers.add(nonEmpty);
          break;
        case 'lyricist':
          if (nonEmpty != null) lyricists.add(nonEmpty);
          break;
        case 'arranger':
          if (nonEmpty != null) arrangers.add(nonEmpty);
          break;
        case 'album':
          album = nonEmpty;
          break;
        case 'year':
          year = nonEmpty;
          break;
        case 'duration':
          duration = nonEmpty;
          break;
        case 'tempo':
          tempo = nonEmpty;
          break;
        case 'time':
          time = nonEmpty;
          break;
        case 'key':
          rawKey = nonEmpty;
          keyDirectiveTranspose = directiveTranspose;
          break;
        case 'capo':
          capo = int.tryParse(nonEmpty ?? '');
          break;
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (hasChordProMarkers && line.trimLeft().startsWith('#')) {
        continue;
      }
      if (line.trim().isEmpty) {
        if (insideExplicitSection) {
          if (builder.hasLines) {
            builder.addLine(const SongLine(segments: <SongLineSegment>[]));
          }
        } else {
          flushSection();
          builder.reset();
        }
        continue;
      }

      final directiveMatch = _directiveRegExp.firstMatch(line.trim());
      if (directiveMatch != null) {
        final rawDirective = directiveMatch.group(1)!.trim().toLowerCase();
        final directive = _baseDirectiveName(rawDirective);
        final value = directiveMatch.group(2)?.trim();

        if (directive == 'define') {
          final definition = _parseChordDefinition(value ?? '', definedChords);
          if (definition != null) {
            definedChords[definition.name] = definition;
            definedChordOrder.remove(definition.name);
            definedChordOrder.add(definition.name);
          }
          hasRichFormatting = true;
          continue;
        }

        if (directive == 'chord') {
          final parsed = _parseChordDefinition(value ?? '', definedChords);
          final resolved = parsed == null
              ? null
              : parsed.frets.isEmpty &&
                    parsed.keys.isEmpty &&
                    definedChords.containsKey(parsed.name)
              ? definedChords[parsed.name]
              : parsed;
          if (resolved != null && resolved.hasDiagram) {
            final effectiveTranspose = transposeSemitones + directiveTranspose;
            final transposedDef = effectiveTranspose == 0
                ? resolved
                : SongChordDefinition(
                    name: resolved.name,
                    displayName: transposeChord(
                      resolved.label,
                      effectiveTranspose,
                    ),
                    baseFret: resolved.baseFret,
                    frets: resolved.frets,
                    fingers: resolved.fingers,
                    keys: resolved.keys,
                    diagramEnabled: resolved.diagramEnabled,
                  );
            builder.addLine(
              SongLine(segments: const [], inlineChord: transposedDef),
            );
          }
          hasRichFormatting = true;
          continue;
        }

        switch (directive) {
          case 'title':
          case 't':
          case 'subtitle':
          case 'st':
          case 'artist':
          case 'composer':
          case 'lyricist':
          case 'arranger':
          case 'album':
          case 'year':
          case 'duration':
          case 'tempo':
          case 'time':
          case 'key':
          case 'capo':
            applyMetadata(directive, value);
            hasRichFormatting = true;
            continue;
          case 'meta':
            if (value != null && value.isNotEmpty) {
              final metaMatch = RegExp(r'^([^\s:]+)(?:(?::\s*|\s+)(.*))$')
                  .firstMatch(value);
              if (metaMatch != null) {
                applyMetadata(
                  metaMatch.group(1)!.toLowerCase(),
                  metaMatch.group(2),
                );
              }
            }
            hasRichFormatting = true;
            continue;
          case 'transpose':
            final parsedOffset = int.tryParse(value ?? '');
            directiveTranspose = parsedOffset ?? 0;
            if (rawKey != null && sections.isEmpty && !builder.hasLines) {
              keyDirectiveTranspose = directiveTranspose;
            }
            hasRichFormatting = true;
            continue;
          case 'diagrams':
            diagramsPlacement = _parseDiagramsPlacement(value);
            hasRichFormatting = true;
            continue;
          case 'titlefont':
          case 'tf':
            titleFont = value == null || value.isEmpty ? null : value;
            hasRichFormatting = true;
            continue;
          case 'titlesize':
          case 'ts':
            titleSize = _parseFontSize(value);
            hasRichFormatting = true;
            continue;
          case 'titlecolour':
          case 'titlecolor':
          case 'tc':
            titleColourArgb = _parseColour(value);
            hasRichFormatting = true;
            continue;
          case 'chordfont':
          case 'cf':
            chordFont = value == null || value.isEmpty ? null : value;
            hasRichFormatting = true;
            continue;
          case 'chordsize':
          case 'cs':
            chordSize = _parseFontSize(value);
            hasRichFormatting = true;
            continue;
          case 'chordcolour':
          case 'chordcolor':
          case 'cc':
            chordColourArgb = _parseColour(value);
            hasRichFormatting = true;
            continue;
          case 'soc':
          case 'start_of_chorus':
            flushSection();
            builder.reset(
              type: SongSectionType.chorus,
              label: _sectionLabel(value, 'Chorus'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'eoc':
          case 'end_of_chorus':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'chorus':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            final hasExplicitLabel = value != null && value.trim().isNotEmpty;
            final recallLabel = _sectionLabel(
              value,
              lastChorus?.label ?? 'Chorus',
            );
            final useDefaultLabel =
                !hasExplicitLabel && (lastChorus?.isDefaultLabel ?? true);
            if (lastChorus != null) {
              sections.add(
                SongSection(
                  type: SongSectionType.chorus,
                  label: recallLabel,
                  isDefaultLabel: useDefaultLabel,
                  lines: lastChorus!.lines,
                ),
              );
            } else {
              sections.add(
                SongSection(
                  type: SongSectionType.chorus,
                  label: recallLabel,
                  isDefaultLabel: useDefaultLabel,
                  lines: [
                    SongLine(
                      segments: [SongLineSegment(lyric: recallLabel)],
                      style: SongLineStyle.commentItalic,
                    ),
                  ],
                ),
              );
            }
            hasRichFormatting = true;
            continue;
          case 'start_of_verse':
          case 'sov':
            flushSection();
            builder.reset(
              type: SongSectionType.verse,
              label: _sectionLabel(value, 'Verse'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'end_of_verse':
          case 'eov':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'sob':
          case 'start_of_bridge':
            flushSection();
            builder.reset(
              type: SongSectionType.bridge,
              label: _sectionLabel(value, 'Bridge'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'eob':
          case 'end_of_bridge':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'start_of_intro':
            flushSection();
            builder.reset(
              type: SongSectionType.intro,
              label: _sectionLabel(value, 'Intro'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'end_of_intro':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'start_of_outro':
            flushSection();
            builder.reset(
              type: SongSectionType.outro,
              label: _sectionLabel(value, 'Outro'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'end_of_outro':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'start_of_tab':
          case 'sot':
            flushSection();
            builder.reset(
              type: SongSectionType.tag,
              label: _sectionLabel(value, 'Tab'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'end_of_tab':
          case 'eot':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'start_of_grid':
          case 'sog':
            flushSection();
            builder.reset(
              type: SongSectionType.tag,
              label: _sectionLabel(value, 'Grid'),
              isDefaultLabel: value == null || value.trim().isEmpty,
            );
            insideExplicitSection = true;
            hasRichFormatting = true;
            continue;
          case 'end_of_grid':
          case 'eog':
            flushSection();
            builder.reset();
            insideExplicitSection = false;
            hasRichFormatting = true;
            continue;
          case 'comment':
          case 'c':
            builder.addLine(
              SongLine(
                segments: [
                  SongLineSegment(lyric: interpolateMeta(value ?? '')),
                ],
                style: SongLineStyle.comment,
              ),
            );
            hasRichFormatting = true;
            continue;
          case 'comment_italic':
          case 'ci':
            builder.addLine(
              SongLine(
                segments: [
                  SongLineSegment(lyric: interpolateMeta(value ?? '')),
                ],
                style: SongLineStyle.commentItalic,
              ),
            );
            hasRichFormatting = true;
            continue;
          case 'comment_box':
          case 'cb':
            builder.addLine(
              SongLine(
                segments: [
                  SongLineSegment(lyric: interpolateMeta(value ?? '')),
                ],
                style: SongLineStyle.commentBox,
              ),
            );
            hasRichFormatting = true;
            continue;
        }
        hasRichFormatting = true;
        continue;
      }

      final effectiveTranspose = transposeSemitones + directiveTranspose;
      final parsedLine = _SongFormatterLineParser.parseLine(
        line,
        transposeSemitones: effectiveTranspose,
      );
      if (parsedLine.hasChords || parsedLine.hasWrappedDirective) {
        hasRichFormatting = true;
      }
      builder.addLine(
        SongLine(
          segments: parsedLine.line.segments,
          style: parsedLine.line.style,
          inlineChord: parsedLine.line.inlineChord,
          chordFont: chordFont,
          chordSize: chordSize,
          chordColourArgb: chordColourArgb,
        ),
      );
    }

    flushSection();

    if (sections.isEmpty) {
      sections.add(
        const SongSection(type: SongSectionType.freeform, lines: <SongLine>[]),
      );
    }

    final totalKeyTranspose = transposeSemitones + keyDirectiveTranspose;
    final resolvedKey = rawKey == null
        ? null
        : totalKeyTranspose == 0
        ? rawKey
        : transposeChord(rawKey!, totalKeyTranspose);

    return SongFormattingResult(
      rawText: normalizedText,
      hasRichFormatting: hasRichFormatting,
      title: title,
      subtitle: subtitles.isEmpty ? null : subtitles.first,
      subtitles: List<String>.unmodifiable(subtitles),
      artist: artists.isEmpty ? null : artists.join(', '),
      artists: List<String>.unmodifiable(artists),
      composers: List<String>.unmodifiable(composers),
      lyricists: List<String>.unmodifiable(lyricists),
      arrangers: List<String>.unmodifiable(arrangers),
      album: album,
      year: year,
      duration: duration,
      tempo: tempo,
      time: time,
      key: resolvedKey,
      capo: capo,
      sections: sections,
      chordDefinitions: definedChordOrder
          .map((name) => definedChords[name]!)
          .toList(growable: false),
      diagramsPlacement: diagramsPlacement,
      titleFont: titleFont,
      titleSize: titleSize,
      titleColourArgb: titleColourArgb,
      chordFont: chordFont,
      chordSize: chordSize,
      chordColourArgb: chordColourArgb,
    );
  }

  static String _baseDirectiveName(String rawDirective) {
    final trimmed = rawDirective.endsWith('!')
        ? rawDirective.substring(0, rawDirective.length - 1)
        : rawDirective;
    final dashIndex = trimmed.indexOf('-');
    if (dashIndex <= 0) return trimmed;
    return trimmed.substring(0, dashIndex);
  }

  static SongDiagramsPlacement _parseDiagramsPlacement(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'off':
      case 'none':
      case 'false':
      case '0':
        return SongDiagramsPlacement.none;
      case 'bottom':
        return SongDiagramsPlacement.bottom;
      default:
        return SongDiagramsPlacement.top;
    }
  }

  static SongFontSizeSpec? _parseFontSize(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.endsWith('%')) {
      final parsed = double.tryParse(
        value.substring(0, value.length - 1).trim(),
      );
      if (parsed == null || parsed <= 0) return null;
      return SongFontSizeSpec(value: parsed, isPercent: true);
    }
    final cleaned = value.toLowerCase().endsWith('pt')
        ? value.substring(0, value.length - 2).trim()
        : value;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return null;
    return SongFontSizeSpec(value: parsed);
  }

  static int? _parseColour(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    final named = _namedColours[value];
    if (named != null) return named;
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 3) {
        final expanded = hex.split('').map((c) => '$c$c').join();
        return int.tryParse('FF$expanded', radix: 16);
      }
      if (hex.length == 6) {
        return int.tryParse('FF$hex', radix: 16);
      }
      if (hex.length == 8) {
        return int.tryParse(hex, radix: 16);
      }
    }
    return null;
  }

  static String _sectionLabel(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    final attrMatch = _labelAttributeRegExp.firstMatch(trimmed);
    if (attrMatch != null) {
      final extracted =
          attrMatch.group(1) ?? attrMatch.group(2) ?? attrMatch.group(3) ?? '';
      if (extracted.trim().isNotEmpty) return extracted.trim();
    }
    return trimmed.replaceAll('"', '').replaceAll("'", '').trim();
  }

  static SongChordDefinition? _parseChordDefinition(
    String value,
    Map<String, SongChordDefinition> knownDefinitions,
  ) {
    final tokens = _defineTokenRegExp
        .allMatches(value)
        .map((match) => _stripDefineToken(match.group(0)!))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return null;
    }

    final name = _stripDefineToken(tokens.first);
    var baseFret = 1;
    var diagramEnabled = true;
    String? displayName;
    final frets = <String>[];
    final fingers = <String>[];
    final keys = <int>[];

    var index = 1;
    while (index < tokens.length) {
      final keyword = tokens[index++].toLowerCase();
      switch (keyword) {
        case 'base-fret':
        case 'base_fret':
          if (index < tokens.length) {
            baseFret = int.tryParse(tokens[index++]) ?? baseFret;
          }
          break;
        case 'frets':
          frets.clear();
          index = _collectDefineValues(tokens, index, frets);
          break;
        case 'fingers':
          fingers.clear();
          index = _collectDefineValues(tokens, index, fingers);
          break;
        case 'keys':
          keys.clear();
          while (index < tokens.length &&
              !_defineKeywords.contains(tokens[index].toLowerCase())) {
            final key = int.tryParse(tokens[index++]);
            if (key != null) keys.add(key);
          }
          break;
        case 'copy':
        case 'copyall':
          if (index < tokens.length) {
            final source = knownDefinitions[_stripDefineToken(tokens[index++])];
            if (source != null) {
              baseFret = source.baseFret;
              diagramEnabled = source.diagramEnabled;
              frets
                ..clear()
                ..addAll(source.frets);
              fingers
                ..clear()
                ..addAll(source.fingers);
              keys
                ..clear()
                ..addAll(source.keys);
              if (keyword == 'copyall') {
                displayName = source.displayName;
              }
            }
          }
          break;
        case 'diagram':
          if (index < tokens.length) {
            diagramEnabled = tokens[index++].toLowerCase() != 'off';
          }
          break;
        case 'display':
          if (index < tokens.length) {
            displayName = tokens[index++];
          }
          break;
        case 'format':
          index = tokens.length;
          break;
      }
    }

    return SongChordDefinition(
      name: name,
      displayName: displayName,
      baseFret: baseFret,
      frets: List<String>.unmodifiable(frets),
      fingers: List<String>.unmodifiable(fingers),
      keys: List<int>.unmodifiable(keys),
      diagramEnabled: diagramEnabled,
    );
  }

  static int _collectDefineValues(
    List<String> tokens,
    int index,
    List<String> values,
  ) {
    while (index < tokens.length &&
        !_defineKeywords.contains(tokens[index].toLowerCase())) {
      values.addAll(_splitDefineValue(tokens[index++]));
    }
    return index;
  }

  static List<String> _splitDefineValue(String token) {
    if (!token.contains('-') || _signedIntRegExp.hasMatch(token)) {
      return <String>[token];
    }
    return token
        .split('-')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static String _stripDefineToken(String token) {
    if (token.length >= 2 &&
        ((token.startsWith('"') && token.endsWith('"')) ||
            (token.startsWith('\'') && token.endsWith('\'')) ||
            (token.startsWith('[') && token.endsWith(']')))) {
      return token.substring(1, token.length - 1);
    }
    return token;
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
  _SongSectionBuilder()
    : _label = null,
      _type = SongSectionType.freeform,
      _isDefaultLabel = false;

  SongSectionType _type;
  String? _label;
  bool _isDefaultLabel;
  final List<SongLine> _lines = <SongLine>[];

  bool get hasLines => _lines.isNotEmpty;

  void reset({
    SongSectionType type = SongSectionType.freeform,
    String? label,
    bool isDefaultLabel = false,
  }) {
    _type = type;
    _label = label;
    _isDefaultLabel = isDefaultLabel;
    _lines.clear();
  }

  void addLine(SongLine line) {
    _lines.add(line);
  }

  SongSection? build() {
    while (_lines.isNotEmpty && _lines.last.isBlank) {
      _lines.removeLast();
    }
    if (_lines.isEmpty) {
      return null;
    }

    return SongSection(
      type: _type,
      label: _label,
      isDefaultLabel: _isDefaultLabel,
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
