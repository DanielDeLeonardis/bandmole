import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';

class ChordProEntry {
  const ChordProEntry(this.name, this.value, this.line);

  final String name;
  final String? value;
  final int line;

  String get normalizedName => name.toLowerCase();
}

class ChordProSectionRange {
  const ChordProSectionRange(
    this.label,
    this.start,
    this.end, {
    this.isClosed = true,
  });

  final String label;
  final int start;
  final int end;
  final bool isClosed;
}

class ChordProInsertTemplate {
  const ChordProInsertTemplate(this.text, {int? cursorOffset})
    : cursorOffset = cursorOffset ?? text.length;

  final String text;
  final int cursorOffset;
}

class ChordProConversionResult {
  const ChordProConversionResult({
    required this.document,
    this.ambiguousLines = const <int>[],
  });

  final ChordProDocument document;
  final List<int> ambiguousLines;
}

class ChordProDocument {
  ChordProDocument(this.text);

  static const supportedDirectives = <String>{
    'album',
    'arranger',
    'artist',
    'capo',
    'chord',
    'chordfont',
    'chordsize',
    'chordcolour',
    'chorus',
    'comment',
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
  };

  static const builtInDirectiveAliases = <String>{
    't',
    'st',
    'c',
    'ci',
    'cb',
    'comment_italic',
    'comment_box',
    'sov',
    'eov',
    'soc',
    'eoc',
    'sob',
    'eob',
    'sot',
    'eot',
    'sog',
    'eog',
    'start_of_tab',
    'end_of_tab',
    'start_of_grid',
    'end_of_grid',
    'start_of_intro',
    'end_of_intro',
    'start_of_outro',
    'end_of_outro',
    'cf',
    'cs',
    'cc',
    'chordcolor',
    'tf',
    'ts',
    'tc',
    'titlecolor',
    'meta',
    'x_scroll_speed',
  };

  static const Set<String> _ambiguousInlineChords = <String>{'A', 'Am'};

  static final RegExp _lineBreak = RegExp(r'\r\n|\r|\n');
  static final RegExp _directive = RegExp(
    r'^\s*\{([A-Za-z_][\w-]*!?)(?:(?::\s*|\s+)(.*?))?\}\s*$',
  );
  static final RegExp _chord = RegExp(
    r'^(?:N\.?C\.?|[A-G](?:#|b)?(?:(?:maj|min|dim|aug|sus|add|m|M|\+|°|ø)?(?:[245679]|11|13)?)*(?:(?:sus|add)[249]|(?:[#b+-](?:5|9|11|13))|\([^)]+\))*(?:/[A-G](?:#|b)?)?)$',
  );
  static final RegExp _tokens = RegExp(r'\S+');
  static final RegExp _inlineChordAnnotation = RegExp(r'\[([^\]]+)\]');
  static final RegExp _plainSectionHeader = RegExp(
    r'^\s*(?:\[\s*(verse|chorus|bridge)(?:\s+[^\]\r\n]+)?\s*\]|(verse|chorus|bridge)(?:\s+[0-9a-zA-Z]+)?\s*:)\s*$',
    caseSensitive: false,
  );
  static final RegExp _labelAttribute = RegExp(
    "label\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|(\\S+))",
    caseSensitive: false,
  );
  static final RegExp _customDirectiveNamePattern = RegExp(
    r'^[a-z][a-z0-9_-]*$',
  );

  final String text;

  String get lineEnding => text.contains('\r\n')
      ? '\r\n'
      : text.contains('\r')
      ? '\r'
      : '\n';

  List<String> get lines => text.split(_lineBreak);

  List<int> get lineStartOffsets {
    final offsets = <int>[0];
    for (final match in _lineBreak.allMatches(text)) {
      offsets.add(match.end);
    }
    return offsets;
  }

  int offsetForLine(int lineIndex) {
    final offsets = lineStartOffsets;
    if (lineIndex <= 0) return 0;
    if (lineIndex >= offsets.length) return text.length;
    return offsets[lineIndex];
  }

  String withLineEnding(String ending) => text.replaceAll(_lineBreak, ending);

  static String normalizeDirectiveName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static bool isValidCustomDirectiveName(String raw) {
    final normalized = normalizeDirectiveName(raw);
    return _customDirectiveNamePattern.hasMatch(normalized);
  }

  static bool isBuiltInDirective(String raw) {
    final normalized = normalizeDirectiveName(raw);
    return supportedDirectives.contains(normalized) ||
        builtInDirectiveAliases.contains(normalized);
  }

