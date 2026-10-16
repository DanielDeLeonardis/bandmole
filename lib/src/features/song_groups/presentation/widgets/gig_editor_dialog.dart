import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:flutter/material.dart';

class GigEditorDialog extends StatefulWidget {
  final Gig? existingGig;

  const GigEditorDialog({super.key, this.existingGig});

  @override
  State<GigEditorDialog> createState() => _GigEditorDialogState();
}

class _GigEditorDialogState extends State<GigEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _venueController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _notesController;
  DateTime? _selectedDate;

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  void initState() {
    super.initState();
    final gig = widget.existingGig;
    _titleController = TextEditingController(text: gig?.title ?? '');
    _venueController = TextEditingController(text: gig?.venue ?? '');
    _startTimeController = TextEditingController(text: gig?.startTime ?? '');
    _notesController = TextEditingController(text: gig?.notes ?? '');
    _selectedDate = gig?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _startTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = SongGroupUtils.normalizeWhitespace(_titleController.text);
      final venue = _venueController.text.trim().isNotEmpty
          ? SongGroupUtils.normalizeWhitespace(_venueController.text)
          : null;
      final startTime = _startTimeController.text.trim().isNotEmpty
          ? SongGroupUtils.normalizeWhitespace(_startTimeController.text)
          : null;
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      Navigator.of(context).pop({
        'title': title,
        'date': _selectedDate,
        'venue': venue,
        'startTime': startTime,
        'notes': notes,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final isEditing = widget.existingGig != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editGig : l10n.createGig),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.gigTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      SongGroupUtils.normalizeWhitespace(value).isEmpty) {
                    return l10n.gigTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                            : l10n.gigDate,
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueController,
                decoration: InputDecoration(
                  labelText: l10n.gigVenue,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: l10n.gigStartTime,
                  hintText: 'e.g. 19:30',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.gigNotes,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
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
