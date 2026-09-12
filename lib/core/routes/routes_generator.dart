// lib/core/routes/routes_generator.dart

import 'package:flutter/material.dart';

class RouterGenerator {
  static Route onGenerateRoute(RouteSettings settings) {
    debugPrint("Navigating to: ${settings.name}");

    switch (settings.name) {
      // ======================================================
      // Core
      // ======================================================
      // case HomeView.routeName:
      //   return HomeView.route();

      default:
        return _errorRoute();
    }
  }

  static Route _errorRoute() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/error'),
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 100,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "The page you're looking for doesn't exist or is under construction.",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
