import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(primaryColor),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsHeader(primaryColor),
                        const SizedBox(height: 32),
                        _buildSectionTitle('SCHEDULE NAVIGATION'),
                        const SizedBox(height: 16),
                        _buildTabNavigation(primaryColor),
                        const SizedBox(height: 32),
                        _buildDateSelector(primaryColor),
                        const SizedBox(height: 24),
                        _buildTimeline(primaryColor),
                        const SizedBox(height: 32),
                        _buildPerformanceCard(primaryColor),
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
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildHeader(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CLINICAL OPERATIONS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              SizedBox(height: 8),
              Text('Appointments', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
    );
  }

  Widget _buildStatsHeader(Color primaryColor) {
    return Row(
      children: [
        _buildStatCard('TODAY', '8', primaryColor, Icons.calendar_today_rounded),
        const SizedBox(width: 16),
        _buildStatCard('PENDING', '5', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 20),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
        tabs: const [Tab(text: 'TODAY'), Tab(text: 'UPCOMING'), Tab(text: 'PENDING'), Tab(text: 'PAST')],
      ),
    );
  }

  Widget _buildDateSelector(Color primaryColor) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('CLINICAL TIMELINE'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              GestureDetector(onTap: _previousDay, child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF1E293B))),
              const SizedBox(width: 12),
              Text(dateStr, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              GestureDetector(onTap: _nextDay, child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(Color primaryColor) {
    final appointments = [
      {'time': '09:30 AM', 'name': 'Sarah Johnson', 'type': 'VIDEO CONSULTATION', 'status': 'COMPLETED', 'color': const Color(0xFF10B981)},
      {'time': '10:45 AM', 'name': 'Emily Davis', 'type': 'CLINICAL REVIEW', 'status': 'UPCOMING', 'color': primaryColor},
      {'time': '12:00 PM', 'name': 'CLINICAL BREAK', 'type': '', 'status': 'BREAK', 'color': const Color(0xFFF59E0B)},
      {'time': '02:15 PM', 'name': 'Michael Brown', 'type': 'FOLLOW-UP', 'status': 'UPCOMING', 'color': primaryColor},
      {'time': '04:30 PM', 'name': 'Jessica Lee', 'type': 'NEW CONSULTATION', 'status': 'UPCOMING', 'color': primaryColor},
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          for (int i = 0; i < appointments.length; i++)
            _buildTimelineItem(
              '${appointments[i]['time']}',
              '${appointments[i]['name']}',
              '${appointments[i]['type']}',
              '${appointments[i]['status']}',
              appointments[i]['color'] as Color,
              primaryColor,
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
        SizedBox(width: 65, child: Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800))),
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 3))),
            if (!isLast) Container(width: 2, height: isBreak ? 50 : 90, color: const Color(0xFFF1F5F9)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isBreak ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: isBreak ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9))),
            child: isBreak
                ? Row(children: [const Icon(Icons.coffee_rounded, color: Color(0xFFF59E0B), size: 16), const SizedBox(width: 12), Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)))])
                : Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF0F62FE),
                        child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            Text(type, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: (status == 'COMPLETED' ? const Color(0xFF10B981) : primaryColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(status == 'COMPLETED' ? Icons.check_rounded : Icons.videocam_rounded, color: status == 'COMPLETED' ? const Color(0xFF10B981) : primaryColor, size: 18)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY PROGRESS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(height: 8),
                Text('37% Completed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Keep going! You have 5 more clinical sessions today.', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: 0.37, strokeWidth: 8, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)), strokeCap: StrokeCap.round)),
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


