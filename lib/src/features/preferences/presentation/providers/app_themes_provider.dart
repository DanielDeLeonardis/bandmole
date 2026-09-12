import 'package:bandmole/src/features/preferences/domain/app_themes.dart';
import 'package:bandmole/src/features/preferences/data/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppThemeNotifier extends AsyncNotifier<ThemeData> {
  @override
  Future<ThemeData> build() async {
    final appTheme = await getThemePreference();
    return appThemeData[appTheme]!;
  }

  Future<void> setAppTheme(AppTheme appTheme) async {
    state = AsyncValue.data(appThemeData[appTheme]!);
    await setThemePreference(appTheme);
  }
}

final appThemeProvider =
    AsyncNotifierProvider<AppThemeNotifier, ThemeData>(
  AppThemeNotifier.new,
);
