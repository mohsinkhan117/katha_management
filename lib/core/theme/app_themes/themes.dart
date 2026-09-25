// lib/core/theme/app_themes/themes.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/core/theme/custom_theme/appbar_theme.dart';
import 'package:katha_management/core/theme/custom_theme/bottom_sheet_theme.dart';
import 'package:katha_management/core/theme/custom_theme/checkbox_theme.dart';
import 'package:katha_management/core/theme/custom_theme/chip_theme.dart';
import 'package:katha_management/core/theme/custom_theme/elevated_button_theme.dart';
import 'package:katha_management/core/theme/custom_theme/outlined_button_theme.dart';
import 'package:katha_management/core/theme/custom_theme/text_field_theme.dart';
import 'package:katha_management/core/theme/custom_theme/text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    textTheme: AppTextTheme.lightTextTheme,
    chipTheme: AppChipTheme.lightChipTheme,
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppAppBarTheme.lightAppBarTheme,
    checkboxTheme: AppCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.lightInputDecorationTheme,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiaryColor,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      surface: AppColors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white.withValues(alpha: 0.82),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.glassBorderLight, width: 1),
      ),
      shadowColor: AppColors.glassShadowLight,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.darkGrey,
      indicatorColor: AppColors.primary,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.textPrimary,
    textTheme: AppTextTheme.darkTextTheme,
    appBarTheme: AppAppBarTheme.darkAppBarTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      surface: Color(0xFF2D3748),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.glassBorderDark, width: 1),
      ),
      shadowColor: AppColors.glassShadowDark,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.grey,
      indicatorColor: AppColors.primary,
    ),
  );
}
