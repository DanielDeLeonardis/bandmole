import 'dart:io';

import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:bandmole/src/features/song_loader/domain/song_library.dart';
import 'package:bandmole/src/features/song_loader/data/android_saf_library.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/song_loader/presentation/widgets/song_loader_effects_listener.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:filepicker_windows/filepicker_windows.dart' as windows_picker;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gigs_controller.dart';
import 'package:bandmole/src/features/song_groups/presentation/song_group_error_localizer.dart';
import 'package:bandmole/src/features/song_groups/presentation/views/gigs_panel_view.dart';

typedef SongLibraryDirectoryPicker = Future<String?> Function();

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key, this.directoryPicker});

  final SongLibraryDirectoryPicker? directoryPicker;

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView>
    with TickerProviderStateMixin {
  static const _wideLayoutBreakpoint = 960.0;
  static const _rootDirPrefsKey = 'song_root_directory';
  static const _selectedSongPrefsKey = 'selected_song_path';
  static const _expandedFoldersPrefsKey = 'expanded_song_folders';

  String? _rootDir;
  String? _selectedSongPath;
  Song? _selectedSong;
  late final TabController _panelTabController;
  late final TabController _widePanelTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _caseSensitiveSearch = false;
  final Set<String> _expandedFolders = <String>{};
  List<SongFile> _songs = const <SongFile>[];
  final AndroidSafLibrary _safLibrary = const AndroidSafLibrary();

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  void initState() {
    super.initState();
    _panelTabController = TabController(length: 3, vsync: this);
    _widePanelTabController = TabController(length: 2, vsync: this);
    _loadPersistedState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _panelTabController.dispose();
    _widePanelTabController.dispose();
    super.dispose();
  }

  void _onSongLoaded(Song song) {
    setState(() => _selectedSong = song);
    if (MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint) {
      _widePanelTabController.animateTo(0);
    } else {
      _panelTabController.animateTo(1);
    }
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final rootDir = prefs.getString(_rootDirPrefsKey);
    final selectedSongPath = prefs.getString(_selectedSongPrefsKey);
    final expandedFolders =
        prefs.getStringList(_expandedFoldersPrefsKey) ?? const <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _rootDir = rootDir;
      _selectedSongPath = selectedSongPath;
      _expandedFolders.addAll(expandedFolders);
      _songs = const <SongFile>[];
    });
    await _refreshSongs();
  }

  Future<void> _refreshSongs() async {
    final root = _rootDir;
    if (root == null) {
      return;
    }
    try {
      final songs = root.startsWith('content://')
          ? await _safLibrary.scan(root)
          : Directory(root).existsSync()
          ? SongLibrary.scanDirectory(root)
          : const <SongFile>[];
      if (mounted && root == _rootDir) {
        setState(() => _songs = songs);
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _songs = const <SongFile>[]);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_l10n.libraryUnavailable)));
      }
    }
  }

  Future<void> _persistRootDir(String? rootDir) async {
    final prefs = await SharedPreferences.getInstance();
    if (rootDir == null) {
      await prefs.remove(_rootDirPrefsKey);
      return;
    }
    await prefs.setString(_rootDirPrefsKey, rootDir);
  }

  Future<void> _persistSelectedSong(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_selectedSongPrefsKey);
      return;
    }
    await prefs.setString(_selectedSongPrefsKey, path);
  }

  Future<void> _persistExpandedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _expandedFoldersPrefsKey,
      _expandedFolders.toList()..sort(),
    );
  }

  void _onFolderExpansionChanged(String path, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedFolders.add(path);
      } else {
        _expandedFolders.remove(path);
      }
    });
    _persistExpandedFolders();
  }

  Future<void> _pickLibraryRoot() async {
    final path = await (widget.directoryPicker ?? _pickDirectoryDialog)();
    if (path == null) {
      return;
    }

    await _persistRootDir(path);
    setState(() {
      _rootDir = path;
    });
    await _refreshSongs();
  }

  Future<String?> _pickDirectoryDialog() async {
    final l10n = _l10n;
    if (Platform.isWindows) {
      final picker = windows_picker.DirectoryPicker()
        ..title = l10n.selectSongLibraryFolder
        ..initialDirectory = _rootDir ?? Directory.current.path;
      return picker.getDirectory()?.path;
    }

    if (Platform.isAndroid) {
      return _safLibrary.pickRoot(initialUri: _rootDir);
    }

    return FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectSongLibraryFolder,
      initialDirectory: _rootDir,
    );
  }

  void _onSongTapped(SongFile file, {bool fromGig = false}) {
    if (!fromGig && ref.read(gigsControllerProvider).isSetOpen) {
      return;
    }
    setState(() {
      _selectedSongPath = file.path;
    });
    if (!fromGig) {
      ref.read(gigsControllerProvider.notifier).clearActiveSong();
    }
    _persistSelectedSong(file.path);
    ref.read(songLoaderControllerProvider.notifier).pickAndLoadSong(file);
  }

  void _closeGigSet() {
    ref.read(gigsControllerProvider.notifier).closeSet();
    if (MediaQuery.sizeOf(context).width < _wideLayoutBreakpoint) {
      _panelTabController.animateTo(0);
    }
  }

  String _relativeSongPath(SongFile song) {
    final path = song.namePath.replaceAll('\\', '/');
    final root = _rootDir
        ?.replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    if (root == null || root.isEmpty) {
      return path;
    }

    final rootPrefix = '$root/';
    final pathToCheck = Platform.isWindows ? path.toLowerCase() : path;
    final prefixToCheck = Platform.isWindows
        ? rootPrefix.toLowerCase()
        : rootPrefix;
    return pathToCheck.startsWith(prefixToCheck)
        ? path.substring(rootPrefix.length)
        : path;
  }

  _SongDirectoryNode _buildSongTree() {
    final root = _SongDirectoryNode(name: '', relativePath: '');
    for (final song in _songs) {
      final segments = _relativeSongPath(song)
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.isEmpty) {
        continue;
      }

      var parent = root;
      var relativeDirectory = '';
      for (final segment in segments.take(segments.length - 1)) {
        relativeDirectory = relativeDirectory.isEmpty
            ? segment
            : '$relativeDirectory/$segment';
        parent = parent.directories.putIfAbsent(
          segment,
          () => _SongDirectoryNode(
            name: segment,
            relativePath: relativeDirectory,
          ),
        );
      }
      parent.songs.add(song);
    }
    return root;
  }

  bool _matchesSearch(String name) {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      return true;
    }
    return _caseSensitiveSearch
        ? name.contains(query)
        : name.toLowerCase().contains(query.toLowerCase());
  }

  _FilteredSongDirectory? _filterSongDirectory(
    _SongDirectoryNode directory, {
    required bool inheritedMatch,
  }) {
    final queryActive = _searchQuery.trim().isNotEmpty;
    final directoryMatches = queryActive && _matchesSearch(directory.name);
    final includeAllChildren =
        inheritedMatch || !queryActive || directoryMatches;
    final matchingSongs = directory.songs
        .where(
          (song) =>
              includeAllChildren ||
              _matchesSearch(_relativeSongPath(song).split('/').last),
        )
        .toList(growable: false);
    final hasMatchingSong =
        queryActive &&
        directory.songs.any(
          (song) => _matchesSearch(_relativeSongPath(song).split('/').last),
        );
    final matchingDirectories = directory.directories.values
        .map(
          (child) =>
              _filterSongDirectory(child, inheritedMatch: includeAllChildren),
        )
        .whereType<_FilteredSongDirectory>()
        .toList(growable: false);

    if (queryActive &&
        !includeAllChildren &&
        !directoryMatches &&
        matchingSongs.isEmpty &&
        matchingDirectories.isEmpty) {
      return null;
    }

    final hasSearchMatch =
        directoryMatches ||
        hasMatchingSong ||
        matchingDirectories.any((child) => child.hasSearchMatch);

    return _FilteredSongDirectory(
      source: directory,
      songs: matchingSongs,
      directories: matchingDirectories,
      hasSearchMatch: hasSearchMatch,
      expandForSearch:
          queryActive &&
          (hasMatchingSong ||
              matchingDirectories.any((child) => child.hasSearchMatch)),
    );
  }

  Future<void> _addSongToCurrentSet(String relativePath) async {
    final gigsState = ref.read(gigsControllerProvider);
    final gig = gigsState.selectedGig;
    final set = gigsState.selectedSet;
    if (gig == null || set == null) return;

    try {
      await ref
          .read(gigsControllerProvider.notifier)
          .addSongToSet(
            gig.id,
            set.id,
            relativePath,
            rootDirectory: _rootDir,
            fileExistsCheck: _songExistsInLibrary,
          );
    } on SongGroupException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(songGroupErrorMessage(_l10n, e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  bool _songExistsInLibrary(String relativePath) {
    return _songs.any(
      (song) =>
          SongGroupUtils.arePathsEqual(_relativeSongPath(song), relativePath),
    );
  }

  SongFile _findSongFileByRelativePath(String relativePath) {
    final norm = SongGroupUtils.normalizePath(relativePath).toLowerCase();
    for (final song in _songs) {
      if (SongGroupUtils.normalizePath(_relativeSongPath(song)).toLowerCase() ==
          norm) {
        return song;
      }
    }
    final fullPath = _resolveFullPath(relativePath);
    return SongFile(path: fullPath, displayPath: relativePath);
  }

  String _resolveFullPath(String relativePath) {
    final root = _rootDir;
    if (root == null || root.isEmpty) return relativePath;
    return root.endsWith('/') || root.endsWith('\\')
        ? '$root$relativePath'
        : '$root${Platform.pathSeparator}$relativePath';
  }

  void _onSongSelectedFromGig(GigSong gigSong, int setIndex, int songIndex) {
    final songFile = _findSongFileByRelativePath(gigSong.relativePath);
    _onSongTapped(songFile, fromGig: true);
  }

  void _handleNextSongInGig() {
    final nextSong = ref
        .read(gigsControllerProvider.notifier)
        .navigateToNextSong();
    if (nextSong != null) {
      final state = ref.read(gigsControllerProvider);
      _onSongSelectedFromGig(
        nextSong,
        state.activeSetIndex ?? 0,
        state.activeSongIndex ?? 0,
      );
    }
  }

  void _handlePreviousSongInGig() {
    final prevSong = ref
        .read(gigsControllerProvider.notifier)
        .navigateToPreviousSong();
    if (prevSong != null) {
      final state = ref.read(gigsControllerProvider);
      _onSongSelectedFromGig(
        prevSong,
        state.activeSetIndex ?? 0,
        state.activeSongIndex ?? 0,
      );
    }
  }

  Widget _buildSongTile(SongFile file) {
    final isSelected = _selectedSongPath == file.path;
    final relativePath = _relativeSongPath(file);
    final gigsState = ref.watch(gigsControllerProvider);
    final selectedGig = gigsState.selectedGig;
    final setModeActive = gigsState.isSetOpen;

    final tile = ListTile(
      key: ValueKey<String>('song:${file.path}'),
      contentPadding: const EdgeInsetsDirectional.only(start: 24, end: 8),
      enabled: !setModeActive,
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      leading: Icon(file.isChordPro ? Icons.music_note : Icons.text_snippet),
      title: Text(relativePath.split('/').last),
      trailing: selectedGig != null && !setModeActive
          ? IconButton(
              key: ValueKey<String>('add_song_btn_${file.path}'),
              icon: const Icon(Icons.playlist_add),
              tooltip: _l10n.addToCurrentSet,
              onPressed: () => _addSongToCurrentSet(relativePath),
            )
          : null,
      selected: isSelected,
      onTap: setModeActive ? null : () => _onSongTapped(file),
    );

    return Draggable<SongFile>(
      data: file,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            relativePath.split('/').last,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: tile),
      child: tile,
    );
  }

  Widget _buildDirectoryTile(_FilteredSongDirectory directory) {
    final path = directory.source.relativePath;
    final children = <Widget>[
      ...directory.directories.map(_buildDirectoryTile),
      ...directory.songs.map(_buildSongTile),
    ];

    return ExpansionTile(
      key: PageStorageKey<String>('folder:$path:${directory.expandForSearch}'),
      initiallyExpanded:
          directory.expandForSearch || _expandedFolders.contains(path),
      onExpansionChanged: (expanded) =>
          _onFolderExpansionChanged(path, expanded),
      leading: const Icon(Icons.folder_outlined),
      title: Text(
        directory.source.name,
        key: ValueKey<String>('folder-title:$path'),
      ),
      children: children,
    );
  }

  Widget _buildSearchField() {
    final l10n = _l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                onChanged: (query) => setState(() => _searchQuery = query),
                decoration: InputDecoration(
                  hintText: l10n.searchSongsAndFolders,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _caseSensitiveSearch
                ? l10n.caseSensitiveSearchOn
                : l10n.caseSensitiveSearchOff,
            isSelected: _caseSensitiveSearch,
            icon: const Text(
              'aA',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                setState(() => _caseSensitiveSearch = !_caseSensitiveSearch),
          ),
        ],
      ),
    );
  }

  Widget _buildSongPanel() {
    final l10n = _l10n;
    final selectedSong = _selectedSong;
    if (selectedSong == null || selectedSong.text == null) {
      return Center(child: Text(l10n.selectSongToView));
    }

    final gigsState = ref.watch(gigsControllerProvider);
    final selectedGig = gigsState.selectedGig;
    final activeSetIndex = gigsState.activeSetIndex;
    final activeSet =
        selectedGig != null &&
            activeSetIndex != null &&
            activeSetIndex >= 0 &&
            activeSetIndex < selectedGig.sets.length
        ? selectedGig.sets[activeSetIndex]
        : null;
    final activeSongIndex = gigsState.activeSongIndex;
    final hasActiveGigSong =
        selectedGig != null &&
        activeSet != null &&
        activeSongIndex != null &&
        activeSongIndex >= 0 &&
        activeSongIndex < activeSet.songs.length;
    final setModeActive = gigsState.isSetOpen;
    final gigInfo = hasActiveGigSong && setModeActive
        ? '${selectedGig.title} \u2022 ${activeSet.title} \u2022 ${activeSongIndex + 1}/${activeSet.songs.length}'
        : null;

    return SongView(
      key: const ValueKey<String>('song_view_active'),
      text: selectedSong.text!,
      canTranspose: selectedSong.canTranspose,
      embedded: true,
      onPreviousSong: setModeActive && hasActiveGigSong
          ? _handlePreviousSongInGig
          : null,
      onNextSong: setModeActive && hasActiveGigSong
          ? _handleNextSongInGig
          : null,
      canGoPrevious: setModeActive && gigsState.canNavigatePrevious,
      canGoNext: setModeActive && gigsState.canNavigateNext,
      gigInfo: gigInfo,
      showGigNavigation: setModeActive && hasActiveGigSong,
    );
  }

  Widget _buildGigsPanel() {
    return GigsPanelView(
      librarySongs: _songs,
      rootDirectory: _rootDir,
      selectedLibrarySong: _songs
          .where((song) => song.path == _selectedSongPath)
          .firstOrNull,
      onSongSelected: _onSongSelectedFromGig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final setModeActive = ref.watch(gigsControllerProvider).isSetOpen;
    final songTree = _buildSongTree();
    final filteredTree = _filterSongDirectory(songTree, inheritedMatch: false);
    final treeEntries = filteredTree == null
        ? const <Widget>[]
        : <Widget>[
            ...filteredTree.directories.map(_buildDirectoryTile),
            ...filteredTree.songs.map(_buildSongTile),
          ];
    final songList = treeEntries.isEmpty
        ? Center(
            child: Text(
              _songs.isNotEmpty && _searchQuery.trim().isNotEmpty
                  ? l10n.noMatchingSongsOrFolders
                  : l10n.noSongsFound,
            ),
          )
        : ListView(children: treeEntries);

    final libraryPanel = Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _rootDir == null
                        ? l10n.noLibrarySelected
                        : l10n.rootLabel(_rootDir!),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  tooltip: l10n.chooseSongLibraryFolder,
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickLibraryRoot,
                ),
                IconButton(
                  tooltip: l10n.preferences,
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    context.pushNamed(AppRoutes.preferences);
                  },
                ),
              ],
            ),
          ),
          _buildSearchField(),
          Expanded(child: songList),
        ],
      ),
    );

    final interactiveLibraryPanel = ExcludeFocus(
      excluding: setModeActive,
      child: Opacity(
        opacity: setModeActive ? 0.55 : 1,
        child: AbsorbPointer(
          key: const ValueKey<String>('song_library_guard'),
          absorbing: setModeActive,
          child: libraryPanel,
        ),
      ),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            SongLoaderEffectsListener(onSongLoaded: _onSongLoaded),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey<String>('close_gig_set_button'),
                onPressed: setModeActive ? _closeGigSet : null,
                icon: const Icon(Icons.close),
                label: Text(l10n.closeSet),
              ),
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= _wideLayoutBreakpoint) {
                    final libraryWidth = (constraints.maxWidth * 0.34).clamp(
                      300.0,
                      380.0,
                    );
                    return Row(
                      children: [
                        SizedBox(
                          width: libraryWidth,
                          child: interactiveLibraryPanel,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              ExcludeFocus(
                                excluding: setModeActive,
                                child: AbsorbPointer(
                                  key: const ValueKey<String>(
                                    'panel_tabs_guard',
                                  ),
                                  absorbing: setModeActive,
                                  child: TabBar(
                                    controller: _widePanelTabController,
                                    tabs: [
                                      Tab(text: l10n.songTab),
                                      Tab(
                                        key: const ValueKey<String>('gigs_tab'),
                                        text: l10n.gigsTab,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _widePanelTabController,
                                  physics: setModeActive
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  children: [
                                    _buildSongPanel(),
                                    _buildGigsPanel(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      ExcludeFocus(
                        excluding: setModeActive,
                        child: AbsorbPointer(
                          key: const ValueKey<String>('panel_tabs_guard'),
                          absorbing: setModeActive,
                          child: TabBar(
                            controller: _panelTabController,
                            tabs: [
                              Tab(text: l10n.songsTab),
                              Tab(text: l10n.songTab),
                              Tab(
                                key: const ValueKey<String>('gigs_tab'),
                                text: l10n.gigsTab,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _panelTabController,
                          physics: setModeActive
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          children: [
                            interactiveLibraryPanel,
                            _buildSongPanel(),
                            _buildGigsPanel(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongDirectoryNode {
  _SongDirectoryNode({required this.name, required this.relativePath});

  final String name;
  final String relativePath;
  final Map<String, _SongDirectoryNode> directories = {};
  final List<SongFile> songs = [];
}

class _FilteredSongDirectory {
  const _FilteredSongDirectory({
    required this.source,
    required this.songs,
    required this.directories,
    required this.hasSearchMatch,
    required this.expandForSearch,
  });

  final _SongDirectoryNode source;
  final List<SongFile> songs;
  final List<_FilteredSongDirectory> directories;
  final bool hasSearchMatch;
  final bool expandForSearch;
}
