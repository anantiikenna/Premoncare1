import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class GenericUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const GenericUserAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.borderOf(context),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Icon(Icons.person, color: AppColors.textTertiaryOf(context))
          : null,
    );
  }
}
