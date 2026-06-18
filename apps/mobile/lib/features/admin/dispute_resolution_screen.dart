import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'admin_scaffold.dart';

class DisputeResolutionScreen extends ConsumerStatefulWidget {
  const DisputeResolutionScreen({super.key});

  @override
  ConsumerState<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends ConsumerState<DisputeResolutionScreen> {
  final primaryColor = const Color(0xFF0F62FE);
  final bgColor = const Color(0xFFF8FAFC);
  String selectedFilter = 'All';

  final filters = ['All', 'Payments', 'Consultation', 'Refunds', 'Fraud', 'Escalated', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildFilterChips(),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDisputesList()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildRightColumn()),
                ],
              )
            else
              Column(
                children: [
                  _buildDisputesList(),
                  const SizedBox(height: 32),
                  _buildRightColumn(),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dispute Resolution Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage, review and resolve disputes fairly and efficiently.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildIconButton(Icons.search),
            const SizedBox(width: 12),
            _buildIconButton(Icons.filter_list, label: 'Filter'),
          ],
        )
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E293B)),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Open Disputes', '24', '8', true, Icons.warning_amber, Colors.orange),
          const SizedBox(width: 16),
          _buildStatCard('Pending Review', '12', '3', true, Icons.access_time, Colors.amber),
          const SizedBox(width: 16),
          _buildStatCard('Resolved Cases', '148', '16', true, Icons.check_circle, Colors.green),
          const SizedBox(width: 16),
          _buildStatCard('High Risk', '5', '2', true, Icons.flag, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change, bool isUp, IconData icon, MaterialColor color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color[600], size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: isUp ? Colors.green[600] : Colors.red[600]),
              const SizedBox(width: 4),
              Text(
                '$change vs yesterday',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isUp ? Colors.green[600] : Colors.red[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => selectedFilter = filter);
              },
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisputesList() {
    return Column(
      children: [
        _buildDisputeCard(
          icon: Icons.account_balance_wallet,
          iconColor: Colors.orange,
          title: 'Payment Not Confirmed',
          description: 'Patient claims N12,000 payment was sent but consultation was denied.',
          patientName: 'Sarah James',
          doctorName: 'Dr. Ibrahim Musa',
          disputeId: '#DSP-2025-0512',
          timeAgo: '2 hrs ago',
          amount: 'N12,000',
          badgeText: 'High Risk',
          badgeColor: Colors.red,
        ),
        _buildDisputeCard(
          icon: Icons.videocam,
          iconColor: Colors.blue,
          title: 'Session Ended Unexpectedly',
          description: 'Video consultation disconnected after 4 minutes.',
          patientName: 'Mark Daniel',
          doctorName: 'Dr. Adaora Nwosu',
          disputeId: '#DSP-2025-0511',
          timeAgo: '5 hrs ago',
          amount: 'N8,500',
          badgeText: 'Waiting for Doctor',
          badgeColor: Colors.amber,
        ),
        _buildDisputeCard(
          icon: Icons.flag,
          iconColor: Colors.red,
          title: 'Suspicious Receipt Upload',
          description: 'Possible edited payment receipt detected.',
          patientName: 'Blessing Okafor',
          doctorName: 'Dr. David Paul',
          disputeId: '#DSP-2025-0510',
          timeAgo: '1 day ago',
          amount: 'N15,000',
          badgeText: 'High Risk',
          badgeColor: Colors.red,
        ),
        _buildDisputeCard(
          icon: Icons.refresh,
          iconColor: Colors.green,
          title: 'Refund Request',
          description: 'Patient requested refund due to duplicate payment.',
          patientName: 'John Adeyemi',
          doctorName: 'Dr. Chinelo Okeke',
          disputeId: '#DSP-2025-0509',
          timeAgo: '1 day ago',
          amount: 'N6,000',
          badgeText: 'Awaiting Response',
          badgeColor: Colors.green,
        ),
        _buildDisputeCard(
          icon: Icons.chat_bubble,
          iconColor: Colors.purple,
          title: 'Doctor Behavior Complaint',
          description: 'Patient reported unprofessional communication.',
          patientName: 'Esther Bassey',
          doctorName: 'Dr. Ibrahim Musa',
          disputeId: '#DSP-2025-0508',
          timeAgo: '2 days ago',
          amount: null,
          badgeText: 'In Investigation',
          badgeColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildDisputeCard({
    required IconData icon,
    required MaterialColor iconColor,
    required String title,
    required String description,
    required String patientName,
    required String doctorName,
    required String disputeId,
    required String timeAgo,
    required String? amount,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor[600], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeText == 'High Risk') ...[
                                Icon(Icons.warning_amber, size: 12, color: badgeColor),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                badgeText,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                child: Text(patientName[0], style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Text(patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('vs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                child: Text(doctorName.startsWith('Dr.') ? doctorName.substring(4, 5) : doctorName[0], style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Text(doctorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(disputeId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              _buildDividerDot(),
              Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              if (amount != null) ...[
                _buildDividerDot(),
                Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle)),
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildQuickActionItem(Icons.note_add, Colors.green, 'New Dispute', 'Create new dispute'),
              _buildQuickActionItem(Icons.upload, Colors.blue, 'Upload Evidence', 'Add file or document'),
              _buildQuickActionItem(Icons.settings, Colors.blue, 'Bulk Actions', 'Update multiple cases'),
              _buildQuickActionItem(Icons.warning_amber, Colors.orange, 'Escalated Cases', 'View escalated only'),
              _buildQuickActionItem(Icons.gpp_bad, Colors.red, 'Fraud Monitoring', 'High risk activities', showDivider: false),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dispute Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Row(
                children: [
                  Text('This Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 14),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: DonutChartPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('189', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Total', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInsightLegendRow(Colors.orange, 'Open', '24 (12.7%)'),
              _buildInsightLegendRow(Colors.amber, 'Pending', '12 (6.3%)'),
              _buildInsightLegendRow(const Color(0xFF10B981), 'Resolved', '148 (78.3%)'),
              _buildInsightLegendRow(Colors.red, 'Escalated', '5 (2.6%)'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.verified, color: primaryColor, size: 20),
              ),
              const SizedBox(height: 16),
              const Text(
                'We ensure fair, secure and transparent resolution for all parties involved.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Learn more', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: primaryColor),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, MaterialColor color, String title, String subtitle, {bool showDivider = true}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color[600], size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF64748B)),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title functionality coming soon')),
            );
          },
        ),
        if (showDivider) const Divider(height: 1, indent: 70),
      ],
    );
  }

  Widget _buildInsightLegendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        ],
      ),
    );
  }


}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - (paint.strokeWidth / 2);

    // Data segments: Resolved (78.3%), Open (12.7%), Pending (6.3%), Escalated (2.6%)
    // Let's approximate the angles
    final segments = [
      {'color': const Color(0xFF10B981), 'sweep': 0.783}, // Green
      {'color': Colors.orange, 'sweep': 0.127}, // Orange
      {'color': Colors.amber, 'sweep': 0.063}, // Yellow
      {'color': Colors.red, 'sweep': 0.026}, // Red
    ];

    double startAngle = -math.pi / 2; // Start at top

    for (var segment in segments) {
      paint.color = segment['color'] as Color;
      final sweepAngle = (segment['sweep'] as double) * 2 * math.pi;
      
      // Draw arc with a small gap
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05, 
        sweepAngle - 0.1, 
        false, 
        paint
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
