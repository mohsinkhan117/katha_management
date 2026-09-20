// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:katha_management/core/routes/routes_generator.dart';
// import 'package:katha_management/core/theme/app_themes/themes.dart';
// import 'package:katha_management/ui/customers/customers_view_model.dart';
// import 'package:katha_management/ui/dashboard/dashboard_view.dart';
// import 'package:katha_management/ui/dashboard/dashboard_view_model.dart';
// import 'package:katha_management/ui/features/add_party/add_party_view_model.dart';
// import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
// import 'package:katha_management/ui/features/new_order/new_order_view_model.dart';
// import 'package:katha_management/ui/features/new_sale/new_sale_view_model.dart';
// import 'package:katha_management/ui/navigation_bar/gnav_bar_view.dart';
// import 'package:katha_management/ui/navigation_bar/gnav_bar_view_model.dart';
// import 'package:katha_management/ui/navigation_bar/navigattion_bar_view.dart';
// import 'package:katha_management/ui/orders/order_view_model.dart';
// import 'package:provider/provider.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => DashboardViewmodel()),
//         ChangeNotifierProvider(create: (_) => OrderViewModel()),
//         ChangeNotifierProvider(create: (_) => NewSaleViewModel()),
//         ChangeNotifierProvider(create: (_) => NewOrderViewModel()),
//         ChangeNotifierProvider(create: (_) => PaymentViewModel()),
//         ChangeNotifierProvider(create: (_) => AddPartyViewModel()),
//         ChangeNotifierProvider(create: (_) => CustomersViewModel()),
//         ChangeNotifierProvider(create: (_) => GnavBarViewModel()),
//       ],
//       child: MaterialApp(
//         title: 'Katha_management',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.lightTheme,
//         darkTheme: AppTheme.darkTheme,
//         themeMode: ThemeMode.light,
//         home: GnavBar(),
//         initialRoute: DashboardView.routeName,
//         onGenerateRoute: RouterGenerator.onGenerateRoute,
//       ),
//     );
//   }
// }

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/routes/routes_generator.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/ui/navigation_bar/gnav_bar_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No MultiProvider here: every screen-scoped ViewModel
    // (NewSaleViewModel, NewOrderViewModel, PaymentViewModel,
    // AddPartyViewModel, CustomersViewModel, GnavBarViewModel, ...)
    // is created locally by its own View. Declaring them again here
    // would just be dead weight — Provider always resolves to the
    // nearest ancestor, so these screens would never actually see an
    // app-wide instance even if one existed.
    //
    // If a genuinely app-wide concern shows up later (a signed-in
    // user, a business profile, a theme toggle the whole app reacts
    // to), that's when MultiProvider belongs back here — for state
    // that outlives any single screen, not for a screen's own form
    // state.
    return MaterialApp(
      title: 'Katha Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      // GnavBar is the whole app shell (tabs + bottom nav) and is the
      // only thing that should ever be `home`. Screens reached by
      // pushing on top of it (Party History, Add Party, New Sale,
      // etc.) go through `onGenerateRoute` instead — `initialRoute`
      // is not needed and conflicts with `home` if set to anything
      // other than '/'.
      home: const GnavBar(),
      onGenerateRoute: RouterGenerator.onGenerateRoute,
    );
  }
}
