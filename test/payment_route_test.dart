// test/payment_route_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:katha_management/core/providers/locale_provider.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/l10n/app_localizations.dart';
import 'package:katha_management/ui/features/add_payment/payment_view.dart';
import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentView Route & Provider Tests', () {
    testWidgets('PaymentView mounts and provides PaymentViewModel cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => PaymentViewModel()),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const PaymentView(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(PaymentView), findsOneWidget);
    });

    testWidgets(
      'Navigating to /payment_view route succeeds without provider error',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LocaleProvider()),
              ChangeNotifierProvider(create: (_) => PaymentViewModel()),
            ],
            child: MaterialApp(
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              initialRoute: '/',
              onGenerateRoute: RouterGenerator.onGenerateRoute,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, PaymentView.routeName);
                      },
                      child: const Text('Open Payment'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Payment'));
        await tester.pumpAndSettle();

        expect(find.byType(PaymentView), findsOneWidget);
      },
    );
  });
}
