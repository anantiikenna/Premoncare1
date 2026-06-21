import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime(2025, 5, 28);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousDay() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDay() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsHeader(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('SCHEDULE NAVIGATION'),
                        const SizedBox(height: 16),
                        _buildTabNavigation(),
                        const SizedBox(height: 32),
                        _buildDateSelector(),
                        const SizedBox(height: 24),
                        _buildTimeline(),
                        const SizedBox(height: 32),
                        _buildPerformanceCard(),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CLINICAL OPERATIONS', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Appointments', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
            ],
          ),
          const Spacer(),
          _buildCircleIconButton(Icons.search_rounded),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
      child: Icon(icon, color: AppColors.textPrimaryOf(context), size: 20),
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      children: [
        _buildStatCard('TODAY', '8', AppColors.primary, Icons.calendar_today_rounded),
        const SizedBox(width: 16),
        _buildStatCard('PENDING', '5', AppColors.warning, Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 20),
            Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(20)),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryOf(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
        tabs: const [Tab(text: 'TODAY'), Tab(text: 'UPCOMING'), Tab(text: 'PENDING'), Tab(text: 'PAST')],
      ),
    );
  }

  Widget _buildDateSelector() {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('CLINICAL TIMELINE'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
          child: Row(
            children: [
              GestureDetector(onTap: _previousDay, child: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimaryOf(context))),
              const SizedBox(width: 12),
              Text(dateStr, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              GestureDetector(onTap: _nextDay, child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textPrimaryOf(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final appointments = [
      {'time': '09:30 AM', 'name': 'Sarah Johnson', 'type': 'VIDEO CONSULTATION', 'status': 'COMPLETED', 'color': AppColors.success},
      {'time': '10:45 AM', 'name': 'Emily Davis', 'type': 'CLINICAL REVIEW', 'status': 'UPCOMING', 'color': AppColors.primary},
      {'time': '12:00 PM', 'name': 'CLINICAL BREAK', 'type': '', 'status': 'BREAK', 'color': AppColors.warning},
      {'time': '02:15 PM', 'name': 'Michael Brown', 'type': 'FOLLOW-UP', 'status': 'UPCOMING', 'color': AppColors.primary},
      {'time': '04:30 PM', 'name': 'Jessica Lee', 'type': 'NEW CONSULTATION', 'status': 'UPCOMING', 'color': AppColors.primary},
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          for (int i = 0; i < appointments.length; i++)
            _buildTimelineItem(
              '${appointments[i]['time']}',
              '${appointments[i]['name']}',
              '${appointments[i]['type']}',
              '${appointments[i]['status']}',
              appointments[i]['color'] as Color,
              AppColors.primary,
              isFirst: i == 0,
              isLast: i == appointments.length - 1,
              isBreak: appointments[i]['status'] == 'BREAK',
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String name, String type, String status, Color color, Color primaryColor, {bool isFirst = false, bool isLast = false, bool isBreak = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 65, child: Text(time, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w800))),
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.surfaceOf(context), shape: BoxShape.circle, border: Border.all(color: color, width: 3))),
            if (!isLast) Container(width: 2, height: isBreak ? 50 : 90, color: AppColors.borderLightOf(context)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isBreak ? AppColors.warningLightOf(context) : AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: isBreak ? AppColors.warningLightOf(context) : AppColors.borderLightOf(context))),
            child: isBreak
                ? Row(children: [Icon(Icons.coffee_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 12), Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimaryOf(context)))])
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                            const SizedBox(height: 2),
                            Text(type, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: (status == 'COMPLETED' ? AppColors.success : primaryColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(status == 'COMPLETED' ? Icons.check_rounded : Icons.videocam_rounded, color: status == 'COMPLETED' ? AppColors.success : primaryColor, size: 18)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.slate800, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: AppColors.slate800.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DAILY PROGRESS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('37% Completed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Keep going! You have 5 more clinical sessions today.', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: 0.37, strokeWidth: 8, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppColors.success), strokeCap: StrokeCap.round)),
              const Text('37%', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
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
