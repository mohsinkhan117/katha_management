import 'dart:async';

import 'package:flutter/material.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/ui/customers/customers_view_model.dart';
import 'package:katha_management/ui/dashboard/dashboard_view_model.dart';
import 'package:katha_management/ui/features/add_party/add_party_view_model.dart';
import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
import 'package:katha_management/ui/features/new_order/new_order_view_model.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view_model.dart';
import 'package:katha_management/ui/navigation_bar/navigattion_bar_view.dart';
import 'package:katha_management/ui/orders/order_view_model.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardViewmodel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProvider(create: (_) => NewSaleViewModel()),
        ChangeNotifierProvider(create: (_) => NewOrderViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider(create: (_) => AddPartyViewModel()),
        ChangeNotifierProvider(create: (_) => CustomersViewModel()),
      ],
      child: MaterialApp(
        title: 'Katha_management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: NavigationBarView.routeName,
        onGenerateRoute: RouterGenerator.onGenerateRoute,
      ),
    );
  }
}
