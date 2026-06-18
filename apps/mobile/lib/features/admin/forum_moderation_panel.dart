import 'package:flutter/material.dart';
import 'admin_scaffold.dart';

class ForumModerationPanel extends StatefulWidget {
  const ForumModerationPanel({super.key});

  @override
  State<ForumModerationPanel> createState() => _ForumModerationPanelState();
}

class _ForumModerationPanelState extends State<ForumModerationPanel> {
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildContentOverview()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildQuickActions()),
              ],
            ),
            const SizedBox(height: 32),
            _buildRecentReports(),
            const SizedBox(height: 32),
            _buildRecentModerationActions(),
            const SizedBox(height: 32),
            _buildBottomBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forum Moderation Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F2042), letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of forum activities, reports, and moderation actions.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text('May 20 – May 26, 2024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Reported Content', '32', '8 High Priority', Icons.flag_outlined, Colors.purple)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('New Posts', '256', '+18% vs last 7 days', Icons.chat_bubble_outline, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('New Users', '128', '+12% vs last 7 days', Icons.people_outline, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Moderation Actions', '47', 'This Week', Icons.shield_outlined, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, MaterialColor color) {
    bool isAlert = subtitle.contains('High Priority');
    bool isPositive = subtitle.contains('+');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color[600], size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F2042))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            subtitle, 
            style: TextStyle(
              fontSize: 11, 
              color: isAlert ? Colors.red[600] : (isPositive ? Colors.green[600] : Colors.grey[500]),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Content Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2042))),
              Text('View Analytics', style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegend(Colors.blue, 'Posts'),
              const SizedBox(width: 16),
              _buildLegend(Colors.teal, 'Replies'),
              const SizedBox(width: 16),
              _buildLegend(Colors.red, 'Reports'),
            ],
          ),
          const SizedBox(height: 24),
          // Simplified chart mockup using CustomPaint
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _MockChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2042))),
          const SizedBox(height: 16),
          _buildQuickActionItem('Review Reported Content', Icons.flag_outlined, Colors.red),
          _buildQuickActionItem('Verify Doctor Answers', Icons.verified_user_outlined, Colors.green),
          _buildQuickActionItem('Manage Categories', Icons.folder_outlined, Colors.purple),
          _buildQuickActionItem('User Moderation', Icons.person_outline, Colors.blue),
          _buildQuickActionItem('Forum Settings', Icons.settings_outlined, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(String title, IconData icon, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color[600], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F2042)))),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F2042))),
              Text('View All', style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _buildReportRow('High', 'Inappropriate language in comment', 'Best weight loss supplements?', 'Sarah J.', '2h ago', Icons.chat_bubble_outline),
          _buildReportRow('Medium', 'Spam or self-promotion', 'How to improve sleep naturally', 'Michael T.', '6h ago', Icons.verified_user_outlined),
          _buildReportRow('Medium', 'Misleading medical information', 'Herbal cure for high blood pressure', 'Amaka P.', '7h ago', Icons.psychology_outlined),
          _buildReportRow('Low', 'Off-topic content', 'Foods for a healthy heart', 'Chinedu O.', '10h ago', Icons.chat_bubble_outline),
        ],
      ),
    );
  }

  Widget _buildReportRow(String priority, String reason, String post, String reporter, String timeAgo, IconData icon) {
    Color pColor = priority == 'High' ? Colors.red : (priority == 'Medium' ? Colors.orange : Colors.green);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(priority, style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blue[600], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                const SizedBox(height: 4),
                Text('In post: "$post"', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                const SizedBox(height: 4),
                Text('Reported by $reporter • $timeAgo', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Text('Pending', style: TextStyle(color: Colors.red[600], fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Icon(Icons.more_vert, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildRecentModerationActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Moderation Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F2042))),
              Text('View All', style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionRow('Doctor answer approved', 'Dr. Ibrahim Musa • Answer in "Managing Diabetes"', Icons.check_circle_outline, Colors.green, 'Approved', 'I'),
          _buildActionRow('Comment removed', 'In post: "Best exercises for beginners"', Icons.delete_outline, Colors.red, 'Removed', 'S'),
          _buildActionRow('User warning issued', 'User: Bright Wellness\nReason: Repeated self-promotion', Icons.warning_amber_rounded, Colors.orange, 'Warning', 'B'),
          _buildActionRow('Post locked', 'In post: "Alternative cancer treatments"', Icons.lock_outline, Colors.blue, 'Locked', 'U'),
        ],
      ),
    );
  }

  Widget _buildActionRow(String action, String details, IconData icon, MaterialColor color, String badge, String initial) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
            child: Icon(icon, color: color[600], size: 20),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                const SizedBox(height: 4),
                Text('By Admin • 1h ago', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: TextStyle(color: color[600], fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Icon(Icons.more_vert, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF0F62FE), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keep the community safe and trustworthy.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                const SizedBox(height: 4),
                Text('Your moderation helps maintain a healthy environment for everyone.', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey[200]!..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw horizontal grid lines and Y-axis labels
    for (int i = 0; i <= 4; i++) {
      double y = size.height - (i * (size.height / 4));
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
      
      textPainter.text = TextSpan(text: '${i * 50}', style: TextStyle(color: Colors.grey[500], fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw X-axis labels
    final days = ['May 20', 'May 21', 'May 22', 'May 23', 'May 24', 'May 25', 'May 26'];
    double stepX = (size.width - 30) / (days.length - 1);
    for (int i = 0; i < days.length; i++) {
      double x = 30 + (i * stepX);
      textPainter.text = TextSpan(text: days[i], style: TextStyle(color: Colors.grey[500], fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, size.height + 10));
    }

    // Mock data points
    final posts = [100, 140, 130, 160, 130, 170, 150];
    final replies = [60, 80, 70, 90, 75, 80, 75];
    final reports = [20, 30, 20, 30, 25, 30, 25];

    _drawPath(canvas, size, posts, Colors.blue, stepX);
    _drawPath(canvas, size, replies, Colors.teal, stepX);
    _drawPath(canvas, size, reports, Colors.red, stepX);
  }

  void _drawPath(Canvas canvas, Size size, List<int> data, Color color, double stepX) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      double x = 30 + (i * stepX);
      double y = size.height - ((data[i] / 200) * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
