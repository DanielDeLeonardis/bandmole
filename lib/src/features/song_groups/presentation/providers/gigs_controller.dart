import 'package:bandmole/src/features/song_groups/data/gig_load_validator.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gig_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GigsState {
  final List<Gig> gigs;
  final String? selectedGigId;
  final String? selectedSetId;
  final bool isSetOpen;
  final int? activeSetIndex;
  final int? activeSongIndex;
  final bool isLoading;
  final String? errorMessage;

  const GigsState({
    this.gigs = const <Gig>[],
    this.selectedGigId,
    this.selectedSetId,
    this.isSetOpen = false,
    this.activeSetIndex,
    this.activeSongIndex,
    this.isLoading = false,
    this.errorMessage,
  });

  GigsState copyWith({
    List<Gig>? gigs,
    String? selectedGigId,
    bool clearSelectedGig = false,
    String? selectedSetId,
    bool clearSelectedSet = false,
    bool? isSetOpen,
    int? activeSetIndex,
    bool clearActiveSet = false,
    int? activeSongIndex,
    bool clearActiveSong = false,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GigsState(
      gigs: gigs ?? this.gigs,
      selectedGigId: clearSelectedGig
          ? null
          : (selectedGigId ?? this.selectedGigId),
      selectedSetId: clearSelectedSet
          ? null
          : (selectedSetId ?? this.selectedSetId),
      isSetOpen: isSetOpen ?? this.isSetOpen,
      activeSetIndex: clearActiveSet
          ? null
          : (activeSetIndex ?? this.activeSetIndex),
      activeSongIndex: clearActiveSong
          ? null
          : (activeSongIndex ?? this.activeSongIndex),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  Gig? get selectedGig {
    if (selectedGigId == null) return null;
    final index = gigs.indexWhere((g) => g.id == selectedGigId);
    return index >= 0 ? gigs[index] : null;
  }

  SongSet? get selectedSet {
    final gig = selectedGig;
    if (gig == null || gig.sets.isEmpty || selectedSetId == null) return null;
    final index = gig.sets.indexWhere((s) => s.id == selectedSetId);
    return index >= 0 ? gig.sets[index] : null;
  }

  GigSong? get activeSong {
    final gig = selectedGig;
    if (gig == null || activeSetIndex == null || activeSongIndex == null) {
      return null;
    }
    if (activeSetIndex! < 0 || activeSetIndex! >= gig.sets.length) return null;
    final set = gig.sets[activeSetIndex!];
    if (activeSongIndex! < 0 || activeSongIndex! >= set.songs.length) {
      return null;
    }
    return set.songs[activeSongIndex!];
  }

  bool get canNavigateNext {
    final gig = selectedGig;
    if (gig == null || activeSetIndex == null || activeSongIndex == null) {
      return false;
    }
    final currentSetIndex = activeSetIndex!;
    final currentSongIndex = activeSongIndex!;
    if (currentSetIndex < 0 ||
        currentSetIndex >= gig.sets.length ||
        currentSongIndex < 0 ||
        currentSongIndex >= gig.sets[currentSetIndex].songs.length) {
      return false;
    }
    final currentSet = gig.sets[currentSetIndex];

    if (currentSongIndex + 1 < currentSet.songs.length) {
      return true;
    }

    for (var i = currentSetIndex + 1; i < gig.sets.length; i++) {
      if (gig.sets[i].songs.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  bool get canNavigatePrevious {
    final gig = selectedGig;
    if (gig == null || activeSetIndex == null || activeSongIndex == null) {
      return false;
    }
    final currentSetIndex = activeSetIndex!;
    final currentSongIndex = activeSongIndex!;
    if (currentSetIndex < 0 ||
        currentSetIndex >= gig.sets.length ||
        currentSongIndex < 0 ||
        currentSongIndex >= gig.sets[currentSetIndex].songs.length) {
      return false;
    }

    if (currentSongIndex > 0) {
      return true;
    }

    for (var i = currentSetIndex - 1; i >= 0; i--) {
      if (gig.sets[i].songs.isNotEmpty) {
        return true;
      }
    }

    return false;
  }
}

class GigsController extends Notifier<GigsState> {
  GigRepository get _repository => ref.read(gigRepositoryProvider);

  @override
  GigsState build() {
    return const GigsState();
  }

  Future<void> loadGigs({
    String? rootDirectory,
    Set<String>? availableRelativePaths,
    FileExistsPredicate? fileExistsCheck,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final rawGigs = await _repository.loadGigs();
      final validatedGigs =
          rawGigs
              .map(
                (g) => GigLoadValidator.validateGig(
                  g,
                  rootDirectory: rootDirectory,
                  availableRelativePaths: availableRelativePaths,
                  fileExistsCheck: fileExistsCheck,
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );

      String? newSelectedGigId = state.selectedGigId;
      if (newSelectedGigId != null &&
          !validatedGigs.any((g) => g.id == newSelectedGigId)) {
        newSelectedGigId = null;
      }
      if (newSelectedGigId == null && validatedGigs.isNotEmpty) {
        newSelectedGigId = validatedGigs.first.id;
      }
      final selectedGig = validatedGigs
          .where((gig) => gig.id == newSelectedGigId)
          .firstOrNull;
      final selectedSetId =
          selectedGig?.sets.any((set) => set.id == state.selectedSetId) == true
          ? state.selectedSetId
          : selectedGig?.sets.firstOrNull?.id;
      final selectionChanged =
          state.selectedGigId != newSelectedGigId ||
          state.selectedSetId != selectedSetId;

      state = state.copyWith(
        gigs: validatedGigs,
        selectedGigId: newSelectedGigId,
        selectedSetId: selectedSetId,
        clearSelectedGig: newSelectedGigId == null,
        clearSelectedSet: selectedSetId == null,
        isSetOpen: selectionChanged ? false : state.isSetOpen,
        clearActiveSet: selectionChanged,
        clearActiveSong: selectionChanged,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectGig(String? gigId) {
    if (gigId == null) {
      state = state.copyWith(
        clearSelectedGig: true,
        clearSelectedSet: true,
        isSetOpen: false,
        clearActiveSet: true,
        clearActiveSong: true,
      );
      return;
    }

    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    final firstSetId = gig?.sets.firstOrNull?.id;

    state = state.copyWith(
      selectedGigId: gigId,
      selectedSetId: firstSetId,
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
    );
  }

  void selectSet(String setId) {
    state = state.copyWith(selectedSetId: setId, isSetOpen: false);
  }

  void closeSet() {
    state = state.copyWith(
      clearSelectedSet: true,
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
    );
  }

  void selectSong(int setIndex, int songIndex) {
    final gig = state.selectedGig;
    if (gig == null ||
        setIndex < 0 ||
        setIndex >= gig.sets.length ||
        songIndex < 0 ||
        songIndex >= gig.sets[setIndex].songs.length) {
      return;
    }
    state = state.copyWith(
      selectedSetId: gig.sets[setIndex].id,
      isSetOpen: true,
      activeSetIndex: setIndex,
      activeSongIndex: songIndex,
    );
  }

  void clearActiveSong() {
    state = state.copyWith(
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
    );
  }

  Future<Gig> createGig({
    required String title,
    DateTime? date,
    String? venue,
    String? notes,
    String? startTime,
    List<SongSet>? sets,
  }) async {
    SongGroupUtils.validateGigTitle(title, state.gigs.map((g) => g.title));

    final id = 'gig_${DateTime.now().microsecondsSinceEpoch}';
    final normalizedTitle = SongGroupUtils.normalizeWhitespace(title);
    final gig = Gig.create(
      id: id,
      title: normalizedTitle,
      date: date,
      venue: venue != null ? SongGroupUtils.normalizeWhitespace(venue) : null,
      notes: notes,
      startTime: startTime != null
          ? SongGroupUtils.normalizeWhitespace(startTime)
          : null,
      sets: sets,
    );

    await _repository.saveGig(gig);

    final updatedGigs = [...state.gigs, gig]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    state = state.copyWith(
      gigs: updatedGigs,
      selectedGigId: gig.id,
      selectedSetId: gig.sets.first.id,
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
      clearErrorMessage: true,
    );

    return gig;
  }

  Future<void> updateGig(Gig gig) async {
    if (state.gigs.every((existing) => existing.id != gig.id)) return;

    SongGroupUtils.validateGigTitle(
      gig.title,
      state.gigs.map((g) => g.title),
      excludeTitle: state.gigs.where((g) => g.id == gig.id).firstOrNull?.title,
    );

    await _repository.saveGig(gig);

    final updatedGigs = state.gigs.map((g) => g.id == gig.id ? gig : g).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    state = state.copyWith(gigs: updatedGigs, clearErrorMessage: true);
  }

  Future<void> deleteGig(String gigId) async {
    await _repository.deleteGig(gigId);

    final updatedGigs = state.gigs.where((g) => g.id != gigId).toList();
    final newSelectedGigId = state.selectedGigId == gigId
        ? updatedGigs.firstOrNull?.id
        : state.selectedGigId;
    final newSelectedGig = updatedGigs
        .where((g) => g.id == newSelectedGigId)
        .firstOrNull;

    state = state.copyWith(
      gigs: updatedGigs,
      selectedGigId: newSelectedGigId,
      clearSelectedGig: newSelectedGigId == null,
      selectedSetId: newSelectedGig?.sets.firstOrNull?.id,
      isSetOpen: state.selectedGigId == gigId ? false : state.isSetOpen,
      clearSelectedSet: newSelectedGig == null,
      clearActiveSet: state.selectedGigId == gigId,
      clearActiveSong: state.selectedGigId == gigId,
      clearErrorMessage: true,
    );
  }

  Future<void> addSet(String gigId, String title) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    SongGroupUtils.validateSetTitle(title, gig.sets.map((s) => s.title));

    final normalizedTitle = SongGroupUtils.normalizeWhitespace(title);
    final newSet = SongSet(
      id: '${gigId}_set_${DateTime.now().microsecondsSinceEpoch}',
      title: normalizedTitle,
      songs: const <GigSong>[],
    );

    final updatedGig = gig.copyWith(sets: [...gig.sets, newSet]);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(
      gigs: updatedGigs,
      selectedSetId: newSet.id,
      isSetOpen: false,
      clearErrorMessage: true,
    );
  }

  Future<void> renameSet(String gigId, String setId, String newTitle) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    final targetSet = gig.sets.where((s) => s.id == setId).firstOrNull;
    if (targetSet == null) return;

    SongGroupUtils.validateSetTitle(
      newTitle,
      gig.sets.map((s) => s.title),
      excludeTitle: targetSet.title,
    );

    final normalizedTitle = SongGroupUtils.normalizeWhitespace(newTitle);
    final updatedSets = gig.sets
        .map((s) => s.id == setId ? s.copyWith(title: normalizedTitle) : s)
        .toList();

    final updatedGig = gig.copyWith(sets: updatedSets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(gigs: updatedGigs, clearErrorMessage: true);
  }

  Future<void> deleteSet(String gigId, String setId) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    if (gig.sets.length <= 1) {
      throw const SongGroupException(
        SongGroupErrorCode.gigMustHaveAtLeastOneSet,
      );
    }

    final updatedSets = gig.sets.where((s) => s.id != setId).toList();
    final updatedGig = gig.copyWith(sets: updatedSets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    final newSelectedSetId = state.selectedSetId == setId
        ? updatedSets.first.id
        : state.selectedSetId;

    state = state.copyWith(
      gigs: updatedGigs,
      selectedSetId: newSelectedSetId,
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
      clearErrorMessage: true,
    );
  }

  Future<void> reorderSets(String gigId, int oldIndex, int newIndex) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;
    if (oldIndex < 0 || oldIndex >= gig.sets.length) return;
    if (newIndex < 0 || newIndex > gig.sets.length) return;

    final sets = List<SongSet>.from(gig.sets);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = sets.removeAt(oldIndex);
    sets.insert(newIndex, moved);
    int? updatedActiveSetIndex = state.activeSetIndex;
    final activeSetId =
        state.activeSetIndex != null &&
            state.activeSetIndex! >= 0 &&
            state.activeSetIndex! < gig.sets.length
        ? gig.sets[state.activeSetIndex!].id
        : null;
    if (state.selectedGigId == gigId && activeSetId != null) {
      updatedActiveSetIndex = sets.indexWhere((set) => set.id == activeSetId);
    }

    final updatedGig = gig.copyWith(sets: sets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(
      gigs: updatedGigs,
      activeSetIndex: updatedActiveSetIndex,
      clearErrorMessage: true,
    );
  }

  Future<void> addSongToSet(
    String gigId,
    String setId,
    String relativeSongPath, {
    String? rootDirectory,
    FileExistsPredicate? fileExistsCheck,
  }) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;
    if (!gig.sets.any((set) => set.id == setId)) {
      throw const SongGroupException(SongGroupErrorCode.setNotFound);
    }

    SongGroupUtils.validateSongNotInGig(relativeSongPath, gig.allSongPaths);

    final songId = '${gigId}_${setId}_${DateTime.now().microsecondsSinceEpoch}';
    final newSong = GigSong(
      id: songId,
      relativePath: SongGroupUtils.normalizePath(relativeSongPath),
    );

    final updatedSets = gig.sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(songs: [...set.songs, newSong]);
      }
      return set;
    }).toList();

    final updatedGig = GigLoadValidator.validateGig(
      gig.copyWith(sets: updatedSets),
      rootDirectory: rootDirectory,
      fileExistsCheck: fileExistsCheck,
    );
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(gigs: updatedGigs, clearErrorMessage: true);
  }

  Future<void> removeSongFromSet(
    String gigId,
    String setId,
    String songId,
  ) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    final updatedSets = gig.sets.map((set) {
      if (set.id == setId) {
        return set.copyWith(
          songs: set.songs.where((s) => s.id != songId).toList(),
        );
      }
      return set;
    }).toList();

    final updatedGig = gig.copyWith(sets: updatedSets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(
      gigs: updatedGigs,
      isSetOpen: false,
      clearActiveSet: true,
      clearActiveSong: true,
      clearErrorMessage: true,
    );
  }

  Future<void> reorderSongsInSet(
    String gigId,
    String setId,
    int oldIndex,
    int newIndex,
  ) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    final set = gig.sets.where((s) => s.id == setId).firstOrNull;
    if (set == null) return;
    if (oldIndex < 0 || oldIndex >= set.songs.length) return;
    if (newIndex < 0 || newIndex >= set.songs.length) return;

    final songs = List<GigSong>.from(set.songs);
    final moved = songs.removeAt(oldIndex);
    songs.insert(newIndex, moved);
    final updatedActiveSongIndex =
        state.selectedGigId == gigId &&
            state.activeSetIndex == gig.sets.indexOf(set) &&
            state.activeSongIndex != null &&
            state.activeSongIndex! >= 0 &&
            state.activeSongIndex! < set.songs.length
        ? songs.indexWhere(
            (song) => song.id == set.songs[state.activeSongIndex!].id,
          )
        : state.activeSongIndex;

    final updatedSets = gig.sets.map((s) {
      if (s.id == setId) {
        return s.copyWith(songs: songs);
      }
      return s;
    }).toList();

    final updatedGig = gig.copyWith(sets: updatedSets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(
      gigs: updatedGigs,
      activeSongIndex: updatedActiveSongIndex,
      clearErrorMessage: true,
    );
  }

  Future<void> moveSong(
    String gigId,
    String setId,
    int index,
    int offset,
  ) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    final set = gig.sets.where((s) => s.id == setId).firstOrNull;
    if (set == null) return;
    if (index < 0 || index >= set.songs.length) return;

    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= set.songs.length) return;

    final songs = List<GigSong>.from(set.songs);
    final moved = songs.removeAt(index);
    songs.insert(targetIndex, moved);

    final updatedSets = gig.sets.map((s) {
      if (s.id == setId) {
        return s.copyWith(songs: songs);
      }
      return s;
    }).toList();

    final updatedGig = gig.copyWith(sets: updatedSets);
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(gigs: updatedGigs, clearErrorMessage: true);
  }

  Future<void> relinkSong(
    String gigId,
    String setId,
    String songId,
    String newRelativeSongPath, {
    String? rootDirectory,
    FileExistsPredicate? fileExistsCheck,
  }) async {
    final gig = state.gigs.where((g) => g.id == gigId).firstOrNull;
    if (gig == null) return;

    final currentSong = gig.findSongById(songId);
    if (currentSong == null ||
        !gig.sets.any(
          (set) =>
              set.id == setId && set.songs.any((song) => song.id == songId),
        )) {
      return;
    }

    SongGroupUtils.validateSupportedSongPath(newRelativeSongPath);
    SongGroupUtils.validateSongNotInGig(
      newRelativeSongPath,
      gig.allSongPaths,
      excludeSongPath: currentSong.relativePath,
    );

    final normalizedPath = SongGroupUtils.normalizePath(newRelativeSongPath);
    final updatedSets = gig.sets.map((set) {
      if (set.id == setId) {
        final updatedSongs = set.songs.map((song) {
          if (song.id == songId) {
            return song.copyWith(
              relativePath: normalizedPath,
              isBroken: false,
              clearBrokenReason: true,
            );
          }
          return song;
        }).toList();
        return set.copyWith(songs: updatedSongs);
      }
      return set;
    }).toList();

    final updatedGig = GigLoadValidator.validateGig(
      gig.copyWith(sets: updatedSets),
      rootDirectory: rootDirectory,
      fileExistsCheck: fileExistsCheck,
    );
    await _repository.saveGig(updatedGig);

    final updatedGigs =
        state.gigs.map((g) => g.id == gigId ? updatedGig : g).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    state = state.copyWith(gigs: updatedGigs, clearErrorMessage: true);
  }

  GigSong? navigateToNextSong() {
    final gig = state.selectedGig;
    if (gig == null ||
        state.activeSetIndex == null ||
        state.activeSongIndex == null) {
      return null;
    }

    final currentSetIndex = state.activeSetIndex!;
    final currentSongIndex = state.activeSongIndex!;
    if (currentSetIndex < 0 ||
        currentSetIndex >= gig.sets.length ||
        currentSongIndex < 0 ||
        currentSongIndex >= gig.sets[currentSetIndex].songs.length) {
      return null;
    }
    final currentSet = gig.sets[currentSetIndex];

    if (currentSongIndex + 1 < currentSet.songs.length) {
      final nextSongIndex = currentSongIndex + 1;
      state = state.copyWith(
        activeSetIndex: currentSetIndex,
        activeSongIndex: nextSongIndex,
      );
      return currentSet.songs[nextSongIndex];
    }

    for (var i = currentSetIndex + 1; i < gig.sets.length; i++) {
      if (gig.sets[i].songs.isNotEmpty) {
        state = state.copyWith(activeSetIndex: i, activeSongIndex: 0);
        return gig.sets[i].songs.first;
      }
    }

    return null;
  }

  GigSong? navigateToPreviousSong() {
    final gig = state.selectedGig;
    if (gig == null ||
        state.activeSetIndex == null ||
        state.activeSongIndex == null) {
      return null;
    }

    final currentSetIndex = state.activeSetIndex!;
    final currentSongIndex = state.activeSongIndex!;
    if (currentSetIndex < 0 ||
        currentSetIndex >= gig.sets.length ||
        currentSongIndex < 0 ||
        currentSongIndex >= gig.sets[currentSetIndex].songs.length) {
      return null;
    }

    if (currentSongIndex > 0) {
      final prevSongIndex = currentSongIndex - 1;
      state = state.copyWith(
        activeSetIndex: currentSetIndex,
        activeSongIndex: prevSongIndex,
      );
      return gig.sets[currentSetIndex].songs[prevSongIndex];
    }

    for (var i = currentSetIndex - 1; i >= 0; i--) {
      if (gig.sets[i].songs.isNotEmpty) {
        final lastIndex = gig.sets[i].songs.length - 1;
        state = state.copyWith(activeSetIndex: i, activeSongIndex: lastIndex);
        return gig.sets[i].songs[lastIndex];
      }
    }

    return null;
  }
}

final gigsControllerProvider = NotifierProvider<GigsController, GigsState>(
  GigsController.new,
);
