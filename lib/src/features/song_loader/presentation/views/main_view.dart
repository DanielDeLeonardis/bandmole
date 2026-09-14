import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  ProviderSubscription<AsyncValue<Song?>>? _songLoaderSubscription;

  @override
  void initState() {
    super.initState();
    _songLoaderSubscription = ref.listenManual(
      songLoaderControllerProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }

        if (next.isLoading) {
          return;
        }

        if (next.hasError) {
          final message = next.error is UnsupportedError
              ? 'Song selection is not supported on this platform.'
              : 'Unable to load song.';
          _schedulePostFrame(() {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          });
          return;
        }

        final song = next.value;
        if (song == null) {
          if (previous?.isLoading == true) {
            _schedulePostFrame(() {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('No song selected.'),
                ),
              );
            });
          }
          return;
        }

        final songText = song.text;
        if (songText == null) {
          _schedulePostFrame(() {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Unable to load song.'),
              ),
            );
          });
          return;
        }

        if (!song.canTranspose) {
          ref.read(songTransposeProvider.notifier).resetTranspose();
        }

        if (song.isMalformed) {
          _schedulePostFrame(() {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Song contents has encoding issues. Please review.',
                ),
              ),
            );
          });
        }

        _schedulePostFrame(() {
          context.pushNamed(
            AppRoutes.lyrics,
            extra: song,
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _songLoaderSubscription?.close();
    super.dispose();
  }

  void _schedulePostFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Search'), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.pushNamed(AppRoutes.preferences);
          },
        )
      ]),
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            MaterialButton(
              color: Colors.white,
              textColor: Colors.black,
              child: const Text('Open song'),
              onPressed: () {
                ref.read(songLoaderControllerProvider.notifier).pickAndLoadSong();
              },
            ),
          ],
        ),
      ),
    );
  }
}