  static ChordProInsertTemplate directiveTemplate(
    String name, {
    String lineEnding = '\n',
  }) {
    final lower = name.toLowerCase();
    switch (lower) {
      case 'start_of_verse':
        final open = '{start_of_verse}$lineEnding';
        return ChordProInsertTemplate(
          '$open$lineEnding{end_of_verse}',
          cursorOffset: open.length,
        );
      case 'start_of_chorus':
        final open = '{start_of_chorus}$lineEnding';
        return ChordProInsertTemplate(
          '$open$lineEnding{end_of_chorus}',
          cursorOffset: open.length,
        );
      case 'start_of_bridge':
        final open = '{start_of_bridge}$lineEnding';
        return ChordProInsertTemplate(
          '$open$lineEnding{end_of_bridge}',
          cursorOffset: open.length,
        );
      case 'end_of_verse':
      case 'end_of_chorus':
      case 'end_of_bridge':
      case 'chorus':
        return ChordProInsertTemplate('{$name}');
      case 'scroll_speed':
        return const ChordProInsertTemplate(
          '{scroll_speed: 5}',
          cursorOffset: '{scroll_speed: '.length,
        );
      case 'define':
        return const ChordProInsertTemplate(
          '{define: C base-fret 1 frets x 3 2 0 1 0}',
          cursorOffset: '{define: '.length,
        );
      case 'chord':
        return const ChordProInsertTemplate(
          '{chord: C base-fret 1 frets x 3 2 0 1 0}',
          cursorOffset: '{chord: '.length,
        );
      case 'diagrams':
        return const ChordProInsertTemplate(
          '{diagrams: top}',
          cursorOffset: '{diagrams: '.length,
        );
      default:
        final prefix = '{$name: ';
        return ChordProInsertTemplate('$prefix}', cursorOffset: prefix.length);
    }
  }

  List<ChordProEntry> get directives {
    final result = <ChordProEntry>[];
    final source = lines;
    for (var index = 0; index < source.length; index++) {
      final match = _directive.firstMatch(source[index]);
      if (match != null) {
        result.add(ChordProEntry(match.group(1)!, match.group(2), index));
      }
    }
    return result;
  }

