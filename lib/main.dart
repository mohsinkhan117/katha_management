// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/providers/locale_provider.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/l10n/app_localizations.dart';
import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
import 'package:katha_management/ui/navigation_bar/gnav_bar_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return MaterialApp(
          title: 'Katha Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) {
            // Synchronize active AppStrings with the current AppLocalizations
            AppStrings.updateLocale(AppLocalizations.of(context));
            return child!;
          },
          home: const GnavBar(),
          onGenerateRoute: RouterGenerator.onGenerateRoute,
        );
      },
    );
  }
}
