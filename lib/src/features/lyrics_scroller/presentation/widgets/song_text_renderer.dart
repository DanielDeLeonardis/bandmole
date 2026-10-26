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
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Consolas',
          fontSize: fontSize,
          height: 1.45,
        ) ??
        const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 18.0,
          height: 1.45,
        );
    final chordStyle = bodyStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );
    final sectionStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        );

    if (!song.hasRichFormatting) {
      return Text(
        song.rawText,
        style: bodyStyle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = allowMultiColumnLayout &&
            constraints.maxWidth >= _largeScreenMinWidth;
        final columnCount = allowMultiColumnLayout &&
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
                    sectionStyle: sectionStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: 16),
                  if (wideLayout)
                    _WideSongLayout(
                      key: const ValueKey<String>('song_text_renderer_wide_layout'),
                      song: song,
                      bodyStyle: bodyStyle,
                      chordStyle: chordStyle,
                      sectionStyle: sectionStyle,
                      columnCount: columnCount,
                    )
                  else
                    _NarrowSongLayout(
                      key: const ValueKey<String>('song_text_renderer_narrow_layout'),
                      song: song,
                      bodyStyle: bodyStyle,
                      chordStyle: chordStyle,
                      sectionStyle: sectionStyle,
                    ),
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
    required this.sectionStyle,
    required this.bodyStyle,
  });

  final SongFormattingResult song;
  final TextStyle sectionStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final metadata = <Widget>[];

    if (song.key != null) {
      metadata.add(
        _MetadataChip(
          label: 'Key',
          value: song.key!,
        ),
      );
    }

    if (song.capo != null) {
      metadata.add(
        _MetadataChip(
          label: 'Capo',
          value: '${song.capo}',
        ),
      );
    }

    if (song.artist != null) {
      metadata.add(
        _MetadataChip(
          label: 'Artist',
          value: song.artist!,
        ),
      );
    }

    final chordDiagrams = song.chordDefinitions
        .where((definition) => definition.hasDiagram)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (song.title != null)
          Text(
            song.title!,
            style: sectionStyle.copyWith(fontSize: 28),
          ),
        if (song.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            song.subtitle!,
            style: bodyStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metadata,
          ),
        ],
        if (chordDiagrams.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: chordDiagrams
                .map(
                  (definition) => _ChordDiagramCard(
                    definition: definition,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text('$label: $value'),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontWeight: FontWeight.w600),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}

class _ChordDiagramCard extends StatelessWidget {
  const _ChordDiagramCard({
    required this.definition,
  });

  final SongChordDefinition definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontWeight: FontWeight.w700);

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
            height: 176,
            child: CustomPaint(
              painter: _ChordDiagramPainter(
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
    final stringValues = definition.frets.isNotEmpty
        ? definition.frets
        : definition.keys.map((value) => '$value').toList(growable: false);
    final stringCount = stringValues.isNotEmpty ? stringValues.length : 6;
    if (stringCount == 0) {
      return;
    }

    final fretCount = _visibleFretCount(stringValues);
    final left = 16.0;
    final right = size.width - 16.0;
    final top = 18.0;
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
      if (relativeFret == null || relativeFret <= 0) {
        continue;
      }

      if (relativeFret > fretCount) {
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
          TextStyle(
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
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
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

    final columns = _splitSectionsIntoColumns(
      song.sections,
      actualColumnCount,
    );

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
    columns.add(
      sections.sublist(
        startIndex,
        endIndex,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (section.label != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            section.label!,
            style: sectionStyle,
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
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
    if (line.isBlank) {
      return const SizedBox(height: 12);
    }

    if (!line.hasChords) {
      return Text(
        line.plainText,
        style: bodyStyle,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 0,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: line.segments
          .map(
            (segment) => _ChordLyricSegment(
              segment: segment,
              bodyStyle: bodyStyle,
              chordStyle: chordStyle,
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
  });

  final SongLineSegment segment;
  final TextStyle bodyStyle;
  final TextStyle chordStyle;

  @override
  Widget build(BuildContext context) {
    if (segment.chord == null || segment.chord!.isEmpty) {
      return Text(
        segment.lyric,
        style: bodyStyle,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.chord!,
          style: chordStyle,
        ),
        Text(
          segment.lyric,
          style: bodyStyle,
        ),
      ],
    );
  }
}
