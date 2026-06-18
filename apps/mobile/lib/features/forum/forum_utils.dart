import 'package:flutter/material.dart';

class ForumUtils {
  /// Maps the string `icon_name` from Supabase `forum_categories` to Flutter IconData.
  static IconData getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'heart_pulse':
        return Icons.monitor_heart_outlined;
      case 'brain':
        return Icons.psychology_outlined;
      case 'apple':
        return Icons.apple_outlined;
      case 'baby':
        return Icons.pregnant_woman_outlined;
      case 'activity':
        return Icons.trending_up_rounded; // Chronic conditions
      case 'pill':
        return Icons.medication_outlined;
      case 'dumbbell':
        return Icons.fitness_center_outlined;
      case 'stethoscope':
        return Icons.medical_services_outlined;
      default:
        return Icons.article_outlined; // Default fallback icon
    }
  }

  /// Maps the string `icon_name` to a consistent thematic color for UI badges.
  static Color getCategoryColor(String? iconName) {
    switch (iconName) {
      case 'heart_pulse':
        return const Color(0xFF10B981); // Emerald
      case 'brain':
        return const Color(0xFFA855F7); // Purple
      case 'apple':
        return const Color(0xFFF59E0B); // Amber
      case 'baby':
        return const Color(0xFFEC4899); // Pink
      case 'activity':
        return const Color(0xFFEF4444); // Red
      case 'pill':
        return const Color(0xFF3B82F6); // Blue
      case 'dumbbell':
        return const Color(0xFF6366F1); // Indigo
      case 'stethoscope':
        return const Color(0xFF14B8A6); // Teal
      default:
        return const Color(0xFF64748B); // Slate fallback
    }
  }
}
