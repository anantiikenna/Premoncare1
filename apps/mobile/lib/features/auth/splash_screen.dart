import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../core/supabase_locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Subtle floating animation for logo
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuart)),
    );

    _mainController.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final session = supabase.auth.currentSession;
      final loggedIn = session != null;

      if (loggedIn) {
        final role = await getUserRole().timeout(const Duration(seconds: 8));
        final prefs = await SharedPreferences.getInstance();
        final hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;

        if (mounted) {
          if (!hasSeenPermissions && role == 'patient') {
            context.go('/permissions');
          } else {
            context.go(role == 'doctor' || role == 'admin' ? '/doctor_dashboard' : '/patient_dashboard');
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
        if (mounted) {
          context.go(hasSeenOnboarding ? '/login' : '/onboarding');
        }
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2FE),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Decorative Background Elements
          _buildDecorativeElements(size),

          // 3. Bottom Mesh/Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: CustomPaint(
              painter: _MeshPainter(),
            ),
          ),

          // 4. Central Content
          Center(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * math.sin(_floatController.value * 2 * math.pi)),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // New Vertical Logo (Symbol + Text)
                        Image.asset(
                          'assets/logo.png',
                          width: size.width * 0.65,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Secure healthcare, simplified',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Minimalist Loading
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F62FE)),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeElements(Size size) {
    return Stack(
      children: [
        // Floating Plus Icons
        _buildPlusIcon(size.width * 0.85, size.height * 0.15, 24, 0.2),
        _buildPlusIcon(size.width * 0.15, size.height * 0.28, 18, 0.1),
        _buildPlusIcon(size.width * 0.9, size.height * 0.52, 20, 0.15),
        
        // Dot Patterns
        _buildDotPattern(size.width * 0.08, size.height * 0.45),
        _buildDotPattern(size.width * 0.88, size.height * 0.68),
      ],
    );
  }

  Widget _buildPlusIcon(double left, double top, double size, double opacity) {
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: Icon(Icons.add, size: size, color: const Color(0xFF0F62FE)),
      ),
    );
  }

  Widget _buildDotPattern(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: 0.15,
        child: Column(
          children: List.generate(4, (_) => Row(
            children: List.generate(4, (_) => Container(
              margin: const EdgeInsets.all(2),
              width: 3,
              height: 3,
              decoration: const BoxDecoration(color: Color(0xFF0F62FE), shape: BoxShape.circle),
            )),
          )),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0F62FE).withValues(alpha: 0.05),
          const Color(0xFF0F62FE).withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    
    // Draw wavy lines to simulate the mesh in the image
    for (var i = 0; i < 15; i++) {
      path.reset();
      path.moveTo(0, size.height * (0.4 + i * 0.05));
      path.quadraticBezierTo(
        size.width * 0.3, size.height * (0.2 + i * 0.06),
        size.width * 0.6, size.height * (0.5 + i * 0.04),
      );
      path.quadraticBezierTo(
        size.width * 0.85, size.height * (0.8 + i * 0.02),
        size.width, size.height * (0.6 + i * 0.05),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

