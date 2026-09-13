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
  });

  final SongFormattingResult song;
  final double fontSize;

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
        final wideLayout = constraints.maxWidth >= _largeScreenMinWidth;
        final columnCount = constraints.maxWidth >= _extraWideScreenMinWidth ? 3 : 2;
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
                      song: song,
                      bodyStyle: bodyStyle,
                      chordStyle: chordStyle,
                      sectionStyle: sectionStyle,
                      columnCount: columnCount,
                    )
                  else
                    _NarrowSongLayout(
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

class _NarrowSongLayout extends StatelessWidget {
  const _NarrowSongLayout({
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
