import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
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
          .select('full_name, specialty, about, experience_years, hourly_rate, consultation_fee, verification_status, avatar_url')
          .eq('id', widget.doctorId)
          .single();
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      debugPrint('Error fetching doctor profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayName => _profile?['full_name'] as String? ?? widget.doctorName;
  String get _displaySpecialty => _profile?['specialty'] as String? ?? widget.specialty;
  double get _hourlyRate => (_profile?['hourly_rate'] as num?)?.toDouble() ?? 5000.0;
  int get _experienceYears => _profile?['experience_years'] as int? ?? 0;
  String get _about => _profile?['about'] as String? ?? 'Dedicated and compassionate healthcare professional committed to delivering quality patient care.';

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F62FE))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                        _buildHeroCard(primaryColor),
                        const SizedBox(height: 24),
                        _buildQuickInfoGrid(),
                        const SizedBox(height: 24),
                        _buildVerifiedBanner(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('About Dr. ${_displayName.replaceFirst('Dr. ', '')}'),
                        const SizedBox(height: 12),
                        _buildAboutSection(primaryColor),
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
          _buildBottomActionBar(context, primaryColor),
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
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 24),
            ),
            Row(
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
                const Text('Doctor Public Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 18),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text('Verified Healthcare Professional', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.share_outlined, color: Color(0xFF1E293B), size: 14),
              SizedBox(width: 6),
              Text('Share Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Color primaryColor) {
    final expLabel = _experienceYears > 0 ? '$_experienceYears+ Years' : 'Experienced';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF032B69), Color(0xFF0A47A5)],
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('Available', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
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
                          Flexible(child: Text('Dr. ${_displayName.replaceFirst('Dr. ', '')}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_displaySpecialty, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
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
          _buildInfoCard(Icons.videocam_rounded, 'Video Consultation', 'Available', const Color(0xFF3B82F6)),
          _buildInfoCard(Icons.chat_bubble_rounded, 'Chat Support', 'Available', const Color(0xFFA855F7)),
          _buildInfoCard(Icons.access_time_rounded, 'Response Time', '~5 min', const Color(0xFFF59E0B)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), height: 1.2)),
          const SizedBox(height: 4),
          Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildVerifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.verified_user_outlined, color: Color(0xFF3B82F6), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verified & Trusted', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text("This doctor's license and qualifications have been verified by Premon Care.", style: TextStyle(color: Color(0xFF475569), fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }

  Widget _buildAboutSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _about,
          style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
        ),
      ],
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
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_outlined, color: Color(0xFF10B981), size: 14),
            const SizedBox(width: 6),
            Text(s, style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPatientRating() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4.9', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
            Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
              ],
            ),
            SizedBox(height: 8),
            Text('Patient Rating', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, Color primaryColor) {
    final hourlyRate = _hourlyRate;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
          border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: primaryColor, size: 20),
                    const SizedBox(height: 4),
                    Text('Chat', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/select-duration', extra: {
                  'doctorId': widget.doctorId,
                  'doctorName': _displayName,
                  'hourlyRate': hourlyRate,
                  'isEmergency': widget.isEmergency,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Book Video', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('₦${hourlyRate.toStringAsFixed(0)}/hr', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/select-duration', extra: {
                  'doctorId': widget.doctorId,
                  'doctorName': _displayName,
                  'hourlyRate': hourlyRate,
                  'isEmergency': widget.isEmergency,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isEmergency ? Icons.flash_on_rounded : Icons.calendar_today_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(widget.isEmergency ? 'Emergency' : 'Book Appt.', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
