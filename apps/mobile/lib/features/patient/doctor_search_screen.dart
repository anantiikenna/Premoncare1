import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DoctorSearchScreen extends ConsumerWidget {
  const DoctorSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = Navigator.of(context).canPop();
    final isEmergency = GoRouterState.of(context).uri.queryParameters['emergency'] == 'true';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('P', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Premon', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Care', style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEmergency ? 'Emergency Ready Doctors' : 'Search & Discover', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(isEmergency ? 'Choose a specialist for immediate priority care' : 'Find the right doctor for your needs', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildSearchInput()),
                          const SizedBox(width: 12),
                          _buildFilterButton(context),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Category Strip
                _buildCategoryStrip(),
                const SizedBox(height: 24),

                // Promo Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPromoBanner(),
                ),
                const SizedBox(height: 32),

                // Popular Specialties
                _buildSectionHeader('Popular Specialties', 'View all', () => context.push('/doctor-search')),
                const SizedBox(height: 16),
                _buildPopularSpecialties(),
                const SizedBox(height: 32),

                // Top Rated Doctors
                _buildSectionHeader('Top Rated Doctors', 'View all', () => context.push('/doctor-search')),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTopRatedDoctors(context, isEmergency: isEmergency),
                ),
                const SizedBox(height: 24),

                // Bottom Verification Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildVerificationBanner(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          hintText: 'Search doctors, specialties, conditions...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Color(0xFF1E293B), size: 16),
            const SizedBox(width: 8),
            const Text('Filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    RangeValues priceRange = const RangeValues(5000, 20000);
    bool emergencyOnly = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        const Text('Specialties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: ['Cardiology', 'Pediatrics', 'Dermatology', 'Neurology', 'Orthopedics'].map((s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        const TextField(decoration: InputDecoration(hintText: 'City, area or zip code', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 24),
                        const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        RangeSlider(
                          values: priceRange,
                          min: 0,
                          max: 50000,
                          activeColor: const Color(0xFF0F62FE),
                          onChanged: (v) => setModalState(() => priceRange = v),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('₦${priceRange.start.round()}'), Text('₦${priceRange.end.round()}+')]),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Emergency Ready Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Show doctors available for immediate priority care'),
                          value: emergencyOnly,
                          activeTrackColor: const Color(0xFFEF4444),
                          onChanged: (v) => setModalState(() => emergencyOnly = v),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Filters applied: ₦${priceRange.start.round()} – ₦${priceRange.end.round()}${emergencyOnly ? ', Emergency only' : ''}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryItem('All', Icons.grid_view_rounded, const Color(0xFF0F62FE), isSelected: true),
          _buildCategoryItem('General\nPhysician', Icons.medical_services_outlined, const Color(0xFF10B981)),
          _buildCategoryItem('Pediatrician', Icons.child_care_rounded, const Color(0xFFA855F7)),
          _buildCategoryItem('Gynecologist', Icons.female_rounded, const Color(0xFFEC4899)),
          _buildCategoryItem('Dermatologist', Icons.clean_hands_rounded, const Color(0xFFF97316)),
          _buildCategoryItem('Cardiologist', Icons.favorite_border_rounded, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, Color color, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          if (isSelected) Container(width: 24, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          if (isSelected) const SizedBox(height: 4),
          Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? color : const Color(0xFF64748B), height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quality care, anywhere', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 8),
                const Text('Connect with verified doctors and get the care you deserve.', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Placeholder for doctor illustration
                const Icon(Icons.person_pin_rounded, size: 80, color: Color(0xFF93C5FD)),
                Positioned(
                  left: 0,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSpecialties() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildSpecialtyCard('Internal\nMedicine', '1,248 doctors', Icons.monitor_heart_rounded, const Color(0xFF10B981)),
          _buildSpecialtyCard('Pediatrics', '856 doctors', Icons.child_care_rounded, const Color(0xFFA855F7)),
          _buildSpecialtyCard('Gynecology', '642 doctors', Icons.female_rounded, const Color(0xFFEC4899)),
          _buildSpecialtyCard('Dermatology', '532 doctors', Icons.clean_hands_rounded, const Color(0xFFF97316)),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(String name, String count, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.2)),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildTopRatedDoctors(BuildContext context, {required bool isEmergency}) {
    return Column(
      children: [
        _buildDoctorCard(
          context: context,
          name: 'Dr. Ibrahim Musa',
          specialty: 'Internal Medicine Specialist',
          degree: 'MBBS, MD (Internal Medicine)',
          rating: '4.9', reviews: '128', consults: '1,248+',
          availability: 'Available Today', isToday: true,
          doctorId: 'd2222222-2222-2222-2222-222222222222',
          isEmergency: isEmergency,
        ),
        _buildDoctorCard(
          context: context,
          name: 'Dr. Adaeze Nwosu',
          specialty: 'Cardiology Specialist',
          degree: 'MBBS, FWACP (Cardiology)',
          rating: '4.8', reviews: '120', consults: '450+',
          availability: 'Available Tomorrow', isToday: false,
          doctorId: 'd1111111-1111-1111-1111-111111111111',
          isEmergency: isEmergency,
        ),
        _buildDoctorCard(
          context: context,
          name: 'Dr. Chinedu Okafor',
          specialty: 'Neurology Expert',
          degree: 'MBBS, FMCP (Neurology)',
          rating: '4.9', reviews: '150', consults: '500+',
          availability: 'Available Today', isToday: true,
          doctorId: 'd3333333-3333-3333-3333-333333333333',
          isEmergency: isEmergency,
        ),
      ],
    );
  }

  Widget _buildDoctorCard({
    required BuildContext context,
    required String name, required String specialty, required String degree,
    required String rating, required String reviews, required String consults,
    required String availability, required bool isToday, required String doctorId,
    required bool isEmergency,
  }) {
    return GestureDetector(
      onTap: () => context.push('/doctor-details', extra: {'id': doctorId, 'name': name, 'specialty': specialty, 'isEmergency': isEmergency}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(name.substring(4, 5), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F62FE))),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(specialty, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(degree, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 4),
                      Text('$rating ($reviews)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 10, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_alt_outlined, color: Color(0xFF94A3B8), size: 12),
                      const SizedBox(width: 4),
                      Text('$consults Consultations', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(availability, style: TextStyle(color: isToday ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/doctor-details', extra: {'id': doctorId, 'name': name, 'specialty': specialty, 'isEmergency': isEmergency}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergency ? const Color(0xFFEF4444) : const Color(0xFF0F62FE),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEmergency ? 'SOS' : 'Book', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All doctors are verified professionals', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 4),
                Text('We verify licenses, qualifications and experience to ensure you receive safe and quality care.', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}
