import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/preferences/domain/app_themes.dart';
import 'package:bandmole/src/features/preferences/presentation/providers/app_themes_provider.dart';
import 'package:bandmole/src/navigation/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(appThemeProvider);
    final themeData = themeAsync.value ?? appThemeData[AppTheme.blueDark]!;

    final app = MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );

    // Screen-reader support is deferred to a later phase, and Flutter's
    // Windows accessibility bridge can fail ui::AXTree updates when dynamic
    // widgets (ReorderableListView, Tooltips, Overlays, Routes) mutate.
    // Excluding semantics at the root on Windows prevents AXTree errors
    // while keeping keyboard-only navigation and pointer interactions intact.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return ExcludeSemantics(child: app);
    }
    return app;
  }
}
