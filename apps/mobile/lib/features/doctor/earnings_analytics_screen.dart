import 'package:flutter/material.dart';
import 'dart:math' as math;


class EarningsAnalyticsScreen extends StatefulWidget {
  const EarningsAnalyticsScreen({super.key});

  @override
  State<EarningsAnalyticsScreen> createState() => _EarningsAnalyticsScreenState();
}

class _EarningsAnalyticsScreenState extends State<EarningsAnalyticsScreen> {
  String selectedFilter = 'This Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Earnings & Analytics',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF1E293B)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Date range filtering is being developed. Currently showing all-time earnings.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Track your earnings and performance\nall in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            
            // 1. Time Filters
            _buildTimeFilters(),
            const SizedBox(height: 24),

            // 2. Total Earnings Card
            _buildTotalEarningsCard(),
            const SizedBox(height: 24),

            // 3. Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // 4. Earnings Overview (Line Chart)
            _buildSectionHeader('Earnings Overview', hasDot: true),
            const SizedBox(height: 16),
            _buildEarningsChart(),
            const SizedBox(height: 24),

            // 5. Earnings Breakdown (Donut Chart)
            _buildSectionHeader('Earnings Breakdown', trailing: 'View Details'),
            const SizedBox(height: 16),
            _buildBreakdownChart(),
            const SizedBox(height: 24),

            // 6. Insight Card
            _buildInsightCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Today', 'This Week', 'This Month', 'Custom'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F62FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Row(
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (filter == 'Custom') ...[
                    const SizedBox(width: 4),
                    Icon(Icons.calendar_month_rounded, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                  ]
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F62FE), Color(0xFF0EA5E9), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F62FE).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Earnings',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                '₦14,560',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('18.6%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    SizedBox(width: 8),
                    Text('vs last week', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.8,
              child: _buildWalletIllustration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletIllustration() {
    return SizedBox(
      width: 140,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wallet
          Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Center(
              child: Icon(Icons.payments_rounded, color: Colors.white.withValues(alpha: 0.3), size: 40),
            ),
          ),
          // Coins
          Positioned(
            top: 10,
            right: 20,
            child: _buildCoin(24, 0xFF67E8F9),
          ),
          Positioned(
            top: 25,
            right: 45,
            child: _buildCoin(20, 0xFF22D3EE),
          ),
        ],
      ),
    );
  }

  Widget _buildCoin(double size, int color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: const Center(child: Icon(Icons.payments_rounded, size: 12, color: Colors.white)),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Consultations', '42', '12%', Icons.account_balance_wallet_rounded, const Color(0xFF0F62FE))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Hours Spent', '28h 15m', '8%', Icons.access_time_filled_rounded, const Color(0xFF06B6D4))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('New Patients', '18', '20%', Icons.person_add_alt_1_rounded, const Color(0xFF8B5CF6))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Rating', '4.9', '100%', Icons.stars_rounded, const Color(0xFFF59E0B))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String percent, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF64748B).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (label == 'Rating') 
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16)
              else ...[
                const Icon(Icons.arrow_upward_rounded, color: Color(0xFF22C55E), size: 12),
                Text(percent, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w800)),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Text('vs last week', style: TextStyle(color: const Color(0xFF64748B).withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool hasDot = false, String? trailing}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
        if (hasDot) ...[
          const SizedBox(width: 8),
          const Icon(Icons.circle, size: 8, color: Color(0xFF0F62FE)),
          const SizedBox(width: 4),
          const Text('Earnings (₦)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        const Spacer(),
        if (trailing != null)
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detailed breakdown is being developed. The summary above shows your current earnings overview.')),
              );
            },
            child: Row(
              children: [
                Text(trailing, style: const TextStyle(color: Color(0xFF0F62FE), fontSize: 13, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F62FE), size: 20),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('₹14,560', style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_upward_rounded, color: Color(0xFF22C55E), size: 16),
              const Text('18.6%', style: TextStyle(color: Color(0xFF22C55E), fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const Expanded(child: _LineChartPainterWidget()),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _DonutChartPainterWidget(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹14,560', style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900)),
                    Text('Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildBreakdownItem('Video Consultations', '₦8,640', '59%', const Color(0xFF0F62FE)),
                _buildBreakdownItem('Chat Consultations', '₦3,840', '26%', const Color(0xFF22D3EE)),
                _buildBreakdownItem('Follow-ups', '₦1,760', '12%', const Color(0xFF8B5CF6)),
                _buildBreakdownItem('Other Services', '₦320', '3%', const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
            ),
          ),
          Text(amount, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
            child: Text(percent, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Great progress!', style: TextStyle(color: Color(0xFF166534), fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Your earnings increased by 18.6%\ncompared to last week.',
                  style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
          Image.asset('assets/growth_icon.png', width: 60, errorBuilder: (_, _, _) => const Icon(Icons.bar_chart_rounded, size: 40, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

class _LineChartPainterWidget extends StatelessWidget {
  const _LineChartPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F62FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0F62FE).withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.6),
      Offset(size.width * 0.33, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.66, size.height * 0.2),
      Offset(size.width * 0.83, size.height * 0.6),
      Offset(size.width, size.height * 0.4),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      path.cubicTo(
        p0.dx + (p1.dx - p0.dx) / 2, p0.dy,
        p0.dx + (p1.dx - p0.dx) / 2, p1.dy,
        p1.dx, p1.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = const Color(0xFF0F62FE)..style = PaintingStyle.stroke..strokeWidth = 2.0;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _DonutChartPainterWidget extends StatelessWidget {
  const _DonutChartPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DonutChartPainter(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    void drawSegment(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Video 59%, Chat 26%, Follow-ups 12%, Other 3%
    const startAngle = -math.pi / 2;
    drawSegment(startAngle, 2 * math.pi * 0.59, const Color(0xFF0F62FE));
    drawSegment(startAngle + 2 * math.pi * 0.59, 2 * math.pi * 0.26, const Color(0xFF22D3EE));
    drawSegment(startAngle + 2 * math.pi * 0.85, 2 * math.pi * 0.12, const Color(0xFF8B5CF6));
    drawSegment(startAngle + 2 * math.pi * 0.97, 2 * math.pi * 0.03, const Color(0xFFF59E0B));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
