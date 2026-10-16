import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_repository.dart';
import 'package:bandmole/src/features/song_groups/domain/gig_song.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/domain/song_set.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gig_repository_provider.dart';
import 'package:bandmole/src/features/song_groups/presentation/providers/gigs_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GigsController', () {
    test('creates normalized unique gigs in alphabetical order', () async {
      final harness = _ControllerHarness();
      addTearDown(harness.dispose);
      await harness.controller.loadGigs();

      final zulu = await harness.controller.createGig(title: ' Zulu\tShow ');
      final alpha = await harness.controller.createGig(title: 'Alpha Show');

      expect(zulu.title, 'Zulu Show');
      expect(alpha.sets, hasLength(1));
      expect(alpha.sets.single.songs, isEmpty);
      expect(
        harness.container
            .read(gigsControllerProvider)
            .gigs
            .map((gig) => gig.title),
        ['Alpha Show', 'Zulu Show'],
      );
      await expectLater(
        harness.controller.createGig(title: ' alpha   show '),
        throwsA(isA<SongGroupException>()),
      );
      await expectLater(
        harness.controller.createGig(title: ' \t '),
        throwsA(isA<SongGroupException>()),
      );
    });

    test('enforces normalized set titles and maintains one set', () async {
      final harness = _ControllerHarness();
      addTearDown(harness.dispose);
      await harness.controller.loadGigs();
      final gig = await harness.controller.createGig(title: 'Friday');

      await harness.controller.addSet(gig.id, '  Encore   Set ');
      expect(
        harness.container.read(gigsControllerProvider).selectedSet?.title,
        'Encore Set',
      );
      await expectLater(
        harness.controller.addSet(gig.id, ' encore set '),
        throwsA(isA<SongGroupException>()),
      );

      final updated = harness.container
          .read(gigsControllerProvider)
          .selectedGig!;
      await harness.controller.deleteSet(updated.id, updated.sets.last.id);
      await expectLater(
        harness.controller.deleteSet(updated.id, updated.sets.first.id),
        throwsA(isA<SongGroupException>()),
      );
      expect(
        harness.container.read(gigsControllerProvider).selectedGig!.sets,
        hasLength(1),
      );
    });

    test(
      'recovers the selected gig and reports repository load failures',
      () async {
        final firstGig = Gig.create(id: 'gig-1', title: 'First');
        final secondGig = Gig.create(id: 'gig-2', title: 'Second');
        final harness = _ControllerHarness(initialGigs: [firstGig, secondGig]);
        addTearDown(harness.dispose);
        harness.controller.selectGig('removed-gig');

        await harness.controller.loadGigs();

        expect(
          harness.container.read(gigsControllerProvider).selectedGigId,
          'gig-1',
        );
        expect(
          harness.container
              .read(gigsControllerProvider)
              .gigs
              .map((gig) => gig.id),
          ['gig-1', 'gig-2'],
        );

        harness.repository.loadError = StateError('Storage unavailable');
        await harness.controller.loadGigs();
        final failedState = harness.container.read(gigsControllerProvider);
        expect(failedState.isLoading, isFalse);
        expect(failedState.errorMessage, contains('Storage unavailable'));
      },
    );

    test(
      'rejects duplicate songs across sets and relinks broken songs',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);
        await harness.controller.loadGigs();
        final gig = await harness.controller.createGig(
          title: 'Festival',
          sets: const [
            SongSet(id: 'set-1', title: 'First'),
            SongSet(id: 'set-2', title: 'Second'),
          ],
        );

        await harness.controller.addSongToSet(
          gig.id,
          'set-1',
          r'folder\first.cho',
          fileExistsCheck: (_) => true,
        );
        await expectLater(
          harness.controller.addSongToSet(
            gig.id,
            'set-2',
            'folder/FIRST.cho',
            fileExistsCheck: (_) => true,
          ),
          throwsA(isA<SongGroupException>()),
        );
        await harness.controller.addSongToSet(
          gig.id,
          'set-2',
          'missing-song.txt',
          fileExistsCheck: (_) => false,
        );

        var updatedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        final brokenSong = updatedGig.sets[1].songs.single;
        expect(
          updatedGig.sets[0].songs.single.relativePath,
          'folder/first.cho',
        );
        expect(brokenSong.isBroken, isTrue);
        expect(brokenSong.brokenReason, contains('missing-song.txt'));
        await expectLater(
          harness.controller.relinkSong(
            gig.id,
            'set-2',
            brokenSong.id,
            'replacement/song.pdf',
          ),
          throwsA(isA<SongGroupException>()),
        );

        await harness.controller.relinkSong(
          gig.id,
          'set-2',
          brokenSong.id,
          'replacement/song.txt',
          fileExistsCheck: (path) => path == 'replacement/song.txt',
        );
        updatedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        expect(updatedGig.sets[1].songs.single.isBroken, isFalse);
        expect(updatedGig.sets[1].songs.single.brokenReason, isNull);

        await harness.controller.removeSongFromSet(
          gig.id,
          'set-2',
          brokenSong.id,
        );
        expect(
          harness.container
              .read(gigsControllerProvider)
              .selectedGig!
              .allSongPaths,
          ['folder/first.cho'],
        );
      },
    );

    test(
      'marks unavailable loaded songs broken without blocking edits',
      () async {
        final gig = _gigWithSets([
          SongSet(
            id: 'set-1',
            title: 'First',
            songs: const [GigSong(id: 'song-1', relativePath: 'gone/song.txt')],
          ),
        ]);
        final harness = _ControllerHarness(initialGigs: [gig]);
        addTearDown(harness.dispose);

        await harness.controller.loadGigs(availableRelativePaths: <String>{});

        final loadedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        expect(loadedGig.sets.single.songs.single.isBroken, isTrue);
        await harness.controller.renameSet(gig.id, 'set-1', 'Renamed');
        expect(
          harness.container
              .read(gigsControllerProvider)
              .selectedGig!
              .sets
              .single
              .title,
          'Renamed',
        );
      },
    );

    test(
      'renaming a set rejects duplicates after whitespace normalization',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);
        await harness.controller.loadGigs();
        final gig = await harness.controller.createGig(title: 'Weekend Set');
        await harness.controller.addSet(gig.id, 'Main Set');

        await expectLater(
          harness.controller.renameSet(
            gig.id,
            gig.sets.first.id,
            '  main\tset  ',
          ),
          throwsA(isA<SongGroupException>()),
        );

        final updatedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        expect(updatedGig.sets.map((set) => set.title), ['Set 1', 'Main Set']);
      },
    );

    test('ignores invalid entity and reorder commands', () async {
      final gig = _gigWithSets([
        _setWithSong('set-1', 'First', 'song-1', 'one.txt'),
        _setWithSong('set-2', 'Second', 'song-2', 'two.txt'),
      ]);
      final harness = _ControllerHarness(initialGigs: [gig]);
      addTearDown(harness.dispose);
      await harness.controller.loadGigs(
        availableRelativePaths: {'one.txt', 'two.txt'},
      );

      await harness.controller.updateGig(gig.copyWith(id: 'missing-gig'));
      await harness.controller.addSet('missing-gig', 'Ignored');
      await harness.controller.renameSet('missing-gig', 'set-1', 'Ignored');
      await harness.controller.renameSet(gig.id, 'missing-set', 'Ignored');
      await harness.controller.deleteSet('missing-gig', 'set-1');
      await harness.controller.reorderSets('missing-gig', 0, 1);
      await harness.controller.reorderSets(gig.id, -1, 0);
      await harness.controller.reorderSets(gig.id, 0, gig.sets.length + 1);
      await harness.controller.reorderSets(gig.id, 0, 0);
      await harness.controller.removeSongFromSet(
        'missing-gig',
        'set-1',
        'song-1',
      );
      await harness.controller.reorderSongsInSet('missing-gig', 'set-1', 0, 1);
      await harness.controller.reorderSongsInSet(gig.id, 'missing-set', 0, 1);
      await harness.controller.reorderSongsInSet(gig.id, 'set-1', -1, 0);
      await harness.controller.reorderSongsInSet(gig.id, 'set-1', 0, 2);
      await harness.controller.moveSong('missing-gig', 'set-1', 0, 1);
      await harness.controller.moveSong(gig.id, 'missing-set', 0, 1);
      await harness.controller.moveSong(gig.id, 'set-1', -1, 1);
      await harness.controller.moveSong(gig.id, 'set-1', 0, -1);
      await harness.controller.relinkSong(
        'missing-gig',
        'set-1',
        'song-1',
        'replacement.txt',
      );
      await harness.controller.relinkSong(
        gig.id,
        'set-2',
        'song-1',
        'replacement.txt',
      );

      final state = harness.container.read(gigsControllerProvider);
      expect(state.selectedGig, gig);
      expect(state.selectedGig!.sets, gig.sets);
      expect(harness.repository.gigs, [gig]);
    });

    test('closing a set clears the active set context', () async {
      final gig = _gigWithSets([
        _setWithSong('set-1', 'First', 'song-1', 'one.txt'),
      ]);
      final harness = _ControllerHarness(initialGigs: [gig]);
      addTearDown(harness.dispose);
      await harness.controller.loadGigs(availableRelativePaths: {'one.txt'});

      harness.controller.selectGig(gig.id);
      harness.controller.selectSong(0, 0);

      expect(
        harness.container.read(gigsControllerProvider).selectedSet?.id,
        'set-1',
      );
      expect(
        harness.container.read(gigsControllerProvider).activeSong?.id,
        'song-1',
      );

      harness.controller.closeSet();

      final state = harness.container.read(gigsControllerProvider);
      expect(state.selectedSetId, isNull);
      expect(state.selectedSet, isNull);
      expect(state.isSetOpen, isFalse);
      expect(state.activeSetIndex, isNull);
      expect(state.activeSongIndex, isNull);
      expect(state.activeSong, isNull);
    });

    test('selecting a gig song opens its set', () async {
      final gig = _gigWithSets([
        const SongSet(id: 'set-1', title: 'First'),
        _setWithSong('set-2', 'Second', 'song-1', 'one.txt'),
      ]);
      final harness = _ControllerHarness(initialGigs: [gig]);
      addTearDown(harness.dispose);
      await harness.controller.loadGigs(availableRelativePaths: {'one.txt'});

      harness.controller.selectSong(1, 0);

      final state = harness.container.read(gigsControllerProvider);
      expect(state.selectedSetId, 'set-2');
      expect(state.selectedSet?.id, 'set-2');
      expect(state.isSetOpen, isTrue);
      expect(state.activeSong?.id, 'song-1');
    });

    test('ignores commands for missing entities and invalid indices', () async {
      final gig = _gigWithSets([
        SongSet(
          id: 'set-1',
          title: 'First',
          songs: const [
            GigSong(id: 'song-1', relativePath: 'one.txt'),
            GigSong(id: 'song-2', relativePath: 'two.txt'),
          ],
        ),
        _setWithSong('set-2', 'Second', 'song-3', 'three.txt'),
      ]);
      final harness = _ControllerHarness(initialGigs: [gig]);
      addTearDown(harness.dispose);
      await harness.controller.loadGigs(
        availableRelativePaths: {'one.txt', 'two.txt', 'three.txt'},
      );
      harness.controller.selectGig(gig.id);

      await harness.controller.updateGig(gig.copyWith(id: 'missing-gig'));
      await harness.controller.addSet('missing-gig', 'Ignored');
      await harness.controller.renameSet('missing-gig', 'set-1', 'Ignored');
      await harness.controller.renameSet(gig.id, 'missing-set', 'Ignored');
      await harness.controller.deleteSet('missing-gig', 'set-1');
      await harness.controller.reorderSets('missing-gig', 0, 1);
      await harness.controller.reorderSets(gig.id, -1, 0);
      await harness.controller.reorderSets(gig.id, 0, gig.sets.length + 1);
      await harness.controller.addSongToSet(
        'missing-gig',
        'set-1',
        'ignored.txt',
      );
      await expectLater(
        harness.controller.addSongToSet(gig.id, 'missing-set', 'ignored.txt'),
        throwsA(isA<SongGroupException>()),
      );
      await harness.controller.removeSongFromSet(
        'missing-gig',
        'set-1',
        'song-1',
      );
      await harness.controller.reorderSongsInSet('missing-gig', 'set-1', 0, 1);
      await harness.controller.reorderSongsInSet(gig.id, 'missing-set', 0, 1);
      await harness.controller.reorderSongsInSet(gig.id, 'set-1', -1, 0);
      await harness.controller.reorderSongsInSet(gig.id, 'set-1', 0, 2);
      await harness.controller.moveSong('missing-gig', 'set-1', 0, 1);
      await harness.controller.moveSong(gig.id, 'missing-set', 0, 1);
      await harness.controller.moveSong(gig.id, 'set-1', -1, 1);
      await harness.controller.moveSong(gig.id, 'set-1', 0, -1);
      await harness.controller.relinkSong(
        'missing-gig',
        'set-1',
        'song-1',
        'replacement.txt',
      );
      await harness.controller.relinkSong(
        gig.id,
        'set-1',
        'missing-song',
        'replacement.txt',
      );
      harness.controller.selectSong(-1, 0);
      harness.controller.selectSong(0, -1);
      harness.controller.selectSong(0, 2);
      harness.controller.clearActiveSong();

      expect(harness.controller.navigateToNextSong(), isNull);
      expect(harness.controller.navigateToPreviousSong(), isNull);
      expect(harness.container.read(gigsControllerProvider).gigs, [gig]);

      harness.controller.selectGig(null);
      expect(
        harness.container.read(gigsControllerProvider).selectedGig,
        isNull,
      );
    });

    test(
      'navigates across empty sets and does not wrap at gig boundaries',
      () async {
        final gig = _gigWithSets([
          _setWithSong('set-1', 'First', 'song-1', 'one.txt'),
          const SongSet(id: 'set-empty', title: 'Break'),
          _setWithSong('set-2', 'Second', 'song-2', 'two.txt'),
          _setWithSong('set-3', 'Third', 'song-3', 'three.txt'),
        ]);
        final harness = _ControllerHarness(initialGigs: [gig]);
        addTearDown(harness.dispose);
        await harness.controller.loadGigs(
          availableRelativePaths: {'one.txt', 'two.txt', 'three.txt'},
        );
        harness.controller.selectSong(0, 0);

        expect(harness.controller.navigateToNextSong()?.id, 'song-2');
        expect(
          harness.container.read(gigsControllerProvider).activeSetIndex,
          2,
        );
        expect(harness.controller.navigateToPreviousSong()?.id, 'song-1');
        expect(harness.controller.navigateToPreviousSong(), isNull);

        harness.controller.selectSong(3, 0);
        expect(harness.controller.navigateToNextSong(), isNull);
      },
    );

    test(
      'set and song reorders persist and keep the active song selected',
      () async {
        final gig = _gigWithSets([
          _setWithSong('set-1', 'First', 'song-1', 'one.txt'),
          SongSet(
            id: 'set-2',
            title: 'Second',
            songs: const [
              GigSong(id: 'song-2', relativePath: 'two.txt'),
              GigSong(id: 'song-3', relativePath: 'three.txt'),
            ],
          ),
          _setWithSong('set-3', 'Third', 'song-4', 'four.txt'),
        ]);
        final harness = _ControllerHarness(initialGigs: [gig]);
        addTearDown(harness.dispose);
        await harness.controller.loadGigs(
          availableRelativePaths: {
            'one.txt',
            'two.txt',
            'three.txt',
            'four.txt',
          },
        );
        harness.controller.selectSong(1, 0);

        await harness.controller.reorderSets(gig.id, 1, 3);
        var updatedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        expect(updatedGig.sets.map((set) => set.id), [
          'set-1',
          'set-3',
          'set-2',
        ]);
        expect(updatedGig.getSetNumber(updatedGig.sets.last), 3);
        expect(
          harness.container.read(gigsControllerProvider).activeSetIndex,
          2,
        );

        await harness.controller.reorderSongsInSet(gig.id, 'set-2', 0, 1);
        updatedGig = harness.container
            .read(gigsControllerProvider)
            .selectedGig!;
        expect(updatedGig.sets.last.songs.map((song) => song.id), [
          'song-3',
          'song-2',
        ]);
        expect(
          harness.container.read(gigsControllerProvider).activeSongIndex,
          1,
        );
        expect(
          harness.container.read(gigsControllerProvider).activeSong?.id,
          'song-2',
        );
        expect(harness.repository.gigs.single, updatedGig);
      },
    );

    test('gig optional metadata can be cleared with copyWith', () {
      final gig = Gig.create(
        id: 'gig-1',
        title: 'Show',
        date: DateTime(2026, 10, 2),
        venue: 'Hall',
        notes: 'Notes',
        startTime: '19:30',
      );

      final updated = gig.copyWith(
        clearDate: true,
        clearVenue: true,
        clearNotes: true,
        clearStartTime: true,
      );

      expect(updated.date, isNull);
      expect(updated.venue, isNull);
      expect(updated.notes, isNull);
      expect(updated.startTime, isNull);
    });
  });
}

