// test/localization_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/providers/locale_provider.dart';
import 'package:katha_management/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default English locale', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.locale.languageCode, equals('en'));
      expect(provider.isUrdu, isFalse);
      expect(provider.currentLanguageDisplayName, equals('English'));
    });

    test('Switches to Urdu and persists in SharedPreferences', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.setLocale(const Locale('ur'));
      expect(provider.locale.languageCode, equals('ur'));
      expect(provider.isUrdu, isTrue);
      expect(provider.currentLanguageDisplayName, equals('اردو (Urdu)'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language_code'), equals('ur'));
    });

    test('Toggles between English and Urdu', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.toggleLanguage();
      expect(provider.locale.languageCode, equals('ur'));

      await provider.toggleLanguage();
      expect(provider.locale.languageCode, equals('en'));
    });

    test('Loads previously saved Urdu locale on startup', () async {
      SharedPreferences.setMockInitialValues({'app_language_code': 'ur'});
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.locale.languageCode, equals('ur'));
      expect(provider.isUrdu, isTrue);
    });
  });

  group('AppLocalizations & AppStrings Tests', () {
    test('Supported locales include English and Urdu', () {
      final locales = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toList();
      expect(locales, containsAll(['en', 'ur']));
    });

    test('Dynamic AppStrings updates when switching locale', () async {
      final enLoc = await AppLocalizations.delegate.load(const Locale('en'));
      final urLoc = await AppLocalizations.delegate.load(const Locale('ur'));

      // In English
      AppStrings.updateLocale(enLoc);
      expect(AppStrings.appTitle, equals('Katha Management'));
      expect(AppStrings.dashboardTitle, equals('Dashboard'));
      expect(AppStrings.todaysSales, equals("Today's Sales"));
      expect(
        AppStrings.openingBalanceLabel,
        equals('Previous Due (Opening Balance)'),
      );

      // In Urdu
      AppStrings.updateLocale(urLoc);
      expect(AppStrings.appTitle, equals('کھاتہ مینجمنٹ'));
      expect(AppStrings.dashboardTitle, equals('ڈیش بورڈ'));
      expect(AppStrings.todaysSales, equals('آج کی فروخت'));
      expect(
        AppStrings.openingBalanceLabel,
        equals('پچھلا بقایا (اوپننگ بیلنس)'),
      );
      expect(AppStrings.quickActionAddPayment, equals('ادائیگی درج کریں'));
    });

    test('ARB files have identical keys in en and ur', () {
      final enFile = File('lib/l10n/app_en.arb');
      final urFile = File('lib/l10n/app_ur.arb');

      expect(enFile.existsSync(), isTrue);
      expect(urFile.existsSync(), isTrue);

      final Map<String, dynamic> enJson = jsonDecode(enFile.readAsStringSync());
      final Map<String, dynamic> urJson = jsonDecode(urFile.readAsStringSync());

      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      final urKeys = urJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInUrdu = enKeys.difference(urKeys);
      final missingInEnglish = urKeys.difference(enKeys);

      expect(
        missingInUrdu,
        isEmpty,
        reason: 'Keys present in English but missing in Urdu: $missingInUrdu',
      );
      expect(
        missingInEnglish,
        isEmpty,
        reason:
            'Keys present in Urdu but missing in English: $missingInEnglish',
      );
    });
  });

  group('Widget Directionality & RTL Tests', () {
    testWidgets('App renders LTR for English and RTL for Urdu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              final direction = Directionality.of(context);
              return Scaffold(body: Text('Direction: $direction'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direction: TextDirection.ltr'), findsOneWidget);

      // Re-pump with Urdu
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ur'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              final direction = Directionality.of(context);
              return Scaffold(body: Text('Direction: $direction'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direction: TextDirection.rtl'), findsOneWidget);
    });
  });
}
