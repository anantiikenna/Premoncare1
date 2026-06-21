import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/providers.dart';
import 'patient_providers.dart';

class PatientDashboard extends ConsumerWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context, userAsync),
                  const SizedBox(height: 32),
                  _buildSearchHub(),
                  const SizedBox(height: 32),
                  _buildTimeBalanceCard(ref, primaryColor),
                  const SizedBox(height: 32),
                  _buildActionGrid(context, primaryColor),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'TOP SPECIALISTS', onSeeAll: () => context.push('/doctor-search')),
                  const SizedBox(height: 16),
                  _buildDoctorList(ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<Map<String, dynamic>?> userAsync) {
    return userAsync.when(
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning,', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
            '${profile?['full_name']?.split(' ')[0] ?? 'Patient'} 👋',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0),
          ),
        ],
      ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning,', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
          const Text('...', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning,', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
          const Text('Welcome 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSearchHub() {
    return Builder(builder: (context) {
    return GestureDetector(
      onTap: () => context.push('/doctor-search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textTertiaryOf(context), size: 20),
            const SizedBox(width: 16),
            Text('Search specialists, clinic...', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.tune_rounded, color: AppColors.textSecondaryOf(context), size: 20),
          ],
        ),
      ),
    );
    });
  }

  Widget _buildTimeBalanceCard(WidgetRef ref, Color primaryColor) {
    final creditsAsync = ref.watch(patientCreditsProvider);

    return Builder(builder: (context) {
    return GestureDetector(
      onTap: () => context.push('/credits'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -20, child: Icon(Icons.access_time_filled_rounded, color: Colors.white.withValues(alpha: 0.1), size: 120)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('CONSULTATION CREDITS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      creditsAsync.when(
                        data: (credits) => Text('$credits', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                        loading: () => const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: Colors.white)),
                        error: (_, _) => const Text('0', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                      ),
                      const SizedBox(width: 8),
                      const Text('minutes', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Add Credit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    });
  }

  Widget _buildActionGrid(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        _ActionCard(icon: Icons.calendar_today_rounded, label: 'Book Now', sublabel: 'Specialists', color: primaryColor, onPress: () => context.push('/doctor-search')),
        const SizedBox(width: 16),
        _ActionCard(icon: Icons.description_rounded, label: 'Records', sublabel: 'Medical Vault', color: AppColors.success, onPress: () => context.push('/vault')),
        const SizedBox(width: 16),
        _ActionCard(icon: Icons.account_balance_wallet_rounded, label: 'Credits', sublabel: 'P2P Top-up', color: AppColors.primary, onPress: () => context.push('/credits')),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 1.5)),
        TextButton(onPressed: onSeeAll, child: const Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13))),
      ],
    );
  }

  Widget _buildDoctorList(WidgetRef ref) {
    final doctorsAsync = ref.watch(availableDoctorsProvider);

    return Builder(builder: (context) {
      return doctorsAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No specialists available at the moment.')),
            );
          }
          return Column(
            children: doctors.map((doc) {
              final String name = doc['full_name'] ?? 'Unknown Doctor';
              final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
              
              String specialty = 'General Practice';
              if (doc['specializations_list'] != null && (doc['specializations_list'] as List).isNotEmpty) {
                specialty = (doc['specializations_list'] as List).first.toString();
              }
              final price = doc['hourly_rate'] != null ? '₦${doc['hourly_rate']}' : '₦N/A';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => context.push('/doctor-details', extra: {
                    'id': doc['id'],
                    'name': name,
                    'specialty': specialty,
                  }),
                  child: _DoctorListItem(
                    name: name,
                    specialty: specialty,
                    experience: '5+ yrs',
                    rating: '5.0',
                    reviews: doc['patients_helped']?.toString() ?? '0',
                    price: price,
                    initial: initial,
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading doctors: $error')),
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onPress;

  const _ActionCard({required this.icon, required this.label, required this.sublabel, required this.color, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(height: 16),
              Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimaryOf(context))),
              const SizedBox(height: 2),
              Text(sublabel, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorListItem extends StatelessWidget {
  final String name;
  final String specialty;
  final String experience;
  final String rating;
  final String reviews;
  final String price;
  final String initial;

  const _DoctorListItem({required this.name, required this.specialty, required this.experience, required this.rating, required this.reviews, required this.price, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context)), overflow: TextOverflow.ellipsis)),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
                Text(specialty, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textPrimaryOf(context))),
                    const SizedBox(width: 4),
                    Text('($reviews reviews)', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(8)), child: Text(experience, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w800))),
                  ],
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
