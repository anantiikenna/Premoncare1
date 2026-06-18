import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          backgroundColor: const Color(0xFFE2E8F0),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? const Icon(Icons.person, color: Color(0xFF94A3B8))
              : null,
        );
      },
      loading: () => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF1F5F9),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFFEE2E2),
        child: const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
      ),
    );
  }
}
