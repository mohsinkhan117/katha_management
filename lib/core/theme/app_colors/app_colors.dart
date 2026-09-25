// lib/core/theme/app_colors/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Core Palette ────────────────────────────────────────────────────────────

  static const Color primary = Color.fromARGB(255, 46, 81, 141); // Deep Navy
  static const Color secondary = Color(0xFFC9932A); // Warm Gold
  static const Color accent = Color(0xFFE8A93B); // Bright Amber Accent
  static const Color tertiaryColor = Color(
    0xFFF7F5F0,
  ); // Receipt-Paper Background
  static const Color tetraColor = Color(
    0xFF8B2635,
  ); // Deep Burgundy (highlights/void stamps)
  static const Color pentaColor = Color(0xFF16495F); // Deep Teal-Blue
  static const Color hexaColor = Color(0xFFFFFDF9); // Warm Paper White

  // ─── Gradients ────────────────────────────────────────────────────────────────
  static const Gradient primaryLinerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F3864), // Deep Navy
      Color(0xFF16495F), // Deep Teal-Blue
    ],
  );

  static const Gradient scaffoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x141F3864), Color(0xFFF7F5F0), Color(0x0DC9932A)],
  );

  // ─── Text Colors ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Colors.white;
  static const Color textPurple = Color(0xFF1F3864);

  // ─── Background Colors ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F5F0);
  static const Color light = Color(0xFFFFFDF9);
  static const Color dark = Color(0xFF111827);
  static const Color primaryBackground = Color(0xFFF7F5F0);
  static const Color lightContainer = Color(0xFFEFF3F8);
  static Color darkContainer = textWhite.withValues(alpha: 0.1);

  // ─── Button Colors ────────────────────────────────────────────────────────────
  static const Color buttonPrimary = Color(0xFF1F3864);
  static const Color buttonSecondary = Color(0xFFC9932A);
  static const Color buttonDisabled = Color(0xFFD1D5DB);
  static const LinearGradient buttonActiveLinearGradientColor = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF244B82), // Primary Navy
      Color(0xFF1A2F55), // Darker Navy
    ],
  );
  static const LinearGradient buttonInActiveLinearGradientColor =
      LinearGradient(colors: [Colors.grey, Colors.grey]);

  // ─── Border Colors ────────────────────────────────────────────────────────────
  static const Color borderPrimary = Color(0xFF808080);
  static const Color borderSecondary = Color(0xFFE5E7EB);

  // ─── Semantic Colors ──────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF1F3864);

  // ─── Neutral Shades ───────────────────────────────────────────────────────────
  static const Color fullBlack = Color(0xFF000000);
  static const Color black = Color(0xFF111827);
  static const Color darkerGrey = Color(0xFF374151);
  static const Color darkGrey = Color(0xFF4B5563);
  static const Color grey = Color(0xFFE5E7EB);
  static const Color softGrey = Color(0xFFF3F4F6);
  static const Color lightGrey = Color(0xFFF7F5F0);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Card & Surface Colors ────────────────────────────────────────────────────
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF7F5F0);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // ─── Frosted Glass Tokens (iPhone Widget Style) ───────────────────────────────
  static const Color glassFillLight = Color(0xC7FFFFFF); // 78% White
  static const Color glassFillLightEnd = Color(0x7AFFFFFF); // 48% White
  static const Color glassBorderLight = Color(0xD9FFFFFF); // 85% White
  static const Color glassShadowLight = Color(0x0D1F3864); // 5% Primary Navy

  static const Color glassFillDark = Color(0x14FFFFFF); // 8% White
  static const Color glassFillDarkEnd = Color(0x08FFFFFF); // 3% White
  static const Color glassBorderDark = Color(0x24FFFFFF); // 14% White
  static const Color glassShadowDark = Color(0x59000000); // 35% Black

  static const Gradient glassGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassFillLight, glassFillLightEnd],
  );

  static const Gradient glassGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassFillDark, glassFillDarkEnd],
  );

  static const Gradient scaffoldGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF000000), Color(0x3316495F)],
  );

  static Gradient glassGradient(bool isDark) =>
      isDark ? glassGradientDark : glassGradientLight;

  static Color glassBorderColor(bool isDark) =>
      isDark ? glassBorderDark : glassBorderLight;

  static Color glassShadowColor(bool isDark) =>
      isDark ? glassShadowDark : glassShadowLight;

  static Gradient scaffoldGradientFor(bool isDark) =>
      isDark ? scaffoldGradientDark : scaffoldGradient;
}
