import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:flutter/material.dart';

class ChordProOutlinePanel extends StatelessWidget {
  const ChordProOutlinePanel({
    super.key,
    required this.sections,
    required this.directives,
    required this.enabled,
    required this.l10n,
    required this.onMoveSection,
    required this.onJumpToLine,
  });

  final List<ChordProSectionRange> sections;
  final List<ChordProEntry> directives;
  final bool enabled;
  final AppLocalizations l10n;
  final void Function(int oldIndex, int newIndex) onMoveSection;
  final ValueChanged<int> onJumpToLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.editorOutline,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: sections.length,
            onReorderItem: onMoveSection,
            itemBuilder: (context, index) {
              final section = sections[index];
              return ListTile(
                key: ValueKey<String>('section_$index'),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: enabled
                    ? ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle, size: 18),
                      )
                    : const Icon(Icons.segment, size: 18),
                title: Text(section.label, overflow: TextOverflow.ellipsis),
                subtitle: Text(l10n.editorLine(section.start + 1)),
                onTap: () => onJumpToLine(section.start),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey<String>('section_up_$index'),
                      tooltip: l10n.editorMoveSectionUp,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: enabled && index > 0
                          ? () => onMoveSection(index, index - 1)
                          : null,
                    ),
                    IconButton(
                      key: ValueKey<String>('section_down_$index'),
                      tooltip: l10n.editorMoveSectionDown,
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: enabled && index < sections.length - 1
                          ? () => onMoveSection(index, index + 1)
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: directives.length,
            itemBuilder: (context, index) {
              final entry = directives[index];
              return ListTile(
                dense: true,
                title: Text(entry.name),
                subtitle: Text(entry.value ?? ''),
                onTap: () => onJumpToLine(entry.line),
              );
            },
          ),
        ),
      ],
    );
  }
}
