import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/presentation/views/main_view.dart';
import 'package:bandmole/src/navigation/app_routes.dart';
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
      ),
      GoRoute(
        name: AppRoutes.lyrics,
        path: '/lyrics',
        builder: (context, state) {
          final song = state.extra as Song?;
          return SongView(
            text: song?.text ?? '',
            canTranspose: song?.canTranspose ?? false,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.preferences,
        path: '/preferences',
        builder: (context, state) => const PreferenceView(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
