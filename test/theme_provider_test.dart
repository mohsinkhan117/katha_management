// test/theme_provider_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/providers/locale_provider.dart';
import 'package:katha_management/core/providers/theme_provider.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/ui/settings_view/settings_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider Unit Tests', () {
    test('Initializes with default Light theme mode', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isDarkMode, isFalse);
      expect(provider.currentThemeDisplayName, equals('Light Mode'));
    });

    test('Switches to Dark theme mode and persists in SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
      expect(provider.currentThemeDisplayName, equals('Dark Mode'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test('Toggles between Light and Dark mode', () async {
      final provider = ThemeProvider();
      expect(provider.isDarkMode, isFalse);

      await provider.toggleTheme();
      expect(provider.isDarkMode, isTrue);

      await provider.toggleTheme();
      expect(provider.isDarkMode, isFalse);
    });

    test('Loads previously saved Dark theme mode on startup', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final provider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
    });
  });

  group('SettingsView Theme Switcher Widget Tests', () {
    testWidgets('Renders Theme switch card in SettingsView and toggles theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final themeProvider = ThemeProvider();
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Theme Section Header & ListTile title
      expect(find.text(AppStrings.themeSectionTitle), findsAtLeastNWidgets(1));

      // Verify Light Mode is displayed initially
      expect(find.text(AppStrings.themeLightMode), findsOneWidget);

      // Verify Theme Switch is present
      final switchFinder = find.byKey(const Key('theme_switch'));
      expect(switchFinder, findsOneWidget);

      final initialSwitch = tester.widget<Switch>(switchFinder);
      expect(initialSwitch.value, isFalse);

      // Tap the switch to toggle to Dark mode
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, isTrue);
      expect(find.text(AppStrings.themeDarkMode), findsOneWidget);

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isTrue);
    });
  });
}
