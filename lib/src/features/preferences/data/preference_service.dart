import 'package:bandmole/src/features/preferences/domain/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppTheme> getThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final themePref = prefs.getString('themeData') ?? AppTheme.blueDark.name;
  return AppTheme.values.byName(themePref);
}

Future<void> setThemePreference(AppTheme appTheme) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('themeData', appTheme.name);
}
