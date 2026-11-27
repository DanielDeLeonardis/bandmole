import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/views/chordpro_editor_view.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/presentation/views/main_view.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        name: AppRoutes.main,
        path: '/',
        builder: (context, state) => const MainView(),
        routes: [
          GoRoute(
            name: AppRoutes.lyrics,
            path: 'lyrics',
            redirect: (context, state) {
              if (state.extra is Song) {
                return null;
              }

              return '/';
            },
            builder: (context, state) {
              final song = state.extra as Song;
              if (song.text != null) {
                final speed = song.file.isChordPro
                    ? ChordProDocument(song.text!).scrollSpeed
                    : 5;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(autoScrollableTextProvider.notifier)
                      .setScrollSpeed(speed);
                });
              }
              return SongView(
                text: song.text ?? '',
                canTranspose: song.canTranspose,
              );
            },
          ),
          GoRoute(
            name: AppRoutes.preferences,
            path: 'preferences',
            builder: (context, state) => const PreferenceView(),
          ),
          GoRoute(
            name: AppRoutes.editor,
            path: 'editor',
            redirect: (context, state) =>
                state.extra is ChordProEditorRequest ? null : '/',
            builder: (context, state) => ChordProEditorView(
              request: state.extra! as ChordProEditorRequest,
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
