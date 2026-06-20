import 'package:flutter/material.dart';
import 'admin_scaffold.dart';

class SubscriptionPlanControl extends StatelessWidget {
  const SubscriptionPlanControl({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(primaryColor),
            const SizedBox(height: 32),
            _buildSectionTitle('Active Subscription Plans'),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'BASIC ACCESS',
              price: 'Free',
              users: '8,432',
              color: const Color(0xFF64748B),
              isActive: true,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'PREMIUM CARE',
              price: '₦5,000/mo',
              users: '3,120',
              color: primaryColor,
              isActive: true,
              isPromoted: true,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'ENTERPRISE / HMO',
              price: 'Custom',
              users: '12',
              color: const Color(0xFF8B5CF6),
              isActive: true,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Draft & Inactive Plans'),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'FAMILY BUNDLE',
              price: '₦12,500/mo',
              users: '0',
              color: const Color(0xFFF59E0B),
              isActive: false,
            ),
            const SizedBox(height: 40),
            _buildAddPlanButton(context, primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLAN ARCHITECTURE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text('Manage Service Tiers', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildStatsRow(Color primaryColor) {
    return Row(
      children: [
        Expanded(child: _SmallStatCard(label: 'Total Revenue', value: '₦12.4M', color: primaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _SmallStatCard(label: 'Active Subs', value: '3,132', color: const Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2));
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String users,
    required Color color,
    required bool isActive,
    bool isPromoted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPromoted ? color.withValues(alpha: 0.3) : const Color(0xFFF1F5F9), width: isPromoted ? 2 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.layers_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(price, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan status updated')),
                  );
                },
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text('$users active users', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan editing is being developed. Contact the development team to modify subscription plans.')),
                  );
                },
                child: const Row(
                  children: [
                    Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlanButton(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan creation is being developed. Subscription plans are configured in the database by administrators.')),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('CREATE NEW TIER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
