import 'package:bandmole/src/features/song_loader/presentation/providers/song_loader_controller.dart';
import 'package:bandmole/src/features/song_loader/presentation/widgets/song_loader_effects_listener.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainView extends ConsumerWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Search'), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.pushNamed(AppRoutes.preferences);
          },
        )
      ]),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SongLoaderEffectsListener(),
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
