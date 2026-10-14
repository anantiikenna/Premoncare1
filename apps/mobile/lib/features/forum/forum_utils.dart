import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ForumUtils {
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
        return Icons.trending_up_rounded;
      case 'pill':
        return Icons.medication_outlined;
      case 'dumbbell':
        return Icons.fitness_center_outlined;
      case 'stethoscope':
        return Icons.medical_services_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  static Color getCategoryColor(String? iconName) {
    switch (iconName) {
      case 'heart_pulse':
        return AppColors.success;
      case 'brain':
        return AppColors.primary;
      case 'apple':
        return AppColors.warning;
      case 'baby':
        return AppColors.pink;
      case 'activity':
        return AppColors.error;
      case 'pill':
        return AppColors.info;
      case 'dumbbell':
        return AppColors.primary;
      case 'stethoscope':
        return AppColors.teal;
      default:
        return AppColors.textSecondary;
    }
  }
}
