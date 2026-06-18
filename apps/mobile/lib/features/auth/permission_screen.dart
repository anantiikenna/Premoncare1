import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestAllPermissions(BuildContext context) async {
    // 1. Camera Permission
    await Permission.camera.request();
    
    // 2. Notification Permission (Firebase)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (context.mounted) {
      context.go('/patient_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1B4B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Permissions',
          style: TextStyle(
            color: Color(0xFF1E1B4B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Illustration Placeholder
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  // Mock illustration with icons
                  Positioned(
                    top: 20,
                    left: 40,
                    child: _buildFloatingIcon(
                      Icons.videocam_rounded,
                      const Color(0xFFEEF2FF),
                      const Color(0xFF4F46E5),
                      48,
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 40,
                    child: _buildFloatingIcon(
                      Icons.notifications_rounded,
                      const Color(0xFFECFDF5),
                      const Color(0xFF10B981),
                      48,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Image.network(
                      'https://cdni.iconscout.com/illustration/premium/thumb/female-doctor-holding-smartphone-5683266-4744415.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_3_rounded,
                        size: 150,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 60,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF4F46E5),
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'We need a couple of\npermissions to make your\nexperience seamless',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'These permissions help us provide secure video\nconsultations and keep you updated on important\ninformation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            
            // Permission Cards
            _PermissionItem(
              icon: Icons.videocam_rounded,
              iconBgColor: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Allow camera for consultations',
              description: 'Use your camera to connect face-to-face with doctors during video consultations for a better experience.',
              note: 'Your video is private and encrypted end-to-end.',
              noteIcon: Icons.verified_user_rounded,
              noteColor: const Color(0xFF4F46E5),
              onTap: () => Permission.camera.request(),
            ),
            const SizedBox(height: 20),
            _PermissionItem(
              icon: Icons.notifications_rounded,
              iconBgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
              title: 'Enable notifications for updates',
              description: 'Get timely updates about appointments, reminders, test results, prescriptions and important alerts.',
              note: 'You can change this anytime in settings.',
              noteIcon: Icons.check_circle_rounded,
              noteColor: const Color(0xFF10B981),
              onTap: () => FirebaseMessaging.instance.requestPermission(),
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _requestAllPermissions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E31BE), // Brand blue
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Enable All & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_permissions', true);
                if (context.mounted) context.go('/patient_dashboard');
              },
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Privacy Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your privacy matters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'We only use permissions to improve your healthcare experience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF4F46E5),
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color bgColor, Color iconColor, double size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size * 0.5),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;
  final String note;
  final IconData noteIcon;
  final Color noteColor;
  final VoidCallback onTap;

  const _PermissionItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.note,
    required this.noteIcon,
    required this.noteColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFE5E7EB),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: noteColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(noteIcon, color: noteColor, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: noteColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
