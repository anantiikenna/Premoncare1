import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

import '../../shared/widgets/generic_user_avatar.dart';

class DoctorDetailsScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final bool isEmergency;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    this.isEmergency = false,
  });

  @override
  ConsumerState<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends ConsumerState<DoctorDetailsScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.doctorId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, title, specialty, about_text, experience_years, hourly_rate, consultation_fee, verification_status, avatar_url, is_online')
          .eq('id', widget.doctorId)
          .single();
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching doctor profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayName => _profile?['full_name'] as String? ?? widget.doctorName;
  String get _formattedName => _displayName;
  String get _displaySpecialty => _profile?['specialty'] as String? ?? widget.specialty;
  double get _hourlyRate => (_profile?['hourly_rate'] as num?)?.toDouble() ?? 5000.0;
  double get _bookingRate => widget.isEmergency ? _hourlyRate * 5 : _hourlyRate;
  int get _experienceYears => _profile?['experience_years'] as int? ?? 0;
  String get _about => _profile?['about_text'] as String? ?? 'Dedicated and compassionate healthcare professional committed to delivering quality patient care.';
  bool get _isOnline => _profile?['is_online'] == true;
  String get _verificationStatus => _profile?['verification_status'] as String? ?? 'pending';
  bool get _isVerified => _verificationStatus == 'approved';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildPageHeader(),
                        const SizedBox(height: 16),
                        _buildHeroCard(),
                        const SizedBox(height: 24),
                        _buildQuickInfoGrid(),
                        const SizedBox(height: 24),
                        if (_isVerified) _buildVerifiedBanner(),
                        if (_isVerified) const SizedBox(height: 24),
                        _buildSectionTitle('About $_formattedName'),
                        const SizedBox(height: 12),
                        _buildAboutSection(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Specializations'),
                        const SizedBox(height: 12),
                        _buildSpecializations(),
                        const SizedBox(height: 24),
                        _buildPatientRating(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActionBar(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 24),
            ),
            Row(
              children: [
                Image.asset('assets/logo-horizontal.png', height: 28, errorBuilder: (context, error, stackTrace) => Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('P', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Premon', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Care', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )),
              ],
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Doctor Public Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
                const SizedBox(width: 8),
                Icon(Icons.verified_user_outlined, color: AppColors.textSecondaryOf(context), size: 18),
              ],
            ),
            const SizedBox(height: 4),
            if (_isVerified)
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  const Text('Verified Healthcare Professional', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.pending_outlined, color: AppColors.warning, size: 14),
                  const SizedBox(width: 4),
                  const Text('Verification Pending', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile link copied to clipboard')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.share_outlined, color: AppColors.textPrimaryOf(context), size: 14),
                const SizedBox(width: 6),
                Text('Share Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final expLabel = _experienceYears > 0 ? '$_experienceYears+ Years' : 'Experienced';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: GenericUserAvatar(
                        radius: 50,
                        avatarUrl: _profile?['avatar_url'] as String?,
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: _isOnline ? AppColors.success : AppColors.textTertiaryOf(context)),
                            const SizedBox(width: 4),
                            Text(_isOnline ? 'Online' : 'Offline', style: TextStyle(color: _isOnline ? AppColors.success : AppColors.textTertiaryOf(context), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(_formattedName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                          if (_isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: AppColors.info, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_displaySpecialty, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeroStat(Icons.person_outline, expLabel, 'Experience'),
                          _buildHeroStat(Icons.monetization_on_outlined, '₦${_hourlyRate.toStringAsFixed(0)}/hr', 'Rate'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
      ],
    );
  }

  Widget _buildQuickInfoGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoCard(Icons.videocam_rounded, 'Video Consultation', _isOnline ? 'Available' : 'Unavailable', AppColors.primary),
          _buildInfoCard(Icons.chat_bubble_rounded, 'Chat Support', _isOnline ? 'Available' : 'Unavailable', AppColors.primary),
          _buildInfoCard(Icons.access_time_rounded, 'Response Time', _isOnline ? '~5 min' : 'N/A', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String status, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context), height: 1.2)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _isOnline ? AppColors.success : AppColors.textTertiaryOf(context))),
        ],
      ),
    );
  }

  Widget _buildVerifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceOf(context),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verified & Trusted', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("This doctor's license and qualifications have been verified by Premon Care.", style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.h4);
  }

  Widget _buildAboutSection() {
    return Text(
      _about,
      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.5),
    );
  }

  Widget _buildSpecializations() {
    final specs = _displaySpecialty.isNotEmpty ? [_displaySpecialty] : ['General Medicine'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specs.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_outlined, color: AppColors.success, size: 14),
            const SizedBox(width: 6),
            Text(s, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPatientRating() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4.9', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
            Row(
              children: const [
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient Rating', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, -5))],
          border: Border(top: BorderSide(color: AppColors.borderLightOf(context))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/chat', extra: {
                'doctorId': widget.doctorId,
                'doctorName': _displayName,
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderOf(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(height: 4),
                    Text('Chat', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isOnline
                    ? () => context.push('/select-duration', extra: {
                        'doctorId': widget.doctorId,
                        'doctorName': _displayName,
                        'hourlyRate': _hourlyRate,
                        'isEmergency': widget.isEmergency,
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textTertiaryOf(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.textInverse, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Book Video', style: TextStyle(color: AppColors.textInverse, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('₦${_bookingRate.toStringAsFixed(0)}/hr', style: const TextStyle(color: AppColors.textInverse, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isOnline
                    ? () => context.push('/select-duration', extra: {
                        'doctorId': widget.doctorId,
                        'doctorName': _displayName,
                        'hourlyRate': _hourlyRate,
                        'isEmergency': widget.isEmergency,
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEmergency ? AppColors.error : AppColors.success,
                  disabledBackgroundColor: AppColors.textTertiaryOf(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isEmergency ? Icons.flash_on_rounded : Icons.calendar_today_rounded, color: AppColors.textInverse, size: 16),
                    const SizedBox(width: 8),
                    Text(widget.isEmergency ? 'Emergency' : 'Book Appt.', style: const TextStyle(color: AppColors.textInverse, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
