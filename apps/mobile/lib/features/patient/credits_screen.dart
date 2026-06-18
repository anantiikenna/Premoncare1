import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'patient_providers.dart';
import '../../shared/widgets/generic_user_avatar.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF0F62FE);
    final creditsAsync = ref.watch(patientDetailedCreditsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(top: -150, right: -100, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 24),
                  const Text('FINANCIAL HUB', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  const Text('Consultation Credits', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
                  const SizedBox(height: 32),

                  _HeaderStatsCard(primaryColor: primaryColor, creditsAsync: creditsAsync),
                  const SizedBox(height: 32),

                  _buildActionGrid(context, primaryColor),
                  const SizedBox(height: 40),

                  const Text('MY DOCTOR CREDITS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  
                  // Interactive Doctor Credits List
                  creditsAsync.when(
                    data: (credits) {
                      if (credits.isEmpty) {
                        return _buildMockDoctorCredits(primaryColor);
                      }
                      return Column(
                        children: credits.map((credit) => _DoctorCreditCard(
                          name: credit['doctor_name'],
                          specialty: credit['specialty'],
                          rate: '₦${credit['hourly_rate']}/hr',
                          remainingMinutes: credit['minutes_remaining'],
                          totalMinutes: credit['minutes_remaining'] + 30, // Mock total for visual progress
                          lastUsed: 'Recently',
                          primaryColor: primaryColor,
                          avatarUrl: credit['avatar_url'],
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _buildMockDoctorCredits(primaryColor),
                  ),

                  const SizedBox(height: 32),
                  _DisclaimerBanner(primaryColor: primaryColor),
                  const SizedBox(height: 40),

                  const Text('RECENT ACTIVITY', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _ActivityFeed(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20)),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credit history coming soon')),
              );
            },
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.history_rounded, color: Color(0xFF1E293B), size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        Expanded(child: _QuickAction(icon: Icons.timer_rounded, label: 'Buy Time', color: primaryColor, onTap: () => context.push('/pricing_plans'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.upload_file_rounded, label: 'Upload Receipt', color: const Color(0xFF10B981), onTap: () => context.push('/upload-receipt'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.receipt_long_rounded, label: 'History', color: const Color(0xFFF59E0B), onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit history coming soon')));
        })),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.help_outline_rounded, label: 'Guide', color: const Color(0xFF8B5CF6), onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guide coming soon')));
        })),
      ],
    );
  }

  Widget _buildMockDoctorCredits(Color primaryColor) {
    return Column(
      children: [
        _DoctorCreditCard(name: 'Dr. Ibrahim Musa', specialty: 'Internal Medicine Specialist', rate: '₦12,000/hr', remainingMinutes: 45, totalMinutes: 60, lastUsed: '2 days ago', primaryColor: primaryColor),
        const SizedBox(height: 16),
        _DoctorCreditCard(name: 'Dr. Adaeze Nwosu', specialty: 'General Practitioner', rate: '₦18,000/hr', remainingMinutes: 20, totalMinutes: 30, lastUsed: '1 week ago', isLowBalance: true, primaryColor: primaryColor),
        const SizedBox(height: 16),
        _DoctorCreditCard(name: 'Dr. David Johnson', specialty: 'Cardiologist', rate: '₦30,000/hr', remainingMinutes: 90, totalMinutes: 120, lastUsed: '3 days ago', primaryColor: primaryColor),
      ],
    );
  }
}

class _HeaderStatsCard extends StatelessWidget {
  final Color primaryColor;
  final AsyncValue<List<Map<String, dynamic>>> creditsAsync;
  
  const _HeaderStatsCard({required this.primaryColor, required this.creditsAsync});

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = creditsAsync.maybeWhen(
      data: (credits) => credits.isEmpty ? 155 : credits.fold(0, (sum, item) => sum + (item['minutes_remaining'] as int)),
      orElse: () => 155,
    );
    final int activeDoctors = creditsAsync.maybeWhen(
      data: (credits) => credits.isEmpty ? 3 : credits.length,
      orElse: () => 3,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text('Total Remaining', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$totalMinutes', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2.0)),
                        const SizedBox(width: 6),
                        const Text('mins', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Across $activeDoctors Active Doctors', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spent (Monthly)', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('₦32,500', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    const Text('Time Purchased', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('210 mins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _DoctorCreditCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String rate;
  final int remainingMinutes;
  final int totalMinutes;
  final String lastUsed;
  final bool isLowBalance;
  final Color primaryColor;
  final String? avatarUrl;

  const _DoctorCreditCard({
    required this.name,
    required this.specialty,
    required this.rate,
    required this.remainingMinutes,
    required this.totalMinutes,
    required this.lastUsed,
    this.isLowBalance = false,
    required this.primaryColor,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = remainingMinutes / totalMinutes;
    final Color progressColor = isLowBalance ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: isLowBalance ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GenericUserAvatar(radius: 28, avatarUrl: avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF0F62FE), size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(specialty, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)), child: Text(rate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$remainingMinutes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: progressColor, letterSpacing: -1.0)),
                  const Text('mins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              color: progressColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last used $lastUsed', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text('$remainingMinutes / $totalMinutes mins', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
                Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/pricing_plans'),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Buy More', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/doctor-search'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Consult', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final Color primaryColor;
  const _DisclaimerBanner({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryColor.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Credits are doctor-specific. Time credits can only be used to consult with the doctor who credited them. Unused time never expires.',
              style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ActivityItem(title: 'Top Up Success', subtitle: 'Dr. Ibrahim Musa', amount: '+30 MINS', date: 'May 20, 2026', isPositive: true),
        SizedBox(height: 16),
        _ActivityItem(title: 'Video Consultation', subtitle: 'Dr. Ibrahim Musa', amount: '-15 MINS', date: 'May 20, 2026', isPositive: false),
        SizedBox(height: 16),
        _ActivityItem(title: 'Top Up Success', subtitle: 'Dr. Adaeze Nwosu', amount: '+20 MINS', date: 'May 18, 2026', isPositive: true),
        SizedBox(height: 16),
        _ActivityItem(title: 'Chat Consultation', subtitle: 'Dr. Adaeze Nwosu', amount: '-10 MINS', date: 'May 17, 2026', isPositive: false),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final bool isPositive;

  const _ActivityItem({required this.title, required this.subtitle, required this.amount, required this.date, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isPositive ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isPositive ? Icons.add_rounded : Icons.remove_rounded, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('$subtitle • $date', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)]));
  }
}