  List<String> get usedChords {
    final seen = <String>{};
    final result = <String>[];
    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('#') || _directive.hasMatch(line)) continue;
      for (final match in _inlineChordAnnotation.allMatches(line)) {
        final chord = match.group(1)?.trim();
        if (chord != null && chord.isNotEmpty && seen.add(chord)) {
          result.add(chord);
        }
      }
    }
    return result;
  }

  List<ChordProSectionRange> get sections {
    const startAliases = <String, String>{
      'sov': 'verse',
      'soc': 'chorus',
      'sob': 'bridge',
      'sot': 'tab',
      'sog': 'grid',
    };
    const endAliases = <String, String>{
      'eov': 'verse',
      'eoc': 'chorus',
      'eob': 'bridge',
      'eot': 'tab',
      'eog': 'grid',
    };

    String? startKindOf(String? rawName) {
      if (rawName == null) return null;
      final base = _stripSelector(rawName.toLowerCase());
      if (base.startsWith('start_of_')) {
        return base.substring('start_of_'.length);
      }
      return startAliases[base];
    }

    String? endKindOf(String? rawName) {
      if (rawName == null) return null;
      final base = _stripSelector(rawName.toLowerCase());
      if (base.startsWith('end_of_')) {
        return base.substring('end_of_'.length);
      }
      return endAliases[base];
    }

    final result = <ChordProSectionRange>[];
    final source = lines;
    for (var index = 0; index < source.length; index++) {
      final match = _directive.firstMatch(source[index]);
      final kind = startKindOf(match?.group(1));
      if (kind == null) continue;

      int? closedAt;
      int? nextStartAt;
      for (var end = index + 1; end < source.length; end++) {
        final nextMatch = _directive.firstMatch(source[end]);
        final nextName = nextMatch?.group(1);
        if (endKindOf(nextName) == kind) {
          closedAt = end;
          break;
        }
        if (startKindOf(nextName) != null) {
          nextStartAt = end;
          break;
        }
      }

      final label = _extractSectionLabel(match?.group(2), kind);
      if (closedAt != null) {
        result.add(ChordProSectionRange(label, index, closedAt, isClosed: true));
        index = closedAt;
      } else {
        var endLine = (nextStartAt ?? source.length) - 1;
        while (endLine > index && source[endLine].trim().isEmpty) {
          endLine--;
        }
        result.add(ChordProSectionRange(label, index, endLine, isClosed: false));
        index = endLine;
      }
    }
    return result;
  }

  SongFormattingResult get preview => SongFormatter.parse(text);

  int get scrollSpeed {
    for (final entry in directives.reversed) {
      final name = _stripSelector(entry.normalizedName);
      if (name == 'scroll_speed' || name == 'x_scroll_speed') {
        final value = int.tryParse(entry.value?.trim() ?? '');
        return value != null && value >= 1 && value <= 99 ? value : 5;
      }
      if (name == 'meta') {
        final raw = entry.value?.trim() ?? '';
        final metaMatch = RegExp(
          r'^(?:x_)?scroll_speed(?::\s*|\s+)(.+)$',
          caseSensitive: false,
        ).firstMatch(raw);
        if (metaMatch != null) {
          final value = int.tryParse(metaMatch.group(1)!.trim());
          return value != null && value >= 1 && value <= 99 ? value : 5;
        }
      }
    }
    return 5;
  }

  ChordProDocument insert(int offset, String value) {
    final position = offset.clamp(0, text.length);
    return ChordProDocument(text.replaceRange(position, position, value));
  }

  ChordProDocument moveSection(int from, int to) {
    final ranges = sections;
    if (from < 0 ||
        from >= ranges.length ||
        to < 0 ||
        to >= ranges.length ||
        from == to) {
      return this;
    }

    final source = lines;
    final sectionBlocks = <List<String>>[
      for (final range in ranges) source.sublist(range.start, range.end + 1),
    ];
    final movingBlock = sectionBlocks.removeAt(from);
    sectionBlocks.insert(to, movingBlock);

    final rebuilt = <String>[];
    var cursor = 0;
    for (var i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      if (range.start > cursor) {
        rebuilt.addAll(source.sublist(cursor, range.start));
      }
      rebuilt.addAll(sectionBlocks[i]);
      cursor = range.end + 1;
    }
    if (cursor < source.length) {
      rebuilt.addAll(source.sublist(cursor));
    }

    return ChordProDocument(rebuilt.join(lineEnding));
  }

  static String _stripSelector(String directiveName) {
    final trimmed = directiveName.endsWith('!')
        ? directiveName.substring(0, directiveName.length - 1)
        : directiveName;
    final dashIndex = trimmed.indexOf('-');
    if (dashIndex <= 0) return trimmed;
    final prefix = trimmed.substring(0, dashIndex);
    if (supportedDirectives.contains(prefix) ||
        builtInDirectiveAliases.contains(prefix)) {
      return prefix;
    }
    return trimmed;
  }

  static String _extractSectionLabel(String? rawValue, String kind) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      return kind.isEmpty
          ? ''
          : '${kind[0].toUpperCase()}${kind.substring(1)}';
    }
    final attrMatch = _labelAttribute.firstMatch(trimmed);
    if (attrMatch != null) {
      final value =
          attrMatch.group(1) ?? attrMatch.group(2) ?? attrMatch.group(3) ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    }
    return trimmed.replaceAll('"', '').replaceAll("'", '').trim();
  }

  static bool _isChordToken(String token) {
    if (token.isEmpty) return false;
    return _chord.hasMatch(token);
  }

  static bool _isChordOnlyLine(List<RegExpMatch> tokens) {
    if (tokens.isEmpty) return false;
    if (!tokens.every((match) => _isChordToken(match.group(0)!))) {
      return false;
    }
    if (tokens.length == 1 && _ambiguousInlineChords.contains(tokens.first.group(0))) {
      return false;
    }
    return true;
  }

  static int _visualColumn(String line, int charIndex) {
    var col = 0;
    for (var i = 0; i < charIndex && i < line.length; i++) {
      col += line[i] == '\t' ? 4 : 1;
    }
    return col;
  }

  static int _charIndexForVisualColumn(String line, int targetColumn) {
    var col = 0;
    for (var i = 0; i < line.length; i++) {
      if (col >= targetColumn) return i;
      col += line[i] == '\t' ? 4 : 1;
    }
    return line.length;
  }

  static ChordProDocument convert(String source) =>
      convertDetailed(source).document;

  static ChordProConversionResult convertDetailed(String source) {
    final doc = ChordProDocument(source);
    final ending = doc.lineEnding;
    final lines = doc.lines;
    final output = <String>[];
    final ambiguousLines = <int>[];
    String? openSectionKind;

    void closeOpenSection() {
      if (openSectionKind != null) {
        output.add('{end_of_$openSectionKind}');
        openSectionKind = null;
      }
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        output.add(line);
        continue;
      }

      if (trimmed.startsWith('#') || _directive.hasMatch(line)) {
        output.add(line);
        continue;
      }

      final sectionMatch = _plainSectionHeader.firstMatch(line);
      if (sectionMatch != null) {
        closeOpenSection();
        final kind = (sectionMatch.group(1) ?? sectionMatch.group(2)!)
            .toLowerCase();
        var label = trimmed;
        if (label.startsWith('[') && label.endsWith(']')) {
          label = label.substring(1, label.length - 1).trim();
        } else if (label.endsWith(':')) {
          label = label.substring(0, label.length - 1).trim();
        }
        output.add('{start_of_$kind: $label}');
        openSectionKind = kind;
        continue;
      }

      final tokens = _tokens.allMatches(line).toList();
      final isChordLine = _isChordOnlyLine(tokens);

      if (isChordLine) {
        final hasNext = index + 1 < lines.length;
        final nextLine = hasNext ? lines[index + 1] : '';
        final nextTrimmed = nextLine.trim();
        final nextTokens = _tokens.allMatches(nextLine).toList();
        final nextIsChordLine = _isChordOnlyLine(nextTokens);
        final nextIsDirectiveOrComment =
            nextTrimmed.startsWith('#') ||
            _directive.hasMatch(nextLine) ||
            _plainSectionHeader.hasMatch(nextLine);

        final canMergeAboveLyric =
            hasNext &&
            nextTrimmed.isNotEmpty &&
            !nextIsChordLine &&
            !nextIsDirectiveOrComment &&
            !nextLine.contains('[') &&
            _visualColumn(line, tokens.first.start) <=
                _visualColumn(nextLine, nextLine.length) + 4;

        if (canMergeAboveLyric) {
          var lyric = lines[++index];
          final trailingChords = <String>[];
          final lyricVisualLength = _visualColumn(lyric, lyric.length);
          final inBounds = <RegExpMatch>[];
          for (final token in tokens) {
            final col = _visualColumn(line, token.start);
            if (col > lyricVisualLength) {
              trailingChords.add('[${token.group(0)}]');
            } else {
              inBounds.add(token);
            }
          }
          for (final token in inBounds.reversed) {
            final col = _visualColumn(line, token.start);
            final offset = _charIndexForVisualColumn(lyric, col);
            lyric = lyric.replaceRange(offset, offset, '[${token.group(0)}]');
          }
          if (trailingChords.isNotEmpty) {
            final separator = lyric.isEmpty || lyric.endsWith(' ') ? '' : ' ';
            lyric = '$lyric$separator${trailingChords.join(' ')}';
          }
          output.add(lyric);
        } else {
          final leadingSpaces = line.substring(0, tokens.first.start);
          final chordList = tokens.map((m) => '[${m.group(0)}]').join(' ');
          output.add('$leadingSpaces$chordList');
        }
        continue;
      }

      final chordTokens = tokens
          .where((match) => _isChordToken(match.group(0)!))
          .toList();
      final unambiguousChords = chordTokens
          .where((match) => !_ambiguousInlineChords.contains(match.group(0)))
          .length;

      if (!line.contains('[') &&
          unambiguousChords >= 2 &&
          chordTokens.length < tokens.length) {
        var converted = line;
        for (final token in chordTokens.reversed) {
          converted = converted.replaceRange(
            token.start,
            token.end,
            '[${token.group(0)}]',
          );
        }
        output.add(converted.replaceAll(RegExp(r'\] +'), ']'));
      } else {
        if (!line.contains('[') && chordTokens.isNotEmpty) {
          ambiguousLines.add(index + 1);
        }
        output.add(line);
      }
    }

    if (openSectionKind != null) {
      final trailingBlanks = <String>[];
      while (output.isNotEmpty && output.last.trim().isEmpty) {
        trailingBlanks.add(output.removeLast());
      }
      closeOpenSection();
      output.addAll(trailingBlanks.reversed);
    }

    return ChordProConversionResult(
      document: ChordProDocument(output.join(ending)),
      ambiguousLines: List<int>.unmodifiable(ambiguousLines),
    );
  }
}
