import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'admin_scaffold.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedRange = 'This Month';
  final List<String> _ranges = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year'];

  double? _chartHoverX;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderRow(),
                  const SizedBox(height: 24),
                  _buildFilterRow(),
                  const SizedBox(height: 24),
                  _buildKpiGrid(),
                  const SizedBox(height: 32),
                  _buildAppointmentsOverviewChart(),
                  const SizedBox(height: 32),
                  _buildSecondaryCharts(),
                  const SizedBox(height: 32),
                  _buildTopDoctors(),
                  const SizedBox(height: 32),
                  _buildReportsShortcuts(),
                  const SizedBox(height: 32),
                  _buildFooterAlert(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports & Insights Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
            SizedBox(height: 4),
            Text('Track performance, usage and key metrics in real-time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: const [
              Icon(Icons.ios_share_rounded, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text('Export Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ..._ranges.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () => setState(() => _selectedRange = range),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F62FE) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFF1F5F9)),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Row(
              children: const [
                Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Custom Range', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildKpiCard('Total Users', '24,563', '18.6%', Icons.group_outlined, const Color(0xFF10B981)),
        _buildKpiCard('Active Doctors', '1,248', '14.2%', Icons.medical_services_outlined, const Color(0xFF3B82F6)),
        _buildKpiCard('Total Appointments', '6,782', '21.3%', Icons.calendar_month_outlined, const Color(0xFF8B5CF6)),
        _buildKpiCard('Total Revenue', '₦24.8M', '16.7%', Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 12),
              const SizedBox(width: 2),
              Text(trend, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              const SizedBox(width: 4),
              const Text('vs Apr', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsOverviewChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('Appointments Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  SizedBox(width: 6),
                  Icon(Icons.info_outline_rounded, color: Color(0xFFCBD5E1), size: 16),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: const [
                    Text('Line Chart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF3B82F6), 'Completed'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFEF4444), 'Cancelled'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFF10B981), 'Rescheduled'),
            ],
          ),
          const SizedBox(height: 24),
          // Interactive Chart Area
          SizedBox(
            height: 220,
            width: double.infinity,
            child: GestureDetector(
              onPanDown: (details) => setState(() => _chartHoverX = details.localPosition.dx),
              onPanUpdate: (details) => setState(() => _chartHoverX = details.localPosition.dx),
              onPanEnd: (_) => setState(() => _chartHoverX = null),
              onPanCancel: () => setState(() => _chartHoverX = null),
              child: CustomPaint(
                painter: _InteractiveLineChartPainter(hoverX: _chartHoverX),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSecondaryCharts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appointments by Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 24),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _DonutChartPainter(),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('6,782', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                          Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDonutLegend(const Color(0xFF3B82F6), 'Consultation', '55%', '3,730'),
                _buildDonutLegend(const Color(0xFF10B981), 'Follow-up', '25%', '1,695'),
                _buildDonutLegend(const Color(0xFF8B5CF6), 'Lab Test', '12%', '814'),
                _buildDonutLegend(const Color(0xFFF59E0B), 'Emergency', '8%', '543'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Users Growth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                      child: const Text('This Month', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('24,563', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const Text('Total Users', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                Row(
                  children: const [
                    Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 10),
                    SizedBox(width: 2),
                    Text('18.6%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                    SizedBox(width: 4),
                    Text('vs Apr', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _BarChartPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutLegend(Color color, String label, String pct, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                Row(
                  children: [
                    Text(pct, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const Text(' (', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    Text(val, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    const Text(')', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDoctors() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Top Performing Doctors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(flex: 3, child: Text('Doctor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
              Expanded(flex: 2, child: Text('Appointments', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
              Expanded(flex: 2, child: Text('Completed', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
              Expanded(flex: 2, child: Text('Rating', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
              Expanded(flex: 2, child: Text('Revenue', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
              SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 12),
          _buildDoctorRow('Dr. Adaora Nwosu', 'Cardiologist', 'A', '450', '428', '96%', '4.9', '₦3.6M'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildDoctorRow('Dr. Ibrahim Umar', 'General Physician', 'I', '382', '362', '95%', '4.8', '₦2.8M'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildDoctorRow('Dr. David Paul', 'Orthopedic Surgeon', 'D', '312', '298', '96%', '4.7', '₦2.2M'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildDoctorRow('Dr. Chinelo Okeke', 'Dermatologist', 'C', '289', '276', '96%', '4.9', '₦1.9M'),
        ],
      ),
    );
  }

  Widget _buildDoctorRow(String name, String specialty, String initial, String total, String completed, String pct, String rating, String revenue) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                child: Text(initial, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                    Text(specialty, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(total, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(completed, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text(pct, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(revenue, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))),
        const SizedBox(width: 8),
        const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8), size: 16),
      ],
    );
  }

  Widget _buildReportsShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reports Shortcuts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildShortcutCard('User Analytics', 'Detailed user insights', Icons.bar_chart_rounded, const Color(0xFF10B981)),
              _buildShortcutCard('Doctor Performance', 'Track doctor metrics', Icons.group_outlined, const Color(0xFF3B82F6)),
              _buildShortcutCard('Financial Reports', 'Revenue & transactions', Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B)),
              _buildShortcutCard('Appointment Reports', 'Booking & trends', Icons.calendar_today_outlined, const Color(0xFF8B5CF6)),
              _buildShortcutCard('System Reports', 'System & audit logs', Icons.settings_system_daydream_outlined, const Color(0xFF6366F1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDBEAFE))),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 24),
          const SizedBox(width: 12),
          const Expanded(child: Text('All reports are updated in real-time and data is securely encrypted.', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4))),
          Row(
            children: const [
              Text('Learn more', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w800)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractiveLineChartPainter extends CustomPainter {
  final double? hoverX;
  
  // Dummy data arrays representing the peaks and valleys
  final List<double> completedData = [0.4, 0.6, 0.5, 0.7, 0.8, 0.6, 0.5, 0.5, 0.4, 0.5, 0.7, 0.9, 0.8, 0.6, 0.7, 0.6, 0.7, 0.6, 0.4, 0.6, 0.5];
  final List<double> rescheduledData = [0.2, 0.25, 0.2, 0.3, 0.25, 0.2, 0.2, 0.25, 0.28, 0.2, 0.25, 0.3, 0.28, 0.25, 0.28, 0.25, 0.28, 0.25, 0.2, 0.3, 0.25];
  final List<double> cancelledData = [0.05, 0.08, 0.06, 0.1, 0.08, 0.06, 0.08, 0.1, 0.08, 0.06, 0.12, 0.1, 0.05, 0.08, 0.12, 0.1, 0.1, 0.05, 0.08, 0.1, 0.08];

  _InteractiveLineChartPainter({this.hoverX});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridLines(canvas, size);
    _drawLabels(canvas, size);

    // Draw the 3 lines
    _drawLine(canvas, size, cancelledData, const Color(0xFFEF4444));
    _drawLine(canvas, size, rescheduledData, const Color(0xFF10B981));
    _drawLine(canvas, size, completedData, const Color(0xFF3B82F6));

    if (hoverX != null && hoverX! >= 0 && hoverX! <= size.width) {
      _drawTooltip(canvas, size, hoverX!);
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      final y = size.height - (i * (size.height / 5));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Y-Axis
    final yLabels = ['0', '500', '1K', '1.5K', '2K', '2.5K'];
    for (int i = 0; i < yLabels.length; i++) {
      textPainter.text = TextSpan(text: yLabels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, size.height - (i * (size.height / 5)) - 12));
    }

    // X-Axis
    final xLabels = ['1 May', '6 May', '11 May', '16 May', '21 May', '26 May', '31 May'];
    final stepX = size.width / (xLabels.length - 1);
    for (int i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(text: xLabels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700));
      textPainter.layout();
      textPainter.paint(canvas, Offset((i * stepX) - (textPainter.width / 2), size.height + 8));
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (data[i - 1] * size.height);
        // smooth curve
        path.quadraticBezierTo(prevX + (stepX / 2), prevY, x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawTooltip(Canvas canvas, Size size, double x) {
    // Find closest index
    final stepX = size.width / (completedData.length - 1);
    final index = (x / stepX).round().clamp(0, completedData.length - 1);
    final snappedX = index * stepX;

    // Draw vertical line
    final linePaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(snappedX, 0), Offset(snappedX, size.height), linePaint);

    // Draw dots
    _drawDot(canvas, snappedX, size.height - (completedData[index] * size.height), const Color(0xFF3B82F6));
    _drawDot(canvas, snappedX, size.height - (rescheduledData[index] * size.height), const Color(0xFF10B981));
    _drawDot(canvas, snappedX, size.height - (cancelledData[index] * size.height), const Color(0xFFEF4444));

    // Draw Tooltip Box
    const boxWidth = 120.0;
    const boxHeight = 85.0;
    double boxX = snappedX + 10;
    if (boxX + boxWidth > size.width) {
      boxX = snappedX - boxWidth - 10;
    }
    double boxY = 20.0;

    final boxRect = RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight), const Radius.circular(8));
    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(boxRect.shift(const Offset(0, 4)), shadowPaint);
    
    final boxPaint = Paint()..color = Colors.white;
    canvas.drawRRect(boxRect, boxPaint);
    
    // Tooltip border
    canvas.drawRRect(boxRect, Paint()..color = const Color(0xFFF1F5F9)..style = PaintingStyle.stroke..strokeWidth = 1);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Date Header
    textPainter.text = const TextSpan(text: '16 May 2025', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w700));
    textPainter.layout();
    textPainter.paint(canvas, Offset(boxX + 12, boxY + 12));

    // Completed
    _drawTooltipRow(canvas, textPainter, 'Completed', '1,842', const Color(0xFF3B82F6), boxX + 12, boxY + 30);
    _drawTooltipRow(canvas, textPainter, 'Cancelled', '245', const Color(0xFFEF4444), boxX + 12, boxY + 46);
    _drawTooltipRow(canvas, textPainter, 'Rescheduled', '312', const Color(0xFF10B981), boxX + 12, boxY + 62);
  }

  void _drawTooltipRow(Canvas canvas, TextPainter textPainter, String label, String value, Color color, double x, double y) {
    canvas.drawCircle(Offset(x + 3, y + 5), 3, Paint()..color = color);
    textPainter.text = TextSpan(text: label, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9, fontWeight: FontWeight.w700));
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 10, y));

    textPainter.text = TextSpan(text: value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9, fontWeight: FontWeight.w900));
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 75, y));
  }

  void _drawDot(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _InteractiveLineChartPainter oldDelegate) {
    return oldDelegate.hoverX != hoverX;
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 35.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Consultation 55%
    paint.color = const Color(0xFF3B82F6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 1.1, false, paint);

    // Follow-up 25%
    paint.color = const Color(0xFF10B981);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.6, math.pi * 0.5, false, paint);

    // Lab Test 12%
    paint.color = const Color(0xFF8B5CF6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 1.1, math.pi * 0.24, false, paint);

    // Emergency 8%
    paint.color = const Color(0xFFF59E0B);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 1.34, math.pi * 0.16, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
    final secondaryPaint = Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.4)..style = PaintingStyle.fill;

    // 5 groups of 2 bars
    final groups = 5;
    final stepX = size.width / groups;
    final barWidth = 8.0;

    final heights1 = [0.4, 0.6, 0.7, 0.8, 0.9];
    final heights2 = [0.3, 0.5, 0.6, 0.8, 0.85];

    for (int i = 0; i < groups; i++) {
      final x = (i * stepX) + (stepX / 2) - barWidth;
      
      final h1 = size.height * heights1[i];
      final r1 = RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h1, barWidth, h1), const Radius.circular(4));
      canvas.drawRRect(r1, secondaryPaint);

      final h2 = size.height * heights2[i];
      final r2 = RRect.fromRectAndRadius(Rect.fromLTWH(x + barWidth + 4, size.height - h2, barWidth, h2), const Radius.circular(4));
      canvas.drawRRect(r2, paint);
    }
    
    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = ['1 May', '8 May', '15 May', '22 May', '29 May'];
    for (int i = 0; i < groups; i++) {
      textPainter.text = TextSpan(text: labels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700));
      textPainter.layout();
      final x = (i * stepX) + (stepX / 2) - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(x, size.height + 8));
    }

    // Y labels
    final yLabels = ['0', '10K', '20K', '30K'];
    for (int i = 0; i < yLabels.length; i++) {
      textPainter.text = TextSpan(text: yLabels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700));
      textPainter.layout();
      textPainter.paint(canvas, Offset(-20, size.height - (i * (size.height / 3)) - 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
