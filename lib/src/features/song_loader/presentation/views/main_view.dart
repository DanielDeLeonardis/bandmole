import 'package:bandmole/src/features/song_loader/presentation/providers/song_repository_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainView extends ConsumerWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songRepository = ref.read(songRepositoryProvider);

    Future<void> openSong() async {
      try {
        final selectedFile = await songRepository.pickSongFile();
        if (!context.mounted) {
          return;
        }

        if (selectedFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No song selected.'),
            ),
          );
          return;
        }

        final song = await songRepository.loadSong(selectedFile);
        if (!context.mounted) {
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

        if (song.text == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to load song. Check encoding is UTF-8.',
              ),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongView(
              text: song.text!,
            ),
          ),
        );
      } on UnsupportedError catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song selection is not supported on this platform.'),
          ),
        );
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load song.'),
          ),
        );
      }
    }

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
              onPressed: openSong,
            ),
          ],
        ),
      ),
    );
  }
}
