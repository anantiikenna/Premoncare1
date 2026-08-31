import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_typography.dart';
import '../../core/app_colors.dart';

import 'patient_providers.dart';

class DoctorSearchScreen extends ConsumerStatefulWidget {
  final bool isBuyingTime;
  const DoctorSearchScreen({super.key, this.isBuyingTime = false});

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _priceMin = 0;
  double _priceMax = 50000;
  bool _emergencyOnly = false;
  bool _isEmergencyMode = false;
  Timer? _debounce;

  static const _categories = [
    'All',
    'General\nPhysician',
    'Pediatrician',
    'Gynecologist',
    'Dermatologist',
    'Cardiologist',
  ];

  static const _specialtyKeywords = {
    'General\nPhysician': 'general',
    'Pediatrician': 'pediatr',
    'Gynecologist': 'gynec',
    'Dermatologist': 'dermat',
    'Cardiologist': 'cardio',
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = value.trim().toLowerCase();
      });
    });
  }

  void _onCategoryTap(String category) {
    setState(() {
      _selectedCategory = category;
      if (category != 'All') {
        final keyword = _specialtyKeywords[category] ?? '';
        _debounce?.cancel();
        _searchQuery = keyword;
        _searchController.clear();
      } else {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    _searchFocusNode.unfocus();
  }

  List<Map<String, dynamic>> _filterDoctors(
    List<Map<String, dynamic>> doctors,
  ) {
    List<Map<String, dynamic>> filtered = List.from(doctors);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final name = (doc['full_name'] ?? '').toString().toLowerCase();
        final specialty = (doc['specialty'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || specialty.contains(_searchQuery);
      }).toList();
    }

    if (_emergencyOnly) {
      filtered = filtered.where((doc) => doc['is_emergency'] == true).toList();
    }

    filtered = filtered.where((doc) {
      final fee = (doc['consultation_fee'] ?? 0).toDouble();
      return fee >= _priceMin && fee <= _priceMax;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(searchableDoctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: doctorsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text('Failed to load doctors', style: AppTypography.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(searchableDoctorsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (doctors) {
            final filtered = _filterDoctors(doctors);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchRow()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _buildEmergencyBanner()),
                SliverToBoxAdapter(child: _buildCategoryStrip()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_isEmergencyMode)
                  SliverToBoxAdapter(
                    child: _buildEmergencyDoctorsSection(filtered),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Top Rated Doctors',
                      '${filtered.length} found',
                      () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildDoctorCard(
                        context: context,
                        doctor: filtered[index],
                      ),
                    ),
                ],
                SliverToBoxAdapter(child: _buildVerificationBanner()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            'Search Doctors',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const Spacer(),
          if (_isEmergencyMode)
            const Icon(Icons.emergency, color: AppColors.error, size: 28),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppColors.primary
              : AppColors.borderOf(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textTertiaryOf(context),
            size: 20,
          ),
          hintText: 'Search doctors, specialties...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimaryOf(context),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Filter',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    double tempMin = _priceMin;
    double tempMax = _priceMax;
    bool tempEmergency = _emergencyOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                      Text('Filters', style: AppTypography.h4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        Text('Price Range', style: AppTypography.h4),
                        const SizedBox(height: 12),
                        RangeSlider(
                          values: RangeValues(tempMin, tempMax),
                          min: 0,
                          max: 50000,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setModalState(() {
                            tempMin = v.start;
                            tempMax = v.end;
                          }),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₦${tempMin.round()}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              '₦${tempMax.round()}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Emergency Only',
                            style: AppTypography.h4,
                          ),
                          subtitle: Text(
                            'Show only emergency-ready doctors',
                            style: AppTypography.bodySmall,
                          ),
                          value: tempEmergency,
                          activeTrackColor: AppColors.error,
                          onChanged: (v) =>
                              setModalState(() => tempEmergency = v),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _priceMin = tempMin;
                          _priceMax = tempMax;
                          _emergencyOnly = tempEmergency;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
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

  Widget _buildEmergencyBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => setState(() => _isEmergencyMode = !_isEmergencyMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isEmergencyMode
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEmergencyMode
                  ? AppColors.error
                  : AppColors.borderOf(context),
              width: _isEmergencyMode ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Care',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEmergencyMode
                          ? 'Showing emergency-ready doctors nearby'
                          : 'Need immediate care? Find emergency doctors',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                _isEmergencyMode
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiaryOf(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => _onCategoryTap(category),
            child: _buildCategoryItem(
              category,
              _getCategoryIcon(category),
              _getCategoryColor(category, context),
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'General\nPhysician':
        return Icons.medical_services_outlined;
      case 'Pediatrician':
        return Icons.child_care_rounded;
      case 'Gynecologist':
        return Icons.female_rounded;
      case 'Dermatologist':
        return Icons.clean_hands_rounded;
      case 'Cardiologist':
        return Icons.favorite_border_rounded;
      default:
        return Icons.person;
    }
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category) {
      case 'All':
        return AppColors.primary;
      case 'General\nPhysician':
        return AppColors.success;
      case 'Pediatrician':
        return AppColors.primary;
      case 'Gynecologist':
        return AppColors.primary;
      case 'Dermatologist':
        return AppColors.warning;
      case 'Cardiologist':
        return AppColors.error;
      default:
        return AppColors.textSecondaryOf(context);
    }
  }

  Widget _buildCategoryItem(
    String name,
    IconData icon,
    Color color, {
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (isSelected) const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondaryOf(context),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.h4),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDoctorsSection(List<Map<String, dynamic>> doctors) {
    final emergencyDoctors = doctors
        .where((d) => d['is_emergency'] == true)
        .toList();
    final displayDoctors = emergencyDoctors.isNotEmpty
        ? emergencyDoctors
        : doctors;

    if (displayDoctors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.textTertiaryOf(context),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No emergency doctors available right now',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() => _isEmergencyMode = false);
              },
              child: const Text('View All Doctors'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSectionHeader(
          'Emergency Doctors',
          '${displayDoctors.length} available',
          () {},
        ),
        const SizedBox(height: 8),
        ...displayDoctors.map(
          (doc) => _buildDoctorCard(context: context, doctor: doc),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.textTertiaryOf(context),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text('No doctors found', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _priceMin = 0;
                _priceMax = 50000;
                _emergencyOnly = false;
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required BuildContext context,
    required Map<String, dynamic> doctor,
  }) {
    final id = doctor['id'] ?? '';
    final fullName = doctor['full_name'] ?? 'Unknown';
    final displayName = fullName;
    final specialty = doctor['specialty'] ?? 'General';
    final fee = doctor['consultation_fee'] ?? 0;
    final isOnline = doctor['is_online'] == true;
    final isEmergency = doctor['is_emergency'] == true;

    return GestureDetector(
      onTap: () => context.push(
        '/doctor-details',
        extra: {
          'id': id,
          'name': displayName,
          'specialty': specialty,
          'isEmergency': _isEmergencyMode,
        },
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    fullName.length > 4
                        ? fullName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success
                          : AppColors.textTertiaryOf(context),
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
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isEmergency)
                        const Icon(
                          Icons.emergency,
                          color: AppColors.error,
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: isOnline
                            ? AppColors.success
                            : AppColors.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: AppTypography.labelSmall.copyWith(
                          color: isOnline
                            ? AppColors.success
                            : AppColors.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₦$fee',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: widget.isBuyingTime
                      ? () => context.push(
                          '/upload-receipt',
                          extra: {'doctorId': id},
                        )
                      : () => context.push(
                          '/doctor-details',
                          extra: {
                            'id': id,
                            'name': displayName,
                            'specialty': specialty,
                            'isEmergency': _isEmergencyMode,
                          },
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isEmergencyMode && isEmergency)
                        ? AppColors.error
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.isBuyingTime
                        ? 'Buy Credit'
                        : ((_isEmergencyMode && isEmergency) ? 'SOS' : 'Book'),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All doctors are verified professionals',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We verify licenses, qualifications and experience to ensure you receive safe and quality care.',
                    style: AppTypography.labelSmall.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiaryOf(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
