import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';

class ChordProEntry {
  const ChordProEntry(this.name, this.value, this.line);
  final String name;
  final String? value;
  final int line;
}

class ChordProSectionRange {
  const ChordProSectionRange(this.label, this.start, this.end);
  final String label;
  final int start;
  final int end;
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
    'composer',
    'diagrams',
    'duration',
    'key',
    'lyricist',
    'start_of_bridge',
    'end_of_bridge',
    'start_of_chorus',
    'end_of_chorus',
    'start_of_verse',
    'end_of_verse',
    'subtitle',
    'tempo',
    'time',
    'title',
    'titlefont',
    'titlesize',
    'titlecolour',
    'transpose',
    'year',
    'define',
    'scroll_speed',
  };
  static final RegExp _directive = RegExp(
    r'^\s*\{([\w-]+)(?:(?::\s*|\s+)(.*?))?\}\s*$',
  );
  static final RegExp _chord = RegExp(
    r'^[A-G](?:#|b)?(?:m|maj|dim|aug|sus|add)?\d*(?:/[A-G](?:#|b)?)?$',
  );
  static final RegExp _tokens = RegExp(r'\S+');

  final String text;
  String get lineEnding => text.contains('\r\n')
      ? '\r\n'
      : text.contains('\r')
      ? '\r'
      : '\n';
  List<String> get lines => text.split(lineEnding);

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

  List<ChordProSectionRange> get sections {
    const aliases = <String, String>{
      'sov': 'verse',
      'soc': 'chorus',
      'sob': 'bridge',
      'sot': 'tab',
    };
    const endAliases = <String, String>{
      'eov': 'verse',
      'eoc': 'chorus',
      'eob': 'bridge',
      'eot': 'tab',
    };
    final result = <ChordProSectionRange>[];
    final source = lines;
    for (var index = 0; index < source.length; index++) {
      final match = _directive.firstMatch(source[index]);
      final name = match?.group(1);
      final kind = name != null && name.startsWith('start_of_')
          ? name.substring('start_of_'.length)
          : aliases[name];
      if (kind == null) continue;
      for (var end = index + 1; end < source.length; end++) {
        final closingName = _directive.firstMatch(source[end])?.group(1);
        if (closingName == 'end_of_$kind' || endAliases[closingName] == kind) {
          var label = match?.group(2)?.trim() ?? kind;
          if (label.startsWith('label=')) {
            label = label.substring('label='.length).replaceAll('"', '');
          }
          result.add(ChordProSectionRange(label, index, end));
          index = end;
          break;
        }
      }
    }
    return result;
  }

  SongFormattingResult get preview => SongFormatter.parse(text);

  int get scrollSpeed {
    for (final entry in directives.reversed) {
      if (entry.name == 'scroll_speed') {
        final value = int.tryParse(entry.value?.trim() ?? '');
        return value != null && value >= 1 && value <= 99 ? value : 5;
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
    final moving = ranges[from];
    final block = source.sublist(moving.start, moving.end + 1);
    source.removeRange(moving.start, moving.end + 1);
    final target = ranges[to];
    final destination = to < from
        ? target.start
        : target.end + 1 - block.length;
    source.insertAll(destination, block);
    return ChordProDocument(source.join(lineEnding));
  }

  static ChordProDocument convert(String source) {
    final ending = ChordProDocument(source).lineEnding;
    final lines = source.split(ending);
    final output = <String>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final tokens = _tokens.allMatches(line).toList();
      final isChordLine =
          tokens.isNotEmpty &&
          tokens.every((match) => _chord.hasMatch(match.group(0)!));
      final nextLine = index + 1 < lines.length ? lines[index + 1] : '';
      final nextTokens = _tokens.allMatches(nextLine).toList();
      final nextIsChordLine =
          nextTokens.isNotEmpty &&
          nextTokens.every((match) => _chord.hasMatch(match.group(0)!));
      if (!isChordLine ||
          nextLine.trim().isEmpty ||
          nextIsChordLine ||
          tokens.any((token) => token.start > nextLine.length)) {
        final chordTokens = tokens
            .where((match) => _chord.hasMatch(match.group(0)!))
            .toList();
        if (!line.contains('[') &&
            chordTokens.length >= 2 &&
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
          output.add(line);
        }
        continue;
      }
      var lyric = lines[++index];
      for (final token in tokens.reversed) {
        final offset = token.start.clamp(0, lyric.length);
        lyric = lyric.replaceRange(offset, offset, '[${token.group(0)}]');
      }
      output.add(lyric);
    }
    return ChordProDocument(output.join(ending));
  }
}

