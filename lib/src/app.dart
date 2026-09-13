import 'package:bandmole/src/features/preferences/domain/app_themes.dart';
import 'package:bandmole/src/features/preferences/presentation/providers/app_themes_provider.dart';
import 'package:bandmole/src/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(appThemeProvider);
    final themeData = themeAsync.value ?? appThemeData[AppTheme.blueDark]!;

    return MaterialApp.router(
      title: 'BandMole',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
