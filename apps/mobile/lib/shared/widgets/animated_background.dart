import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Slowly rotate/move the orbs over a long duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Stack(
      children: [
        // Base Background
        Container(color: backgroundColor),

        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Top Right Glowing Orb
                Positioned(
                  top: -100 + (50 * _controller.value),
                  right: -100 - (30 * _controller.value),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Bottom Left Glowing Orb
                Positioned(
                  bottom: -150 - (40 * _controller.value),
                  left: -50 + (60 * _controller.value),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                // Center Moving Orb
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 150 + (100 * _controller.value),
                  left: MediaQuery.of(context).size.width / 2 - 150 - (50 * _controller.value),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Heavy Frosted Glass Blur to create Mesh Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: backgroundColor.withValues(alpha: 0.1),
            ),
          ),
        ),

        // Main Content Overlay
        SafeArea(child: widget.child),
      ],
    );
  }
}
