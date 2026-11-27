import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:flutter/material.dart';

const double _paletteWrapWidth = 640.0;

class ChordProChordPalette extends StatelessWidget {
  const ChordProChordPalette({
    super.key,
    required this.chords,
    required this.enabled,
    required this.l10n,
    required this.onInsert,
    required this.onAddCustomChord,
    this.allowWrap = true,
  });

  final List<String> chords;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<ChordProInsertTemplate> onInsert;
  final VoidCallback onAddCustomChord;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ...chords.map(
        (chord) => _DraggablePaletteChip(
          key: ValueKey<String>('chord_chip_$chord'),
          label: chord,
          template: ChordProInsertTemplate('[$chord]'),
          enabled: enabled,
          onInsert: onInsert,
        ),
      ),
      ActionChip(
        key: const ValueKey<String>('add_custom_chord_chip'),
        label: Text('+ ${l10n.editorCustomChord}'),
        onPressed: enabled ? onAddCustomChord : null,
      ),
    ];

    return _ResponsivePalette(
      key: const ValueKey<String>('chordpro_chords'),
      chips: chips,
      allowWrap: allowWrap,
    );
  }
}

class ChordProDirectivePalette extends StatelessWidget {
  const ChordProDirectivePalette({
    super.key,
    required this.directiveNames,
    required this.globalCustomNames,
    required this.enabled,
    required this.l10n,
    required this.onInsert,
    required this.onAddCustomDirective,
    required this.onRemoveGlobalDirective,
    this.allowWrap = true,
  });

  final List<String> directiveNames;
  final Set<String> globalCustomNames;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<ChordProInsertTemplate> onInsert;
  final VoidCallback onAddCustomDirective;
  final ValueChanged<String> onRemoveGlobalDirective;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ...directiveNames.map(
        (name) => _DraggablePaletteChip(
          key: ValueKey<String>('directive_chip_$name'),
          label: name,
          template: ChordProDocument.directiveTemplate(name),
          enabled: enabled,
          deleteTooltip: l10n.editorDeleteCustomDirective,
          onInsert: onInsert,
          onDeleted: globalCustomNames.contains(name)
              ? () => onRemoveGlobalDirective(name)
              : null,
        ),
      ),
      ActionChip(
        key: const ValueKey<String>('add_custom_directive_chip'),
        label: Text('+ ${l10n.editorCustomDirective}'),
        onPressed: enabled ? onAddCustomDirective : null,
      ),
    ];

    return _ResponsivePalette(
      key: const ValueKey<String>('chordpro_directives'),
      chips: chips,
      allowWrap: allowWrap,
    );
  }
}

class _DraggablePaletteChip extends StatelessWidget {
  const _DraggablePaletteChip({
    super.key,
    required this.label,
    required this.template,
    required this.enabled,
    required this.onInsert,
    this.onDeleted,
    this.deleteTooltip,
  });

  final String label;
  final ChordProInsertTemplate template;
  final bool enabled;
  final ValueChanged<ChordProInsertTemplate> onInsert;
  final VoidCallback? onDeleted;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final chip = onDeleted != null
        ? InputChip(
            label: Text(label),
            onPressed: enabled ? () => onInsert(template) : null,
            deleteButtonTooltipMessage: deleteTooltip,
            onDeleted: enabled ? onDeleted : null,
          )
        : ActionChip(
            label: Text(label),
            onPressed: enabled ? () => onInsert(template) : null,
          );

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Draggable<ChordProInsertTemplate>(
        data: template,
        maxSimultaneousDrags: enabled ? 1 : 0,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Chip(label: Text(label)),
        ),
        child: chip,
      ),
    );
  }
}

class _ResponsivePalette extends StatelessWidget {
  const _ResponsivePalette({
    super.key,
    required this.chips,
    required this.allowWrap,
  });

  final List<Widget> chips;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (allowWrap && constraints.maxWidth >= _paletteWrapWidth) {
          return Wrap(spacing: 0, runSpacing: 6, children: chips);
        }
        return SizedBox(
          height: 46,
          child: ListView(scrollDirection: Axis.horizontal, children: chips),
        );
      },
    );
  }
}
