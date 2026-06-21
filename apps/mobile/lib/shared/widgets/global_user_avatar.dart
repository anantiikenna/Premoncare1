import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/providers.dart';

class GlobalUserAvatar extends ConsumerWidget {
  final double radius;
  
  const GlobalUserAvatar({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      data: (profile) {
        final avatarUrl = profile?['avatar_url'] as String?;
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.borderOf(context),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, color: AppColors.textTertiaryOf(context))
              : null,
        );
      },
      loading: () => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.borderLightOf(context),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.errorLightOf(context),
        child: Icon(Icons.error_outline, color: AppColors.error),
      ),
    );
  }
}
