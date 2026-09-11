import 'package:bandmole/providers/app_themes_provider.dart';
import 'package:flutter/material.dart';
import 'package:bandmole/models/app_themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferenceView extends ConsumerWidget {
  const PreferenceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: AppTheme.values.length,
        itemBuilder: (context, index) {
          // Enums expose their values as a list - perfect for ListView
          // Store the theme for the current ListView item
          final itemAppTheme = AppTheme.values[index];
          return Card(
            // Style the cards with the to-be-selected theme colors
            color: appThemeData[itemAppTheme]!.primaryColor,
            child: ListTile(
              title: Text(
                itemAppTheme.toString(),
                // To show light text with the dark variants...
                style: appThemeData[itemAppTheme]!.textTheme.bodyLarge,
              ),
              onTap: () {
                ref
                    .read(appThemeProvider.notifier)
                    .setAppTheme(itemAppTheme);
              },
            ),
          );
        },
      ),
    );
  }
}
