import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PricingPlansScreen extends StatelessWidget {
  const PricingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(top: -150, right: -100, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PREMIUM ACCESS', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        const Text('Explore Plans', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
                        const SizedBox(height: 8),
                        const Text('Choose a plan that fits your clinical needs.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 32),

                        _PricingCard(
                          title: 'BASIC ACCESS',
                          price: 'Free',
                          subtitle: 'Standard medical consultation',
                          features: const [
                            '24/7 Specialist Access',
                            'Secure Messaging',
                            'Standard Appointments',
                            'Basic Health Vault'
                          ],
                          buttonLabel: 'CURRENT PLAN',
                          isCurrent: true,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 24),

                        _PricingCard(
                          title: 'PREMIUM CARE',
                          price: '₦5,000',
                          period: '/month',
                          subtitle: 'Priority clinical oversight',
                          features: const [
                            'All Basic Features',
                            'Priority Booking Queue',
                            'Unlimited Video Calls',
                            'Family Record Sharing',
                            'Premium Pharmacy Discounts'
                          ],
                          buttonLabel: 'UPGRADE NOW',
                          isPremium: true,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 24),

                        _PricingCard(
                          title: 'ENTERPRISE / HMO',
                          price: 'Custom',
                          subtitle: 'Corporate health management',
                          features: const [
                            'All Premium Features',
                            'Dedicated Clinical Lead',
                            'Unlimited Family Members',
                            'Biometric Health Analysis',
                            'On-site Clinic Sync'
                          ],
                          buttonLabel: 'CONTACT SALES',
                          primaryColor: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Help'),
                  content: const Text('Choose a plan that fits your needs. You can upgrade or cancel anytime from your profile settings.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
                  ],
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.help_outline_rounded, color: Color(0xFF1E293B), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String? period;
  final String subtitle;
  final List<String> features;
  final String buttonLabel;
  final bool isPremium;
  final bool isCurrent;
  final Color primaryColor;

  const _PricingCard({
    required this.title,
    required this.price,
    this.period,
    required this.subtitle,
    required this.features,
    required this.buttonLabel,
    this.isPremium = false,
    this.isCurrent = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isPremium ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFF1F5F9), width: isPremium ? 2 : 1),
        boxShadow: isPremium ? [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: const Text('MOST POPULAR CHOICE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isPremium ? primaryColor : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
                    if (period != null)
                      Text(period!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 32),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 12)),
                      const SizedBox(width: 16),
                      Text(f, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subscription flow coming soon')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? primaryColor : (isCurrent ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                      foregroundColor: isPremium || !isCurrent ? Colors.white : const Color(0xFF94A3B8),
                      elevation: isPremium ? 10 : 0,
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
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

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
