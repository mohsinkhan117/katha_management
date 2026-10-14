// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/providers/locale_provider.dart';
import 'package:katha_management/core/providers/theme_provider.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/l10n/app_localizations.dart';
import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
import 'package:katha_management/core/services/distributor_auth_service.dart';
import 'package:katha_management/ui/distributer/auth/distributor_auth_view.dart';
import 'package:katha_management/ui/distributer/navigation_bar/gnav_bar_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isClaimed = await DistributorAuthService.isTokenClaimed();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
      ],
      child: MyApp(isClaimed: isClaimed),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isClaimed;
  const MyApp({super.key, this.isClaimed = true});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, _) {
        return MaterialApp(
          title: 'Katha Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) {
            // Synchronize active AppStrings with the current AppLocalizations
            AppStrings.updateLocale(AppLocalizations.of(context));
            return child!;
          },
          home: isClaimed ? const GnavBar() : const DistributorAuthView(),
          onGenerateRoute: RouterGenerator.onGenerateRoute,
        );
      },
    );
  }
}
