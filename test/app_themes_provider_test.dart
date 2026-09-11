import 'package:bandmole/models/app_themes.dart';
import 'package:bandmole/providers/app_themes_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('appThemeProvider loads default theme blueDark initially', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final themeData = await container.read(appThemeProvider.future);
    expect(themeData, equals(appThemeData[AppTheme.blueDark]));
  });

  test('setAppTheme updates state and persists theme setting', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appThemeProvider.future);
    await container
        .read(appThemeProvider.notifier)
        .setAppTheme(AppTheme.greenLight);

    final updatedTheme = container.read(appThemeProvider).value;
    expect(updatedTheme, equals(appThemeData[AppTheme.greenLight]));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeData'), equals(AppTheme.greenLight.name));
  });
}
