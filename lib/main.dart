import 'dart:async';

import 'package:flutter/material.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/ui/dashboard/dashboard_view.dart';
import 'package:katha_management/ui/dashboard/dashboard_view_model.dart';
import 'package:katha_management/ui/new_sale/new_sale_view_model.dart';
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
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => NewSaleViewModel()),
      ],
      child: MaterialApp(
        title: 'Katha_management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: DashboardView.routeName,
        onGenerateRoute: RouterGenerator.onGenerateRoute,
      ),
    );
  }
}
