import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';

class SongRelinkDialog extends StatefulWidget {
  final GigSong song;
  final List<SongFile> availableSongs;
  final String? rootDirectory;

  const SongRelinkDialog({
    super.key,
    required this.song,
    this.availableSongs = const <SongFile>[],
    this.rootDirectory,
  });

  @override
  State<SongRelinkDialog> createState() => _SongRelinkDialogState();
}

class _SongRelinkDialogState extends State<SongRelinkDialog> {
  late final TextEditingController _pathController;
  String? _selectedRelativePath;

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.song.relativePath);
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  String _relativeSongPath(SongFile song) {
    final path = song.namePath.replaceAll('\\', '/');
    final root = widget.rootDirectory
        ?.replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    if (root == null || root.isEmpty) {
      return path;
    }

    final rootPrefix = '$root/';
    final pathToCheck = path.toLowerCase();
    final prefixToCheck = rootPrefix.toLowerCase();
    return pathToCheck.startsWith(prefixToCheck)
        ? path.substring(rootPrefix.length)
        : path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final available = widget.availableSongs;

    return AlertDialog(
      title: Text(l10n.relinkSong),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current broken link:\n${widget.song.relativePath}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Target Song Relative Path',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _selectedRelativePath = val),
            ),
            if (available.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Or select from current library:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final item = available[index];
                      final relPath = _relativeSongPath(item);
                      final isSelected = _selectedRelativePath == relPath ||
                          _pathController.text == relPath;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        title: Text(item.namePath.split(RegExp(r'[\\/]+')).last),
                        subtitle: Text(relPath),
                        onTap: () {
                          setState(() {
                            _selectedRelativePath = relPath;
                            _pathController.text = relPath;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final path = SongGroupUtils.normalizeWhitespace(_pathController.text);
            if (path.isNotEmpty) {
              Navigator.of(context).pop(path);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
