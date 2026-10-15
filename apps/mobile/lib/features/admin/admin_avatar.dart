import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AdminAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const AdminAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bgColor = backgroundColor ?? AppColors.primary;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor.withValues(alpha: 0.1),
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.7,
                color: bgColor,
              ),
            )
          : null,
    );
  }
}
