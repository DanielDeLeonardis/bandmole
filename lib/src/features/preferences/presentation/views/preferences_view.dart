import 'package:bandmole/src/features/preferences/presentation/providers/app_themes_provider.dart';
import 'package:flutter/material.dart';
import 'package:bandmole/src/features/preferences/domain/app_themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/l10n/app_localizations_fallback.dart';

class PreferenceView extends ConsumerWidget {
  const PreferenceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        EnglishAppLocalizations();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferences)),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: AppTheme.values.length,
        itemBuilder: (context, index) {
          final itemAppTheme = AppTheme.values[index];
          return Card(
            color: appThemeData[itemAppTheme]!.primaryColor,
            child: ListTile(
              title: Text(
                itemAppTheme.toString(),
                style: appThemeData[itemAppTheme]!.textTheme.bodyLarge,
              ),
              onTap: () {
                ref.read(appThemeProvider.notifier).setAppTheme(itemAppTheme);
              },
            ),
          );
        },
      ),
    );
  }
}
