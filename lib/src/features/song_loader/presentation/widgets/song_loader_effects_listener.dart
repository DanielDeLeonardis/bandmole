import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/l10n/app_localizations_fallback.dart';

class SongLoaderEffectsListener extends ConsumerWidget {
  const SongLoaderEffectsListener({super.key, required this.onSongLoaded});

  final ValueChanged<Song> onSongLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Song?>>(songLoaderControllerProvider, (
      previous,
      next,
    ) {
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations) ??
          EnglishAppLocalizations();
      if (next.isLoading) {
        return;
      }

      if (next.hasError) {
        final message = next.error is UnsupportedError
            ? l10n.songSelectionUnsupported
            : l10n.unableToLoadSong;
        _schedulePostFrame(context, () {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(message)));
        });
        return;
      }

      final song = next.value;
      if (song == null) {
        if (previous?.isLoading == true) {
          _schedulePostFrame(context, () {
            ScaffoldMessenger.maybeOf(context)
                ?.showSnackBar(SnackBar(content: Text(l10n.noSongSelected)));
          });
        }
        return;
      }

      if (song.text == null) {
        _schedulePostFrame(context, () {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(l10n.unableToLoadSong)));
        });
        return;
      }

      if (!song.canTranspose) {
        ref.read(songTransposeProvider.notifier).resetTranspose();
      }

      if (song.isMalformed) {
        _schedulePostFrame(context, () {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(l10n.encodingIssues)));
        });
      }

      _schedulePostFrame(context, () {
        onSongLoaded(song);
      });
    });

    return const SizedBox.shrink();
  }

  void _schedulePostFrame(BuildContext context, VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      action();
    });
  }
}
