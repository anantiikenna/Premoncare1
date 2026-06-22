import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Book verified\ndoctors instantly',
      highlight: 'instantly',
      text: 'Find and book trusted doctors in just a few taps.',
      image: 'assets/onboarding_1.png',
      icon: Icons.verified_rounded,
      color: AppColors.primary,
    ),
    _OnboardingItem(
      title: 'Secure video\nconsultations',
      highlight: 'consultations',
      text: 'Talk to your doctor securely from the comfort of your home.',
      image: 'assets/onboarding_2.png',
      icon: Icons.videocam_rounded,
      color: AppColors.primary,
    ),
    _OnboardingItem(
      title: 'Pay with\ntime credits',
      highlight: 'time credits',
      text: 'Use time credits for consultations - simple, transparent, and fair.',
      image: 'assets/onboarding_3.png',
      icon: Icons.access_time_filled_rounded,
      color: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _rememberOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  Future<void> _goTo(String route) async {
    await _rememberOnboarding();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.backgroundOf(context), AppColors.surfaceOf(context)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.17,
            child: CustomPaint(painter: _WavePainter(color: page.color)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo-symbol.png', height: 42, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(Icons.health_and_safety_rounded, size: 32, color: AppColors.primary)),
                      TextButton.icon(
                        onPressed: () => _goTo('/login'),
                        label: const Text(
                          'Skip',
                          style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingSlide(
                        item: _pages[index],
                        animation: _floatController,
                        viewportHeight: size.height,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
                  child: Column(
                    children: [
                      _PageDots(count: _pages.length, current: _currentPage, activeColor: page.color),
                      const SizedBox(height: 28),
                      _PrimaryAction(
                        label: 'Get Started',
                        icon: page.icon,
                        color: page.color,
                        onPressed: () => _goTo('/register'),
                      ),
                      const SizedBox(height: 14),
                      _LoginAction(onPressed: () => _goTo('/login')),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String highlight;
  final String text;
  final String image;
  final IconData icon;
  final Color color;

  const _OnboardingItem({
    required this.title,
    required this.highlight,
    required this.text,
    required this.image,
    required this.icon,
    required this.color,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingItem item;
  final Animation<double> animation;
  final double viewportHeight;

  const _OnboardingSlide({
    required this.item,
    required this.animation,
    required this.viewportHeight,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = math.min(viewportHeight * 0.42, 390.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 8 * math.sin(animation.value * 2 * math.pi)),
                    child: child,
                  );
                },
                child: Image.asset(item.image, height: imageHeight, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(item.icon, size: 80, color: item.color)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HighlightedTitle(item: item),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Text(
              item.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedTitle extends StatelessWidget {
  final _OnboardingItem item;

  const _HighlightedTitle({required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = item.title.split(item.highlight);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontSize: 30,
          height: 1.18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: parts.first),
          TextSpan(text: item.highlight, style: TextStyle(color: item.color)),
          if (parts.length > 1) TextSpan(text: parts.last),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;

  const _PageDots({required this.count, required this.current, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            color: active ? activeColor : AppColors.borderLightOf(context),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [AppColors.primary, color]),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 12)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.96), shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.borderOf(context), width: 1.4),
          backgroundColor: AppColors.surfaceOf(context).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.infoLight,
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 21),
            ),
            SizedBox(width: 18),
            Text(
              'Login',
              style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;

  const _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.03), color.withValues(alpha: 0.14)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 12; i++) {
      final path = Path()
        ..moveTo(0, size.height * (0.35 + i * 0.045))
        ..quadraticBezierTo(
          size.width * 0.32,
          size.height * (0.12 + i * 0.055),
          size.width * 0.62,
          size.height * (0.42 + i * 0.035),
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * (0.64 + i * 0.025),
          size.width,
          size.height * (0.5 + i * 0.04),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.color != color;
}
