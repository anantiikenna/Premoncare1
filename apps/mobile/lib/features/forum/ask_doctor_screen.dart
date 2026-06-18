import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AskDoctorScreen extends StatelessWidget {
  const AskDoctorScreen({super.key});

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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            _buildCategoriesStrip(),
            const SizedBox(height: 24),
            _buildHeroBanner(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Top Verified Doctors'),
            _buildFeaturedDoctors(context),
            const SizedBox(height: 32),
            _buildSectionTitle('Recent Verified Answers'),
            _buildRecentVerifiedAnswers(),
            const SizedBox(height: 32),
            _buildSectionTitle('Most Helpful Discussions'),
            _buildMostHelpfulDiscussions(),
            const SizedBox(height: 32),
            _buildBottomCTASection(context),
            const SizedBox(height: 32),
            _buildStatisticsFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask a Doctor', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F2042))),
          const SizedBox(height: 4),
          Text('Get answers from verified healthcare professionals.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Search health questions...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStrip() {
    final categories = [
      {'name': 'All', 'icon': null, 'color': const Color(0xFF0F62FE), 'bg': const Color(0xFF0F62FE), 'text': Colors.white},
      {'name': 'Heart Health', 'icon': Icons.favorite_border, 'color': Colors.red, 'bg': Colors.white, 'text': const Color(0xFF0F2042)},
      {'name': 'Mental Health', 'icon': Icons.psychology_outlined, 'color': Colors.purple, 'bg': Colors.white, 'text': const Color(0xFF0F2042)},
      {'name': 'Nutrition', 'icon': Icons.apple_outlined, 'color': Colors.orange, 'bg': Colors.white, 'text': const Color(0xFF0F2042)},
      {'name': 'Pregnancy', 'icon': Icons.pregnant_woman_outlined, 'color': Colors.pink, 'bg': Colors.white, 'text': const Color(0xFF0F2042)},
      {'name': 'General Health', 'icon': Icons.health_and_safety_outlined, 'color': Colors.teal, 'bg': Colors.white, 'text': const Color(0xFF0F2042)},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final hasIcon = cat['icon'] != null;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cat['bg'] as Color,
              border: Border.all(color: hasIcon ? (cat['color'] as MaterialColor)[100]! : Colors.transparent),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasIcon) ...[
                  Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    color: cat['text'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F62FE), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined, color: Color(0xFF0F62FE), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need urgent advice?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Ask a verified doctor and receive professional responses.', style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.push('/forum/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F62FE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ask Question', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2042))),
          const Text('View all', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFeaturedDoctors(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildDoctorCard(context, 'Dr. Ibrahim Musa', 'Internal Medicine', '1,245', '4.9', 'I'),
          _buildDoctorCard(context, 'Dr. Adaeze Nwosu', 'Nutritionist', '987', '4.8', 'A'),
          _buildDoctorCard(context, 'Dr. Chinedu Okafor', 'Cardiologist', '1,102', '4.9', 'C'),
          Container(
            width: 50,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: const Icon(Icons.chevron_right, color: Color(0xFF0F2042)),
          )
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, String name, String specialty, String answers, String rating, String authorInitial) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F62FE))),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2042)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.teal[50], border: Border.all(color: Colors.teal[200]!), borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 10, color: Colors.teal[700]),
                const SizedBox(width: 2),
                Text('Verified Doctor', style: TextStyle(fontSize: 8, color: Colors.teal[700], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(specialty, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$answers Answers', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 12),
                  const SizedBox(width: 2),
                  Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: () => context.push('/doctor-search'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFF0F62FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Profile', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentVerifiedAnswers() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF10B981),
                child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                      child: Text('Heart Health', style: TextStyle(color: Colors.red[700], fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    const Text('How can I naturally lower my blood pressure?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Asked by '),
                          const TextSpan(text: 'Sarah J.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2042))),
                          const TextSpan(text: ' • 2h ago'),
                        ],
                      ),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF0F62FE),
                          child: Text('I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Dr. Ibrahim Musa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2042))),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 12, color: Color(0xFF0F62FE)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal[50], border: Border.all(color: Colors.teal[200]!), borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 8, color: Colors.teal[700]),
                                    const SizedBox(width: 2),
                                    Text('Verified Doctor', style: TextStyle(fontSize: 8, color: Colors.teal[700], fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Internal Medicine', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 10, color: Color(0xFF0F62FE)),
                          SizedBox(width: 4),
                          Text('Verified Medical Response', style: TextStyle(fontSize: 9, color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Lifestyle changes such as reducing sodium intake, regular exercise, maintaining a healthy weight, good sleep habits, and stress management may help lower blood pressure naturally. Consistency is key. If your BP remains high, please consult your doctor.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text('Helpful (24)', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text('Reply', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text('Like (18)', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMostHelpfulDiscussions() {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildHelpfulDiscussionCard('Managing Diabetes Through Diet', 'Dr. Adaeze Nwosu', 235, Colors.teal, Icons.water_drop_outlined, 'A'),
          _buildHelpfulDiscussionCard('Dealing With Anxiety Naturally', 'Dr. Chinedu Okafor', 198, Colors.purple, Icons.psychology_outlined, 'C'),
          _buildHelpfulDiscussionCard('Best Foods for a Healthy Heart', 'Dr. Ibrahim Musa', 176, Colors.orange, Icons.apple_outlined, 'I'),
          Container(
            width: 50,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: const Icon(Icons.chevron_right, color: Color(0xFF0F2042)),
          )
        ],
      ),
    );
  }

  Widget _buildHelpfulDiscussionCard(String title, String doctorName, int votes, MaterialColor color, IconData icon, String authorInitial) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color[200]!)),
                child: Icon(icon, color: color[700], size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2042), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color[200],
                child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Answered by', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                    Text(doctorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2042))),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up, color: color[700], size: 12),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$votes ', style: TextStyle(fontWeight: FontWeight.bold, color: color[700])),
                    TextSpan(text: 'Helpful Votes', style: TextStyle(color: color[700])),
                  ],
                ),
                style: const TextStyle(fontSize: 10),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomCTASection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.edit_note, color: Color(0xFF0F62FE), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Have a health question?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2042))),
                        const SizedBox(height: 4),
                        Text('Create a discussion and get answers from verified doctors.', style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question submitted to doctors'), backgroundColor: Color(0xFF10B981)),
                      );
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 14),
                        SizedBox(width: 4),
                        Text('Ask a Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[50]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF0F62FE), size: 16),
                  const SizedBox(height: 8),
                  Text(
                    'Forum responses are for educational purposes and do not replace professional consultations.',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600], height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!), bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.people_outline, 'Verified Doctors', '248', const Color(0xFF0F62FE)),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildStatItem(Icons.question_answer_outlined, 'Questions Answered', '15,430', Colors.teal),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildStatItem(Icons.diversity_3, 'Community Members', '82,500', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2042))),
          ],
        )
      ],
    );
  }
}
