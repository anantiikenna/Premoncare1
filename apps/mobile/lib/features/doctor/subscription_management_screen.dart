import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool isExploring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscription Management',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF1E293B)),
            onPressed: () => context.push('/help-support'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (isExploring) _buildExploreView() else _buildManageView(),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW 1: MANAGE SUBSCRIPTION (Image 2) ---
  Widget _buildManageView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Manage your plan, billing and benefits',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        
        // Premium Plan Hero Card
        _buildPlanHeroCard(),
        const SizedBox(height: 20),

        // Quick Features
        _buildFeaturesRow(),
        const SizedBox(height: 32),

        // Billing & Payment
        _buildSectionHeader('Billing & Payment', trailing: 'View History'),
        const SizedBox(height: 16),
        _buildBillingInfo(),
        const SizedBox(height: 32),

        // Your Plan Usage
        _buildSectionHeader('Your Plan Usage', trailing: 'Resets on 15 June 2025'),
        const SizedBox(height: 20),
        _buildUsageGrid(),
        const SizedBox(height: 32),

        // Manage Subscription Actions
        _buildSectionHeader('Manage Subscription'),
        const SizedBox(height: 16),
        _buildActionTile(Icons.upgrade_rounded, 'Upgrade Plan', 'Get more benefits and features', const Color(0xFF0F62FE), () => setState(() => isExploring = true)),
        _buildActionTile(Icons.pause_circle_outline_rounded, 'Pause Subscription', 'Pause your plan for a while', const Color(0xFF6366F1), () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Pause Subscription'),
              content: const Text("Are you sure you want to pause your subscription? You won't be charged during the pause period."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription paused. Resume anytime from settings.')));
                  },
                  child: const Text('Pause'),
                ),
              ],
            ),
          );
        }),
        _buildActionTile(Icons.cancel_outlined, 'Cancel Subscription', 'Cancel your plan and stop future billing', const Color(0xFFEF4444), () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cancel Subscription'),
              content: const Text("Are you sure you want to cancel? You'll lose access to premium features at the end of your billing period."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled. Access continues until end of billing period.')));
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
        }, isLast: true),
        
        const SizedBox(height: 32),
        // Need Help
        _buildSupportCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPlanHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F62FE), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: const Text('Current Plan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('Premium Plan', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24),
                ],
              ),
              const SizedBox(height: 8),
              const Text('All-in-one access to premium\nhealthcare features.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              const Text('Price', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('₦15,000 / month', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text('Next billing date: 15 June 2025', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            top: 10,
            child: _buildShieldIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 90, color: Colors.white24),
            const Text('P', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFeatureItem(Icons.videocam_rounded, 'Unlimited', 'Video Consults'),
        _buildFeatureItem(Icons.chat_bubble_rounded, 'Priority', 'Support'),
        _buildFeatureItem(Icons.security_rounded, 'Secure', 'Health Data'),
        _buildFeatureItem(Icons.local_offer_rounded, 'Exclusive', 'Discounts'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String sub) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0F62FE).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0F62FE), size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w800)),
          Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w800)),
        if (trailing != null)
          Text(trailing, style: TextStyle(color: trailing.contains('History') ? const Color(0xFF0F62FE) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBillingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildBillingRow(Icons.description_outlined, 'Billing Cycle', 'Monthly', amount: '₦15,000'),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildBillingRow(Icons.credit_card_rounded, 'Payment Method', '•••• 4242', isDefault: true, trailingIcon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Widget _buildBillingRow(IconData icon, String label, String value, {String? amount, bool isDefault = false, IconData? trailingIcon}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF0F62FE), size: 20)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)), child: const Text('Default', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold))),
                ]
              ],
            ),
          ],
        ),
        const Spacer(),
        if (amount != null) Text(amount, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900)),
        if (trailingIcon != null) Icon(trailingIcon, color: const Color(0xFF94A3B8), size: 20),
      ],
    );
  }

  Widget _buildUsageGrid() {
    return Row(
      children: [
        Expanded(child: _buildUsageItem(0.65, Icons.videocam_rounded, '12 / ∞', 'Video Consults', 'Unlimited')),
        Expanded(child: _buildUsageItem(0.4, Icons.chat_bubble_rounded, '28 / ∞', 'Chat Consults', 'Unlimited')),
        Expanded(child: _buildUsageItem(0.4, Icons.description_rounded, '8 / 20', 'Health Records', '40% used')),
        Expanded(child: _buildUsageItem(0.3, Icons.file_download_rounded, '3 / 10', 'Reports', '30% used')),
      ],
    );
  }

  Widget _buildUsageItem(double progress, IconData icon, String val, String label, String sub) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation(const Color(0xFF0F62FE)),
              ),
            ),
            Icon(icon, color: const Color(0xFF0F62FE), size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Text(val, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600)),
        Text(sub, style: TextStyle(color: sub.contains('Unlimited') ? const Color(0xFF22C55E) : const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String sub, Color color, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
          subtitle: Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFDCFCE7))),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_rounded, color: Color(0xFF22C55E), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need Help?', style: TextStyle(color: Color(0xFF166534), fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Our support team is here to help you.', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email admin@premoncare.com for subscription support')));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F62FE),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Contact Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support@premoncare.com')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F62FE), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF22C55E), width: 1))),
            child: const Text('Contact Support', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- VIEW 2: EXPLORE PLANS (Image 1) ---
  Widget _buildExploreView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Choose the plan that works best for you\nand manage your subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        
        // Current Plan Section
        const Text('Current Plan', style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildCurrentPlanExploreCard(),
        
        const SizedBox(height: 32),
        // Choose a Plan Section
        const Text('Choose a Plan', style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildPlansCarousel(),
        
        const SizedBox(height: 32),
        // Security Footer
        _buildSecurityFooter(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCurrentPlanExploreCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F62FE), Color(0xFF22D3EE)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Premium Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₦15,000 / month', style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Renews on May 25, 2025', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTick('Unlimited consultations'),
                    _buildTick('Priority support'),
                    _buildTick('Time credits included'),
                    _buildTick('Family account (up to 5)'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTick(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF0F62FE), size: 14),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPlansCarousel() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPlanCard('Basic', '₦5,000', Icons.send_rounded, [
            '10 consultations / month',
            'Standard support',
            'Time credits (₦2,000)',
            'Family account (N/A)',
          ], isPopular: false),
          _buildPlanCard('Premium', '₦15,000', Icons.diamond_rounded, [
            'Unlimited consultations',
            'Priority support',
            'Time credits (₦7,500)',
            'Family account (up to 5)',
          ], isPopular: true, isCurrent: true),
          _buildPlanCard('Pro', '₦30,000', Icons.rocket_launch_rounded, [
            'Unlimited consultations',
            'VIP support',
            'Time credits (₦20,000)',
            'Family account (up to 10)',
          ], isPopular: false),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, IconData icon, List<String> perks, {bool isPopular = false, bool isCurrent = false}) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPopular ? const Color(0xFF0F62FE) : const Color(0xFFF1F5F9), width: isPopular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0F62FE).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF0F62FE), size: 20)),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$price / month', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          ...perks.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: p.contains('N/A') ? Colors.grey.shade300 : const Color(0xFF22C55E), size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(p, style: TextStyle(color: p.contains('N/A') ? Colors.grey.shade400 : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? () => setState(() => isExploring = false) : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan selected! Contact support@premoncare.com to complete your upgrade.')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? const Color(0xFF0F62FE) : Colors.white,
                foregroundColor: isCurrent ? Colors.white : const Color(0xFF0F62FE),
                elevation: 0,
                side: BorderSide(color: isCurrent ? Colors.transparent : const Color(0xFF0F62FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isCurrent ? 'Current Plan' : 'Choose Plan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          _buildShieldWithLock(),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure & Hassle-free', style: TextStyle(color: Color(0xFF166534), fontSize: 15, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Your payment is encrypted and your data is always protected.', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldWithLock() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFDCFCE7), shape: BoxShape.circle)),
        const Icon(Icons.shield_rounded, color: Color(0xFF22C55E), size: 30),
        const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
      ],
    );
  }
}
