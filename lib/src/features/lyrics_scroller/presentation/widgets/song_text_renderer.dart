import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';
import 'package:flutter/material.dart';

const double _largeScreenMinWidth = 960.0;
const double _extraWideScreenMinWidth = 1500.0;
const double _contentMaxWidth = 1440.0;

class SongTextRenderer extends StatelessWidget {
  const SongTextRenderer({
    super.key,
    required this.song,
    required this.fontSize,
    this.allowMultiColumnLayout = true,
  });

  final SongFormattingResult song;
  final double fontSize;
  final bool allowMultiColumnLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Consolas',
          fontSize: fontSize,
          height: 1.45,
        ) ??
        const TextStyle(fontFamily: 'Consolas', fontSize: 18.0, height: 1.45);
    final chordStyle = bodyStyle.copyWith(
      fontFamily: song.chordFont ?? bodyStyle.fontFamily,
      fontSize: song.chordSize?.resolve(fontSize) ?? fontSize,
      color: song.chordColourArgb != null
          ? Color(song.chordColourArgb!)
          : theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );
    final sectionStyle =
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ) ??
        const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6);
    final titleStyle = sectionStyle.copyWith(
      fontFamily: song.titleFont ?? sectionStyle.fontFamily,
      fontSize: song.titleSize?.resolve(28.0) ?? 28.0,
      color: song.titleColourArgb != null
          ? Color(song.titleColourArgb!)
          : sectionStyle.color,
    );

    if (!song.hasRichFormatting) {
      return Text(song.rawText, style: bodyStyle);
    }

    final summaryDiagrams = song.diagramsPlacement == SongDiagramsPlacement.none
        ? const <SongChordDefinition>[]
        : song.chordDefinitions
              .where((definition) => definition.hasDiagram)
              .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout =
            allowMultiColumnLayout &&
            constraints.maxWidth >= _largeScreenMinWidth;
        final columnCount =
            allowMultiColumnLayout &&
                constraints.maxWidth >= _extraWideScreenMinWidth
            ? 3
            : 2;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SongHeader(
                    song: song,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                    topDiagrams:
                        song.diagramsPlacement == SongDiagramsPlacement.top
                        ? summaryDiagrams
                        : const <SongChordDefinition>[],
                  ),
                  const SizedBox(height: 16),
                  if (wideLayout)
                    _WideSongLayout(
                      key: const ValueKey<String>(
                        'song_text_renderer_wide_layout',
                      ),
                      song: song,
                      bodyStyle: bodyStyle,
                      chordStyle: chordStyle,
                      sectionStyle: sectionStyle,
                      columnCount: columnCount,
                    )
                  else
                    _NarrowSongLayout(
                      key: const ValueKey<String>(
                        'song_text_renderer_narrow_layout',
                      ),
                      song: song,
                      bodyStyle: bodyStyle,
                      chordStyle: chordStyle,
                      sectionStyle: sectionStyle,
                    ),
                  if (song.diagramsPlacement == SongDiagramsPlacement.bottom &&
                      summaryDiagrams.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ChordDiagramWrap(
                      key: const ValueKey<String>(
                        'song_text_renderer_bottom_diagrams',
                      ),
                      definitions: summaryDiagrams,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({
    required this.song,
    required this.titleStyle,
    required this.bodyStyle,
    required this.topDiagrams,
  });

  final SongFormattingResult song;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final List<SongChordDefinition> topDiagrams;

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        EnglishAppLocalizations();
    final metadata = <Widget>[];
    void addChip(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        metadata.add(_MetadataChip(label: label, value: value));
      }
    }

    addChip(l10n.metaKey, song.key);
    addChip(l10n.metaCapo, song.capo?.toString());
    addChip(
      l10n.metaArtist,
      song.artists.isNotEmpty ? song.artists.join(', ') : song.artist,
    );
    addChip(l10n.metaAlbum, song.album);
    addChip(l10n.metaYear, song.year);
    addChip(
      l10n.metaComposer,
      song.composers.isNotEmpty ? song.composers.join(', ') : null,
    );
    addChip(
      l10n.metaLyricist,
      song.lyricists.isNotEmpty ? song.lyricists.join(', ') : null,
    );
    addChip(
      l10n.metaArranger,
      song.arrangers.isNotEmpty ? song.arrangers.join(', ') : null,
    );
    addChip(l10n.metaTempo, song.tempo);
    addChip(l10n.metaTime, song.time);
    addChip(l10n.metaDuration, song.duration);

    final subtitlesToShow = song.subtitles.isNotEmpty
        ? song.subtitles
        : song.subtitle != null
        ? <String>[song.subtitle!]
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (song.title != null) Text(song.title!, style: titleStyle),
        for (final subtitle in subtitlesToShow) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: bodyStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: metadata),
        ],
        if (topDiagrams.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ChordDiagramWrap(definitions: topDiagrams),
        ],
      ],
    );
  }
}

