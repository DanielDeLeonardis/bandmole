import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CustomChordDialog extends StatefulWidget {
  const CustomChordDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<CustomChordDialog> createState() => _CustomChordDialogState();
}

class _CustomChordDialogState extends State<CustomChordDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.editorCustomChord),
      content: TextField(
        key: const ValueKey<String>('custom_chord_input'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.l10n.editorChordName),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(
          key: const ValueKey<String>('custom_chord_add'),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.l10n.editorAdd),
        ),
      ],
    );
  }
}

class CustomDirectiveDialog extends StatefulWidget {
  const CustomDirectiveDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<CustomDirectiveDialog> createState() => _CustomDirectiveDialogState();
}

class _CustomDirectiveDialogState extends State<CustomDirectiveDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isGlobal = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.editorCustomDirective),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey<String>('custom_directive_input'),
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.l10n.editorCustomName,
            ),
            onSubmitted: (value) => Navigator.pop(
              context,
              (name: value, isGlobal: _isGlobal),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            key: const ValueKey<String>('custom_directive_scope'),
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text(widget.l10n.editorScopeGlobal),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(widget.l10n.editorScopeSong),
              ),
            ],
            selected: <bool>{_isGlobal},
            onSelectionChanged: (selection) {
              setState(() => _isGlobal = selection.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(
          key: const ValueKey<String>('custom_directive_add'),
          onPressed: () => Navigator.pop(
            context,
            (name: _controller.text, isGlobal: _isGlobal),
          ),
          child: Text(widget.l10n.editorAdd),
        ),
      ],
    );
  }
}

class OverwriteFileDialog extends StatelessWidget {
  const OverwriteFileDialog({
    super.key,
    required this.l10n,
    required this.targetPath,
  });

  final AppLocalizations l10n;
  final String targetPath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.editorOverwriteTitle),
      content: Text(l10n.editorOverwriteMessage(targetPath)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('chordpro_confirm_overwrite'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.editorOverwrite),
        ),
      ],
    );
  }
}

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.editorUnsavedChanges),
      content: Text(l10n.editorSaveBeforeLeaving),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'discard'),
          child: Text(l10n.editorDiscard),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'save'),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
