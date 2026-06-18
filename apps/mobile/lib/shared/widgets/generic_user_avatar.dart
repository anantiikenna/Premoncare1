import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFE2E8F0),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? const Icon(Icons.person, color: Color(0xFF94A3B8))
          : null,
    );
  }
}
