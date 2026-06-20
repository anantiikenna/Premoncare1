import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/global_user_avatar.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  int _selectedTabIndex = 0;
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2042)),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined, color: Color(0xFF0F62FE)),
            const SizedBox(width: 8),
            const Text('Premon', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
            Text('Care', style: TextStyle(color: Colors.cyan[600], fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F2042)), onPressed: () => context.push('/notifications')),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: GlobalUserAvatar(radius: 16),
          )
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          _buildSubFilters(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildStandardCard(
                  'General Health',
                  Colors.teal,
                  Icons.monitor_heart_outlined,
                  'How can I naturally lower my blood pressure?',
                  'I was recently told my blood pressure is a bit high (around 145/95). I don\'t want to go on medication if I can avoid it. What lifestyle...',
                  '2h ago',
                  28,
                  34,
                  256,
                ),
                const SizedBox(height: 16),
                _buildStandardCard(
                  'Nutrition',
                  Colors.orange,
                  Icons.apple_outlined,
                  'Is intermittent fasting safe?',
                  'I want to try intermittent fasting for weight loss. Is it safe for everyone?',
                  '1d ago',
                  22,
                  31,
                  142,
                ),
                const SizedBox(height: 16),
                _buildStandardCard(
                  'Mental Health',
                  Colors.purple,
                  Icons.psychology_outlined,
                  'Feeling anxious all the time – need advice',
                  'Lately I\'ve been feeling anxious and overwhelmed for no clear reason. It\'s affecting my sleep and focus. Any tips...',
                  '2d ago',
                  16,
                  27,
                  118,
                ),
                const SizedBox(height: 16),
                _buildPollCard(),
                const SizedBox(height: 24),
                _buildImpactBanner(),
                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Activity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F2042))),
          const SizedBox(height: 4),
          Text('Manage your posts, replies and interactions in the community.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'title': 'My Posts', 'icon': Icons.article_outlined},
      {'title': 'My Replies', 'icon': Icons.chat_bubble_outline},
      {'title': 'Saved', 'icon': Icons.bookmark_border},
      {'title': 'Following', 'icon': Icons.people_outline},
    ];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: isSelected ? const Border(bottom: BorderSide(color: Color(0xFF0F62FE), width: 2)) : null,
                ),
                child: Column(
                  children: [
                    Icon(tab['icon'] as IconData, color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[500], size: 20),
                    const SizedBox(height: 4),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubFilters() {
    final filters = ['All', 'Questions', 'Discussions', 'Polls'];
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandardCard(String category, MaterialColor color, IconData icon, String title, String body, String timeAgo, int replies, int likes, int views) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(6)),
                      child: Text(category, style: TextStyle(color: color[700], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(6)),
                      child: Text('Published', style: TextStyle(color: Colors.teal[700], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('$replies Replies', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite_border, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('$likes Likes', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('$views Views', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPollCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart, color: Color(0xFF0F62FE), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                  child: const Text('Poll', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                const Text('What\'s your go-to stress relief activity?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                const SizedBox(height: 4),
                Text('Let\'s see what works best for our community!', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                _buildPollOption('Exercise / Workout', 0.45, '45%'),
                _buildPollOption('Meditation / Breathing', 0.30, '30%'),
                _buildPollOption('Listening to Music', 0.15, '15%'),
                _buildPollOption('Talking to someone', 0.10, '10%'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('48 Votes', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('5d ago', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(6)),
                      child: Text('Published', style: TextStyle(color: Colors.teal[700], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPollOption(String title, double fraction, String percentStr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF0F2042)))),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(3)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xFF0F62FE), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(percentStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F2042)), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[50]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF0F62FE), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Community Impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                const SizedBox(height: 4),
                Text('You\'ve made 12 posts and 36 replies. Keep sharing and helping others!', style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImpactStat(Icons.article_outlined, '12', 'Posts', const Color(0xFF0F62FE)),
              const SizedBox(width: 12),
              _buildImpactStat(Icons.chat_bubble_outline, '36', 'Replies', const Color(0xFF0F62FE)),
              const SizedBox(width: 12),
              _buildImpactStat(Icons.favorite_border, '186', 'Likes Received', Colors.red),
              const SizedBox(width: 12),
              _buildImpactStat(Icons.visibility_outlined, '1.2K', 'Views', const Color(0xFF0F62FE)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImpactStat(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
        Text(label, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
      ],
    );
  }
}
