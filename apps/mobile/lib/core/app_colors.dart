import 'package:flutter/material.dart';

/// Premoncare Design System — Single source of truth for all colors.
/// Use these constants instead of hardcoded Color(0xFF...) values.
class AppColors {
  AppColors._();

  // ─── Brand ───────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF0F62FE);
  static const Color primaryLight  = Color(0xFF818CF8);
  static const Color primaryDark   = Color(0xFF1E3A8A);

  // ─── Semantic ────────────────────────────────────────────────────
  static const Color success       = Color(0xFF10B981);
  static const Color successLight  = Color(0xFFDCFCE7);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningLight  = Color(0xFFFEF3C7);
  static const Color error         = Color(0xFFEF4444);
  static const Color errorLight    = Color(0xFFFEE2E2);
  static const Color info          = Color(0xFF00B4D8);
  static const Color infoLight     = Color(0xFFE0F7FA);

  // ─── Neutral (Slate) ────────────────────────────────────────────
  static const Color slate900      = Color(0xFF0F172A);
  static const Color slate800      = Color(0xFF1E293B);
  static const Color slate700      = Color(0xFF334155);
  static const Color slate600      = Color(0xFF475569);
  static const Color slate500      = Color(0xFF64748B);
  static const Color slate400      = Color(0xFF94A3B8);
  static const Color slate300      = Color(0xFFCBD5E1);
  static const Color slate200      = Color(0xFFE2E8F0);
  static const Color slate100      = Color(0xFFF1F5F9);
  static const Color slate50       = Color(0xFFF8FAFC);

  // ─── Surfaces ───────────────────────────────────────────────────
  static const Color surface       = Colors.white;
  static const Color surfaceAlt    = Color(0xFFF8FAFC);
  static const Color background    = Color(0xFFF8FAFC);

  // ─── Border / Divider ──────────────────────────────────────────
  static const Color border        = Color(0xFFE2E8F0);
  static const Color borderLight   = Color(0xFFF1F5F9);
  static const Color divider       = Color(0xFFF1F5F9);

  // ─── Text ───────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary  = Color(0xFF94A3B8);
  static const Color textInverse   = Colors.white;

  // ─── Glassmorphism ─────────────────────────────────────────────
  static const Color glassBorder   = Color(0xFFE2E8F0);
  static const Color glassShadow   = Color(0x0A000000);
}
