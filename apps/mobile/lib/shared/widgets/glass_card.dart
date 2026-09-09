import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: border ?? Border.all(
          width: 1.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: child,
    );
  }
}
