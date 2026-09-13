import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainView extends ConsumerWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(songLoaderControllerProvider, (previous, next) {
      if (previous == null || !context.mounted) {
        return;
      }

      if (next.isLoading) {
        return;
      }

      if (next.hasError) {
        final message = next.error is UnsupportedError
            ? 'Song selection is not supported on this platform.'
            : 'Unable to load song.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
        return;
      }

      final song = next.value;
      if (song == null) {
        return;
      }

      if (song.text == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load song.'),
          ),
        );
        return;
      }

      if (song.isMalformed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Song contents has encoding issues. Please review.',
            ),
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongView(
            text: song.text!,
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Song Search'), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PreferenceView(),
              ),
            );
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
                ref
                    .read(songLoaderControllerProvider.notifier)
                    .pickAndLoadSong();
              },
            ),
          ],
        ),
      ),
    );
  }
}
