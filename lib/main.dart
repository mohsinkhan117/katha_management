import 'dart:async';

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return
    //  MultiProvider(
    //   providers: [
    //     // ChangeNotifierProvider(create: (_) => SplashViewModel()),
    //   ],
    //   child:
    MaterialApp(
      title: 'Invoice-Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
