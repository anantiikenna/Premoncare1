import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';

class PricingPlansScreen extends StatelessWidget {
  const PricingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.05), size: 400)),

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
                        Text('PREMIUM ACCESS', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Text('Explore Plans', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
                        const SizedBox(height: 8),
                        Text('Choose a plan that fits your clinical needs.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w500)),
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20),
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(Icons.help_outline_rounded, color: AppColors.textPrimaryOf(context), size: 20),
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

  const _PricingCard({
    required this.title,
    required this.price,
    this.period,
    required this.subtitle,
    required this.features,
    required this.buttonLabel,
    this.isPremium = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isPremium ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLightOf(context), width: isPremium ? 2 : 1),
        boxShadow: isPremium ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Text('MOST POPULAR CHOICE', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isPremium ? AppColors.primary : AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
                    if (period != null)
                      Text(period!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textTertiaryOf(context))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                Divider(color: AppColors.borderLightOf(context)),
                const SizedBox(height: 32),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.successLightOf(context), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: AppColors.success, size: 12)),
                      const SizedBox(width: 16),
                      Text(f, style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w700)),
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
                        SnackBar(content: Text(isPremium ? 'To upgrade, contact support@premoncare.com or visit your profile settings.' : 'For enterprise inquiries, email sales@premoncare.com')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? AppColors.primary : (isCurrent ? AppColors.borderLightOf(context) : AppColors.slate800),
                      foregroundColor: isPremium || !isCurrent ? AppColors.textInverse : AppColors.textTertiaryOf(context),
                      elevation: isPremium ? 10 : 0,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(buttonLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
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
