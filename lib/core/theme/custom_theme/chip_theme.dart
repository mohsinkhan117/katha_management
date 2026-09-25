// lib/core/theme/custom_theme/chip_theme.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';

class AppChipTheme {
  AppChipTheme._();
  static ChipThemeData lightChipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.glassBorderLight, width: 1),
    ),
    backgroundColor: AppColors.white.withValues(alpha: 0.5),
    disabledColor: AppColors.grey.withValues(alpha: 0.4),
    labelStyle: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: const TextStyle(
      color: AppColors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    selectedColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
    checkmarkColor: AppColors.white,
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.glassBorderDark, width: 1),
    ),
    backgroundColor: AppColors.white.withValues(alpha: 0.06),
    disabledColor: AppColors.darkGrey,
    labelStyle: const TextStyle(
      color: AppColors.textWhite,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: const TextStyle(
      color: AppColors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    selectedColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
    checkmarkColor: AppColors.white,
  );
}
