import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/song_group_error_localizer.dart';
import 'package:flutter/material.dart';

class SetEditorDialog extends StatefulWidget {
  final SongSet? existingSet;
  final List<String> otherSetTitles;

  const SetEditorDialog({
    super.key,
    this.existingSet,
    this.otherSetTitles = const <String>[],
  });

  @override
  State<SetEditorDialog> createState() => _SetEditorDialogState();
}

class _SetEditorDialogState extends State<SetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  String? _customError;

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingSet?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _customError = null);
    if (_formKey.currentState?.validate() ?? false) {
      final title = SongGroupUtils.normalizeWhitespace(_titleController.text);
      try {
        SongGroupUtils.validateSetTitle(
          title,
          widget.otherSetTitles,
        );
        Navigator.of(context).pop(title);
      } on SongGroupException catch (e) {
        setState(() => _customError = songGroupErrorMessage(_l10n, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final isEditing = widget.existingSet != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.renameSet : l10n.addSet),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.setTitle,
                border: const OutlineInputBorder(),
                errorText: _customError,
              ),
              validator: (value) {
                if (value == null ||
                    SongGroupUtils.normalizeWhitespace(value).isEmpty) {
                  return l10n.setTitleRequired;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
