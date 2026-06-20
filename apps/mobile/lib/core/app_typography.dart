import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Premoncare Design System — Typography scale.
/// Use `AppTypography.of(context)` for theme-aware access, or static constants
/// for backward-compatible light-mode defaults.
class AppTypography {
  AppTypography._();

  // ─── Headings ────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ─── Body ────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ─── Labels / Captions ──────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  // ─── Buttons ─────────────────────────────────────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textInverse,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  // ─── Misc ────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: AppColors.textTertiary,
  );

  // ═══════════════════════════════════════════════════════════════════
  // Theme-aware access — call AppTypography.of(context) for dark mode
  // ═══════════════════════════════════════════════════════════════════

  static TextStyle _t(BuildContext context, TextStyle base, Color? Function(BuildContext) colorFn) =>
      base.copyWith(color: colorFn(context));

  static TextStyle h1Of(BuildContext context) => _t(context, h1, AppColors.textPrimaryOf);
  static TextStyle h2Of(BuildContext context) => _t(context, h2, AppColors.textPrimaryOf);
  static TextStyle h3Of(BuildContext context) => _t(context, h3, AppColors.textPrimaryOf);
  static TextStyle h4Of(BuildContext context) => _t(context, h4, AppColors.textPrimaryOf);

  static TextStyle bodyLargeOf(BuildContext context) => _t(context, bodyLarge, AppColors.textPrimaryOf);
  static TextStyle bodyMediumOf(BuildContext context) => _t(context, bodyMedium, AppColors.textPrimaryOf);
  static TextStyle bodySmallOf(BuildContext context) => _t(context, bodySmall, AppColors.textSecondaryOf);

  static TextStyle labelLargeOf(BuildContext context) => _t(context, labelLarge, AppColors.textPrimaryOf);
  static TextStyle labelMediumOf(BuildContext context) => _t(context, labelMedium, AppColors.textPrimaryOf);
  static TextStyle labelSmallOf(BuildContext context) => _t(context, labelSmall, AppColors.textSecondaryOf);

  static TextStyle captionOf(BuildContext context) => _t(context, caption, AppColors.textTertiaryOf);
  static TextStyle overlineOf(BuildContext context) => _t(context, overline, AppColors.textTertiaryOf);
}
