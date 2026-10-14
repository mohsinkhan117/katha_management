// lib/core/theme/custom_theme/elevated_button_theme.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';

class AppElevatedButtonTheme {
  AppElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style:
        ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.darkerGrey,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.buttonDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.9);
            }
            return AppColors.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),
        ),
  );

  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style:
        ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.darkGrey,
          disabledForegroundColor: AppColors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.darkGrey;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.9);
            }
            return AppColors.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),
        ),
  );
}
