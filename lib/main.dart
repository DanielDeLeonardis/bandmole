import 'package:bandmole/models/app_themes.dart';
import 'package:bandmole/providers/app_themes_provider.dart';
import 'package:bandmole/views/main_view.dart';
import 'package:bandmole/views/preferences_view.dart';
import 'package:bandmole/views/song_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(appThemeProvider);
    final themeData =
        themeAsync.value ?? appThemeData[AppTheme.blueDark]!;

    return MaterialApp(
      title: 'BandMole',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const MainView(),
              settings: settings,
            );
          case '/lyrics':
            final songText = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (context) => SongView(text: songText),
              settings: settings,
            );
          case '/preferences':
            return MaterialPageRoute(
              builder: (context) => const PreferenceView(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const MainView(),
              settings: settings,
            );
        }
      },
    );
  }
}
