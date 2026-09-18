import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SongLoaderEffectsListener extends ConsumerWidget {
  const SongLoaderEffectsListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Song?>>(
      songLoaderControllerProvider,
      (previous, next) {
        if (next.isLoading) {
          return;
        }

        if (next.hasError) {
          final message = next.error is UnsupportedError
              ? 'Song selection is not supported on this platform.'
              : 'Unable to load song.';
          _schedulePostFrame(context, () {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(message)),
            );
          });
          return;
        }

        final song = next.value;
        if (song == null) {
          if (previous?.isLoading == true) {
            _schedulePostFrame(context, () {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('No song selected.')),
              );
            });
          }
          return;
        }

        if (song.text == null) {
          _schedulePostFrame(context, () {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Unable to load song.')),
            );
          });
          return;
        }

        if (!song.canTranspose) {
          ref.read(songTransposeProvider.notifier).resetTranspose();
        }

        if (song.isMalformed) {
          _schedulePostFrame(context, () {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Song contents has encoding issues. Please review.'),
              ),
            );
          });
        }

        _schedulePostFrame(context, () {
          context.pushNamed(
            AppRoutes.lyrics,
            extra: song,
          );
        });
      },
    );

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