class _ChordDiagramWrap extends StatelessWidget {
  const _ChordDiagramWrap({super.key, required this.definitions});

  final List<SongChordDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: definitions
          .map((definition) => _ChordDiagramCard(definition: definition))
          .toList(growable: false),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text('$label: $value'),
      labelStyle:
          theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
          const TextStyle(fontWeight: FontWeight.w600),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}

class _ChordDiagramCard extends StatelessWidget {
  const _ChordDiagramCard({required this.definition});

  final SongChordDefinition definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontWeight: FontWeight.w700);
    final isKeyboard = definition.frets.isEmpty && definition.keys.isNotEmpty;

    return Container(
      key: ValueKey<String>('chord-diagram-${definition.name}'),
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(definition.label, style: titleStyle),
          const SizedBox(height: 8),
          SizedBox(
            width: 144,
            height: isKeyboard ? 96 : 176,
            child: CustomPaint(
              painter: isKeyboard
                  ? _KeyboardDiagramPainter(
                      keys: definition.keys,
                      lineColor: theme.colorScheme.outline,
                      activeColor: theme.colorScheme.primary,
                    )
                  : _ChordDiagramPainter(
                      definition: definition,
                      lineColor: theme.colorScheme.outline,
                      noteColor: theme.colorScheme.primary,
                      mutedTextColor: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardDiagramPainter extends CustomPainter {
  const _KeyboardDiagramPainter({
    required this.keys,
    required this.lineColor,
    required this.activeColor,
  });

  final List<int> keys;
  final Color lineColor;
  final Color activeColor;

  static const Set<int> _blackPitchClasses = <int>{1, 3, 6, 8, 10};
  static const List<int> _whitePitchClasses = <int>[0, 2, 4, 5, 7, 9, 11];

  @override
  void paint(Canvas canvas, Size size) {
    final activeSet = keys.map((k) => k % 24).toSet();
    final octaves = activeSet.any((k) => k >= 12) ? 2 : 1;
    final whiteCount = 7 * octaves;
    final keyWidth = size.width / whiteCount;
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final whiteFill = Paint()..color = Colors.white;
    final blackFill = Paint()..color = Colors.black87;
    final activeFill = Paint()..color = activeColor;

    var whiteIndex = 0;
    for (var octave = 0; octave < octaves; octave++) {
      for (final pitch in _whitePitchClasses) {
        final note = octave * 12 + pitch;
        final rect = Rect.fromLTWH(
          whiteIndex * keyWidth,
          0,
          keyWidth,
          size.height,
        );
        canvas.drawRect(
          rect,
          activeSet.contains(note) ? activeFill : whiteFill,
        );
        canvas.drawRect(rect, strokePaint);
        whiteIndex++;
      }
    }

    final blackHeight = size.height * 0.6;
    final blackWidth = keyWidth * 0.62;
    const blackOffsets = <int, double>{
      1: 0.68,
      3: 1.68,
      6: 3.68,
      8: 4.68,
      10: 5.68,
    };
    for (var octave = 0; octave < octaves; octave++) {
      for (final pitch in _blackPitchClasses) {
        final note = octave * 12 + pitch;
        final left = (octave * 7 + blackOffsets[pitch]!) * keyWidth;
        final rect = Rect.fromLTWH(left, 0, blackWidth, blackHeight);
        canvas.drawRect(
          rect,
          activeSet.contains(note) ? activeFill : blackFill,
        );
        canvas.drawRect(rect, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardDiagramPainter oldDelegate) {
    return oldDelegate.keys != keys ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.activeColor != activeColor;
  }
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({
    required this.definition,
    required this.lineColor,
    required this.noteColor,
    required this.mutedTextColor,
  });

  final SongChordDefinition definition;
  final Color lineColor;
  final Color noteColor;
  final Color mutedTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stringValues = definition.frets;
    final stringCount = stringValues.isNotEmpty ? stringValues.length : 6;
    final fretCount = _visibleFretCount(stringValues);
    const left = 16.0;
    final right = size.width - 16.0;
    const top = 18.0;
    final bottom = size.height - 22.0;
    final stringSpacing = stringCount == 1
        ? 0.0
        : (right - left) / (stringCount - 1);
    final fretSpacing = (bottom - top) / fretCount;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final nutPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final noteFillPaint = Paint()
      ..color = noteColor
      ..style = PaintingStyle.fill;
    final noteOutlinePaint = Paint()
      ..color = noteColor.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var stringIndex = 0; stringIndex < stringCount; stringIndex++) {
      final x = left + stringIndex * stringSpacing;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), linePaint);
    }

    if (definition.baseFret <= 1) {
      canvas.drawLine(Offset(left, top), Offset(right, top), nutPaint);
      for (var fretIndex = 1; fretIndex <= fretCount; fretIndex++) {
        final y = top + fretIndex * fretSpacing;
        canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
      }
    } else {
      for (var fretIndex = 0; fretIndex <= fretCount; fretIndex++) {
        final y = top + fretIndex * fretSpacing;
        canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
      }
      _drawText(
        canvas,
        '${definition.baseFret}',
        Offset(left - 10, top + fretSpacing * 0.45),
        TextStyle(
          color: mutedTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        align: TextAlign.right,
      );
    }

    for (var stringIndex = 0; stringIndex < stringCount; stringIndex++) {
      final rawValue = stringIndex < stringValues.length
          ? stringValues[stringIndex].trim()
          : '';
      if (rawValue.isEmpty) {
        continue;
      }

      final x = left + stringIndex * stringSpacing;
      if (_isMutedFret(rawValue)) {
        _drawText(
          canvas,
          'x',
          Offset(x, top - 10),
          TextStyle(
            color: mutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );
        continue;
      }

      if (_isOpenFret(rawValue)) {
        _drawText(
          canvas,
          'o',
          Offset(x, top - 10),
          TextStyle(
            color: mutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );
        continue;
      }

      final relativeFret = int.tryParse(rawValue);
      if (relativeFret == null ||
          relativeFret <= 0 ||
          relativeFret > fretCount) {
        continue;
      }

      final y = top + (relativeFret - 0.5) * fretSpacing;
      canvas.drawCircle(Offset(x, y), 9, noteFillPaint);
      canvas.drawCircle(Offset(x, y), 9, noteOutlinePaint);

      final finger = stringIndex < definition.fingers.length
          ? definition.fingers[stringIndex].trim()
          : '';
      if (finger.isNotEmpty && !_isMutedFret(finger) && !_isOpenFret(finger)) {
        _drawText(
          canvas,
          finger,
          Offset(x, y + 0.5),
          const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        );
      }
    }
  }

  int _visibleFretCount(List<String> stringValues) {
    var highestFret = 0;
    for (final value in stringValues) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > highestFret) {
        highestFret = parsed;
      }
    }
    return highestFret > 5 ? highestFret : 5;
  }

  bool _isMutedFret(String value) {
    final lowered = value.toLowerCase();
    return lowered == 'x' || lowered == 'n' || lowered == '-1';
  }

  bool _isOpenFret(String value) => value == '0';

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    TextAlign align = TextAlign.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter oldDelegate) {
    return oldDelegate.definition != definition ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.noteColor != noteColor ||
        oldDelegate.mutedTextColor != mutedTextColor;
  }
}

class _NarrowSongLayout extends StatelessWidget {
  const _NarrowSongLayout({
    super.key,
    required this.song,
    required this.bodyStyle,
    required this.chordStyle,
    required this.sectionStyle,
  });

  final SongFormattingResult song;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;
  final TextStyle sectionStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: song.sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _SongSectionView(
                section: section,
                bodyStyle: bodyStyle,
                chordStyle: chordStyle,
                sectionStyle: sectionStyle,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _WideSongLayout extends StatelessWidget {
  const _WideSongLayout({
    super.key,
    required this.song,
    required this.bodyStyle,
    required this.chordStyle,
    required this.sectionStyle,
    required this.columnCount,
  });

  final SongFormattingResult song;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;
  final TextStyle sectionStyle;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    if (song.sections.length <= 1) {
      return _NarrowSongLayout(
        song: song,
        bodyStyle: bodyStyle,
        chordStyle: chordStyle,
        sectionStyle: sectionStyle,
      );
    }

    final actualColumnCount = columnCount > song.sections.length
        ? song.sections.length
        : columnCount;
    if (actualColumnCount <= 1) {
      return _NarrowSongLayout(
        song: song,
        bodyStyle: bodyStyle,
        chordStyle: chordStyle,
        sectionStyle: sectionStyle,
      );
    }

    final columns = _splitSectionsIntoColumns(song.sections, actualColumnCount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns.length; index++) ...[
          Expanded(
            child: _SectionColumn(
              sections: columns[index],
              bodyStyle: bodyStyle,
              chordStyle: chordStyle,
              sectionStyle: sectionStyle,
            ),
          ),
          if (index != columns.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }
}

List<List<SongSection>> _splitSectionsIntoColumns(
  List<SongSection> sections,
  int columnCount,
) {
  final columns = <List<SongSection>>[];
  final baseSize = sections.length ~/ columnCount;
  final remainder = sections.length % columnCount;
  var startIndex = 0;

  for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
    final chunkSize = baseSize + (columnIndex < remainder ? 1 : 0);
    final endIndex = startIndex + chunkSize;
    columns.add(sections.sublist(startIndex, endIndex));
    startIndex = endIndex;
  }

  return columns;
}

class _SectionColumn extends StatelessWidget {
  const _SectionColumn({
    required this.sections,
    required this.bodyStyle,
    required this.chordStyle,
    required this.sectionStyle,
  });

  final List<SongSection> sections;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;
  final TextStyle sectionStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _SongSectionView(
                section: section,
                bodyStyle: bodyStyle,
                chordStyle: chordStyle,
                sectionStyle: sectionStyle,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SongSectionView extends StatelessWidget {
  const _SongSectionView({
    required this.section,
    required this.bodyStyle,
    required this.chordStyle,
    required this.sectionStyle,
  });

  final SongSection section;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;
  final TextStyle sectionStyle;

  String? _resolvedSectionLabel(AppLocalizations l10n) {
    final raw = section.label;
    if (raw == null) return null;
    if (!section.isDefaultLabel) return raw;
    switch (section.type) {
      case SongSectionType.verse:
        return l10n.sectionVerse;
      case SongSectionType.chorus:
        return l10n.sectionChorus;
      case SongSectionType.bridge:
        return l10n.sectionBridge;
      case SongSectionType.intro:
        return l10n.sectionIntro;
      case SongSectionType.outro:
        return l10n.sectionOutro;
      case SongSectionType.tag:
        return raw == 'Grid' ? l10n.sectionGrid : l10n.sectionTab;
      case SongSectionType.freeform:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        EnglishAppLocalizations();
    final children = <Widget>[];
    final heading = _resolvedSectionLabel(l10n);

    if (heading != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(heading, style: sectionStyle),
        ),
      );
    }

    children.addAll(
      section.lines.map(
        (line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SongLineView(
            line: line,
            bodyStyle: bodyStyle,
            chordStyle: chordStyle,
          ),
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    if (section.type == SongSectionType.chorus) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: content,
      );
    }

    return content;
  }
}

class _SongLineView extends StatelessWidget {
  const _SongLineView({
    required this.line,
    required this.bodyStyle,
    required this.chordStyle,
  });

  final SongLine line;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;

  @override
  Widget build(BuildContext context) {
    if (line.inlineChord != null) {
      return _ChordDiagramCard(definition: line.inlineChord!);
    }

    if (line.isBlank) {
      return const SizedBox(height: 12);
    }

    if (!line.hasChords) {
      if (line.style == SongLineStyle.commentBox) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(line.plainText, style: bodyStyle),
        );
      }
      if (line.style == SongLineStyle.commentItalic) {
        return Text(
          line.plainText,
          style: bodyStyle.copyWith(fontStyle: FontStyle.italic),
        );
      }
      if (line.style == SongLineStyle.comment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(line.plainText, style: bodyStyle),
        );
      }
      return Text(line.plainText, style: bodyStyle);
    }

    final effectiveChordStyle = chordStyle.copyWith(
      fontFamily: line.chordFont ?? chordStyle.fontFamily,
      fontSize:
          line.chordSize?.resolve(bodyStyle.fontSize ?? 18.0) ??
          chordStyle.fontSize,
      color: line.chordColourArgb != null
          ? Color(line.chordColourArgb!)
          : chordStyle.color,
    );

    final hasLyrics = line.segments.any(
      (segment) => segment.lyric.trim().isNotEmpty,
    );

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: line.segments
          .map(
            (segment) => _ChordLyricSegment(
              segment: segment,
              bodyStyle: bodyStyle,
              chordStyle: effectiveChordStyle,
              chordOnlyLine: !hasLyrics,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ChordLyricSegment extends StatelessWidget {
  const _ChordLyricSegment({
    required this.segment,
    required this.bodyStyle,
    required this.chordStyle,
    required this.chordOnlyLine,
  });

  final SongLineSegment segment;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;
  final bool chordOnlyLine;

  @override
  Widget build(BuildContext context) {
    if (segment.chord == null || segment.chord!.isEmpty) {
      return Text(segment.lyric, style: bodyStyle);
    }

    if (chordOnlyLine && segment.lyric.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(segment.chord!, style: chordStyle),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(segment.chord!, style: chordStyle),
        ),
        Text(segment.lyric, style: bodyStyle),
      ],
    );
  }
}