Gig _gigWithSets(List<SongSet> sets) =>
    Gig(id: 'gig-1', title: 'Test Gig', sets: sets);

SongSet _setWithSong(
  String setId,
  String title,
  String songId,
  String relativePath,
) => SongSet(
  id: setId,
  title: title,
  songs: [GigSong(id: songId, relativePath: relativePath)],
);

class _ControllerHarness {
  _ControllerHarness({List<Gig> initialGigs = const []}) {
    repository = _MemoryGigRepository(initialGigs);
    container = ProviderContainer(
      overrides: [gigRepositoryProvider.overrideWithValue(repository)],
    );
  }

  late final _MemoryGigRepository repository;
  late final ProviderContainer container;

  GigsController get controller =>
      container.read(gigsControllerProvider.notifier);

  void dispose() => container.dispose();
}

class _MemoryGigRepository implements GigRepository {
  _MemoryGigRepository(List<Gig> gigs) : gigs = List<Gig>.of(gigs);

  final List<Gig> gigs;
  Object? loadError;

  @override
  Future<List<Gig>> loadGigs() async {
    if (loadError != null) throw loadError!;
    return List<Gig>.of(gigs);
  }

  @override
  Future<void> saveGig(Gig gig) async {
    final index = gigs.indexWhere((existing) => existing.id == gig.id);
    if (index < 0) {
      gigs.add(gig);
    } else {
      gigs[index] = gig;
    }
  }

  @override
  Future<void> deleteGig(String gigId) async {
    gigs.removeWhere((gig) => gig.id == gigId);
  }
}
