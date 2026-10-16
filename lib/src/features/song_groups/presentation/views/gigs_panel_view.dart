import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gigs_controller.dart';
import 'package:bandmole/src/features/song_groups/presentation/song_group_error_localizer.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/gig_delete_dialog.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/gig_editor_dialog.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/set_editor_dialog.dart';
import 'package:bandmole/src/features/song_groups/presentation/widgets/song_relink_dialog.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnSongSelectedFromGig = void Function(
  GigSong song,
  int setIndex,
  int songIndex,
);

class GigsPanelView extends ConsumerStatefulWidget {
  final List<SongFile> librarySongs;
  final String? rootDirectory;
  final SongFile? selectedLibrarySong;
  final OnSongSelectedFromGig? onSongSelected;

  const GigsPanelView({
    super.key,
    this.librarySongs = const <SongFile>[],
    this.rootDirectory,
    this.selectedLibrarySong,
    this.onSongSelected,
  });

  @override
  ConsumerState<GigsPanelView> createState() => _GigsPanelViewState();
}

class _GigsPanelViewState extends ConsumerState<GigsPanelView> {
  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(gigsControllerProvider.notifier)
          .loadGigs(
            rootDirectory: widget.rootDirectory,
            availableRelativePaths: _availableRelativePaths,
          );
    });
  }

  @override
  void didUpdateWidget(covariant GigsPanelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootDirectory != widget.rootDirectory ||
        oldWidget.librarySongs != widget.librarySongs) {
      ref
          .read(gigsControllerProvider.notifier)
          .loadGigs(
            rootDirectory: widget.rootDirectory,
            availableRelativePaths: _availableRelativePaths,
          );
    }
  }

  Set<String> get _availableRelativePaths =>
      widget.librarySongs.map(_relativeSongPath).toSet();

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

  bool _songExistsInLibrary(String relativePath) {
    return widget.librarySongs.any(
      (song) =>
          SongGroupUtils.arePathsEqual(_relativeSongPath(song), relativePath),
    );
  }

  void _showErrorSnackBar(SongGroupException exception) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(songGroupErrorMessage(_l10n, exception)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _createGig() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const GigEditorDialog(),
    );

    if (result != null) {
      try {
        await ref
            .read(gigsControllerProvider.notifier)
            .createGig(
              title: result['title'] as String,
              date: result['date'] as DateTime?,
              venue: result['venue'] as String?,
              notes: result['notes'] as String?,
              startTime: result['startTime'] as String?,
            );
      } on SongGroupException catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  Future<void> _editGig(Gig gig) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GigEditorDialog(existingGig: gig),
    );

    if (result != null) {
      try {
        final updated = gig.copyWith(
          title: result['title'] as String,
          date: result['date'] as DateTime?,
          venue: result['venue'] as String?,
          notes: result['notes'] as String?,
          startTime: result['startTime'] as String?,
          clearDate: result['date'] == null,
          clearVenue: result['venue'] == null,
          clearNotes: result['notes'] == null,
          clearStartTime: result['startTime'] == null,
        );
        await ref.read(gigsControllerProvider.notifier).updateGig(updated);
      } on SongGroupException catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  Future<void> _deleteGig(Gig gig) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GigDeleteDialog(gig: gig),
    );

    if (confirmed == true) {
      await ref.read(gigsControllerProvider.notifier).deleteGig(gig.id);
    }
  }

  Future<void> _addSet(Gig gig) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => SetEditorDialog(
        otherSetTitles: gig.sets.map((s) => s.title).toList(),
      ),
    );

    if (title != null) {
      try {
        await ref.read(gigsControllerProvider.notifier).addSet(gig.id, title);
      } on SongGroupException catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  Future<void> _renameSet(Gig gig, SongSet set) async {
    final otherTitles = gig.sets
        .where((s) => s.id != set.id)
        .map((s) => s.title)
        .toList();

    final title = await showDialog<String>(
      context: context,
      builder: (context) =>
          SetEditorDialog(existingSet: set, otherSetTitles: otherTitles),
    );

    if (title != null) {
      try {
        await ref
            .read(gigsControllerProvider.notifier)
            .renameSet(gig.id, set.id, title);
      } on SongGroupException catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  Future<void> _deleteSet(Gig gig, SongSet set) async {
    try {
      await ref.read(gigsControllerProvider.notifier).deleteSet(gig.id, set.id);
    } on SongGroupException catch (e) {
      _showErrorSnackBar(e);
    }
  }

  Future<void> _addSongToSet(Gig gig, SongSet set, String relativePath) async {
    try {
      await ref
          .read(gigsControllerProvider.notifier)
          .addSongToSet(
            gig.id,
            set.id,
            relativePath,
            rootDirectory: widget.rootDirectory,
            fileExistsCheck: _songExistsInLibrary,
          );
    } on SongGroupException catch (e) {
      _showErrorSnackBar(e);
    }
  }

  Future<void> _relinkSong(Gig gig, SongSet set, GigSong song) async {
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => SongRelinkDialog(
        song: song,
        availableSongs: widget.librarySongs,
        rootDirectory: widget.rootDirectory,
      ),
    );

    if (newPath != null) {
      try {
        await ref
            .read(gigsControllerProvider.notifier)
            .relinkSong(
              gig.id,
              set.id,
              song.id,
              newPath,
              rootDirectory: widget.rootDirectory,
              fileExistsCheck: _songExistsInLibrary,
            );
      } on SongGroupException catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  Widget _buildGigSelector(GigsState state) {
    final l10n = _l10n;
    final selectedGig = state.selectedGig;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const ValueKey<String>('gig_selector_dropdown'),
              isExpanded: true,
              value: selectedGig?.id,
              hint: Text(l10n.selectGig),
              items: state.gigs.map((gig) {
                return DropdownMenuItem<String>(
                  value: gig.id,
                  child: Text(gig.title, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (id) {
                ref.read(gigsControllerProvider.notifier).selectGig(id);
              },
            ),
          ),
        ),
        IconButton(
          key: const ValueKey<String>('create_gig_button'),
          icon: const Icon(Icons.add),
          tooltip: l10n.createGig,
          onPressed: _createGig,
        ),
        if (selectedGig != null) ...[
          IconButton(
            key: const ValueKey<String>('edit_gig_button'),
            icon: const Icon(Icons.edit),
            tooltip: l10n.editGig,
            onPressed: () => _editGig(selectedGig),
          ),
          IconButton(
            key: const ValueKey<String>('delete_gig_button'),
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteGig,
            onPressed: () => _deleteGig(selectedGig),
          ),
        ],
      ],
    );
  }

  Widget _buildGigSummary(Gig gig) {
    final details = <String>[];
    if (gig.date != null) {
      details.add(
        '${gig.date!.year}-${gig.date!.month.toString().padLeft(2, '0')}-${gig.date!.day.toString().padLeft(2, '0')}',
      );
    }
    if (gig.startTime != null && gig.startTime!.isNotEmpty) {
      details.add(gig.startTime!);
    }
    if (gig.venue != null && gig.venue!.isNotEmpty) {
      details.add(gig.venue!);
    }

    if (details.isEmpty && (gig.notes == null || gig.notes!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty)
            Text(
              details.join(' • '),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          if (gig.notes != null && gig.notes!.isNotEmpty)
            Text(
              gig.notes!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildSongTile(
    Gig gig,
    SongSet set,
    int setIndex,
    GigSong song,
    int songIndex,
  ) {
    final l10n = _l10n;
    final isBroken = song.isBroken;
    final state = ref.watch(gigsControllerProvider);
    final isCurrentPlaying =
        state.selectedGigId == gig.id &&
        state.activeSetIndex == setIndex &&
        state.activeSongIndex == songIndex;

    final songName = song.displayName;

    Widget titleWidget = Text(
      songName,
      style: TextStyle(
        color: isBroken
            ? Theme.of(context).colorScheme.error
            : (isCurrentPlaying ? Theme.of(context).colorScheme.primary : null),
        fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
      ),
    );

    if (isBroken) {
      final tooltipMessage =
          song.brokenReason ?? l10n.brokenSongTooltip(song.relativePath);
      titleWidget = Tooltip(
        key: ValueKey<String>('broken_tooltip_${song.id}'),
        message: tooltipMessage,
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(child: titleWidget),
          ],
        ),
      );
    }

    return ListTile(
      key: ValueKey<String>('gig_song_${song.id}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: titleWidget,
      subtitle: isBroken
          ? Text(song.relativePath, style: const TextStyle(fontSize: 11))
          : null,
      leading: Text(
        '${songIndex + 1}.',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            tooltip: l10n.moveSongUp,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: songIndex > 0
                ? () => ref
                      .read(gigsControllerProvider.notifier)
                      .moveSong(gig.id, set.id, songIndex, -1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            tooltip: l10n.moveSongDown,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: songIndex < set.songs.length - 1
                ? () => ref
                      .read(gigsControllerProvider.notifier)
                      .moveSong(gig.id, set.id, songIndex, 1)
                : null,
          ),
          if (isBroken)
            IconButton(
              icon: const Icon(Icons.link, size: 18),
              tooltip: l10n.relinkSong,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _relinkSong(gig, set, song),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: l10n.removeSong,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => ref
                .read(gigsControllerProvider.notifier)
                .removeSongFromSet(gig.id, set.id, song.id),
          ),
        ],
      ),
      onTap: () {
        ref
            .read(gigsControllerProvider.notifier)
            .selectSong(setIndex, songIndex);
        widget.onSongSelected?.call(song, setIndex, songIndex);
      },
    );
  }

  Widget _buildSetCard(Gig gig, SongSet set, int setIndex) {
    final l10n = _l10n;
    final setNumber = setIndex + 1;
    final state = ref.watch(gigsControllerProvider);
    final isSelectedSet = state.selectedSetId == set.id;

    return DragTarget<SongFile>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final relPath = _relativeSongPath(details.data);
        _addSongToSet(gig, set, relPath);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Card(
          key: ValueKey<String>('set_card_${set.id}'),
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: isSelectedSet
              ? Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.16)
              : (isHovered
                    ? Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.5)
                    : null),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: ValueKey<String>('select_set_${set.id}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => ref
                            .read(gigsControllerProvider.notifier)
                            .selectSet(set.id),
                        child: Text(
                          '${l10n.setNumber(setNumber)}: ${set.title}',
                          style: TextStyle(
                            fontWeight: isSelectedSet
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      tooltip: l10n.moveSetUp,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: setIndex > 0
                          ? () => ref
                                .read(gigsControllerProvider.notifier)
                                .reorderSets(gig.id, setIndex, setIndex - 1)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      tooltip: l10n.moveSetDown,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: setIndex < gig.sets.length - 1
                          ? () => ref
                                .read(gigsControllerProvider.notifier)
                                .reorderSets(gig.id, setIndex, setIndex + 2)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: l10n.renameSet,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () => _renameSet(gig, set),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      tooltip: l10n.deleteSet,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: gig.sets.length > 1
                          ? () => _deleteSet(gig, set)
                          : null,
                    ),
                  ],
                ),
                if (widget.selectedLibrarySong != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        '${l10n.addToSet}: ${_relativeSongPath(widget.selectedLibrarySong!).split(RegExp(r"[\\/]+")).last}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        final relPath = _relativeSongPath(
                          widget.selectedLibrarySong!,
                        );
                        _addSongToSet(gig, set, relPath);
                      },
                    ),
                  ),
                if (set.songs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Text(
                        l10n.emptySetDropSongsHere,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: set.songs.length,
                    onReorderItem: (oldIndex, newIndex) => ref
                        .read(gigsControllerProvider.notifier)
                        .reorderSongsInSet(gig.id, set.id, oldIndex, newIndex),
                    itemBuilder: (context, index) =>
                        ReorderableDragStartListener(
                          key: ValueKey<String>(
                            'song_drag_${set.songs[index].id}',
                          ),
                          index: index,
                          child: _buildSongTile(
                            gig,
                            set,
                            setIndex,
                            set.songs[index],
                            index,
                          ),
                        ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final state = ref.watch(gigsControllerProvider);
    final selectedGig = state.selectedGig;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGigSelector(state),
            const Divider(),
            if (selectedGig == null)
              Expanded(
                child: Center(
                  child: Text(
                    state.gigs.isEmpty ? l10n.noGigsFound : l10n.selectGig,
                  ),
                ),
              )
            else ...[
              _buildGigSummary(selectedGig),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sets,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey<String>('add_set_button'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addSet),
                    onPressed: () => _addSet(selectedGig),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedGig.sets.length,
                  itemBuilder: (context, index) {
                    final set = selectedGig.sets[index];
                    return _buildSetCard(selectedGig, set, index);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
