// lib/core/theme/custom_theme/text_field_theme.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';

class AppTextFormFieldTheme {
  AppTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    errorMaxLines: 3,
    prefixIconColor: AppColors.primary,
    suffixIconColor: AppColors.darkGrey,
    labelStyle: const TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
    errorStyle: const TextStyle(
      fontStyle: FontStyle.normal,
      color: AppColors.error,
      fontSize: 12,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.glassBorderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.glassBorderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1.5, color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 2, color: AppColors.error),
    ),
    filled: true,
    fillColor: AppColors.white.withValues(alpha: 0.70),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    errorMaxLines: 2,
    prefixIconColor: AppColors.accent,
    suffixIconColor: AppColors.grey,
    labelStyle: const TextStyle(
      fontSize: 14,
      color: AppColors.grey,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
    errorStyle: const TextStyle(
      fontStyle: FontStyle.normal,
      color: AppColors.error,
      fontSize: 12,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.accent,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.glassBorderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.glassBorderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1.5, color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 1, color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(width: 2, color: AppColors.error),
    ),
    filled: true,
    fillColor: AppColors.white.withValues(alpha: 0.08),
  );
}
