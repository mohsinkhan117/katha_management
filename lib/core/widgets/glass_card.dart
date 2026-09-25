// lib/core/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';

/// A reusable glassmorphic container widget designed after iOS / iPhone widgets.
///
/// Features:
/// - Smooth squircle continuous border radius (default: 22px).
/// - Frosted glass `BackdropFilter` with 18px gaussian blur.
/// - Dynamic light/dark mode adaptation via `AppColors` and `Theme.of(context)`.
/// - Subtle light-catch hairline border and soft ambient elevation shadow.
/// - Optional interactive touch ripple with native iOS feel.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding,
    this.margin,
    this.onTap,
    this.borderWidth = 1.0,
    this.customGradient,
    this.blurSigma = 18.0,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderWidth;
  final Gradient? customGradient;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = AppColors.glassBorderColor(isDark);
    final shadowColor = AppColors.glassShadowColor(isDark);
    final gradient = customGradient ?? AppColors.glassGradient(isDark);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: isDark
                ? AppColors.black.withValues(alpha: 0.25)
                : AppColors.borderSecondary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.08),
          highlightColor: isDark
              ? AppColors.white.withValues(alpha: 0.04)
              : AppColors.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}

/// An ambient mesh gradient background container for screens using the
/// iPhone widget frosted glass aesthetic.
class AmbientScaffoldBackground extends StatelessWidget {
  const AmbientScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark : AppColors.primaryBackground,
        gradient: AppColors.scaffoldGradientFor(isDark),
      ),
      child: child,
    );
  }
}
