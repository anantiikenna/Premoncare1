import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
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
          IconButton(icon: const Icon(Icons.bookmark_border, color: Color(0xFF0F2042)), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post saved to bookmarks'), backgroundColor: Color(0xFF10B981)),
            );
          }),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0F2042)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, color: Colors.red),
                        title: const Text('Report Post'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post reported'), backgroundColor: Color(0xFF10B981)),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined, color: Color(0xFF0F62FE)),
                        title: const Text('Share Post'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post link copied to clipboard'), backgroundColor: Color(0xFF10B981)),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.link, color: Colors.teal),
                        title: const Text('Copy Link'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard'), backgroundColor: Color(0xFF10B981)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBreadcrumbs(),
                  const SizedBox(height: 20),
                  _buildOriginalPost(),
                  const SizedBox(height: 32),
                  _buildRepliesHeader(),
                  const SizedBox(height: 16),
                  _buildDoctorReply(),
                  const SizedBox(height: 16),
                  _buildNormalReply('Amaka P.', '55m ago', 'I started walking every morning and reduced salt. My BP went down to 130/85 in a few weeks. Stay consistent!', 8, 3, 'A'),
                  const SizedBox(height: 16),
                  _buildNormalReply('Chinedu O.', '40m ago', 'Hibiscus tea helped me a lot. I drink it daily and my BP has been stable.', 6, 2, 'C'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            _buildBottomInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        Text('Forum', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        Text('General Health', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        const Text('Post Details', style: TextStyle(color: Color(0xFF0F2042), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOriginalPost() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF0F62FE),
                child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sarah J.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                    Text('Community Member', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '2h ago • Posted in '),
                          TextSpan(text: 'General Health', style: TextStyle(color: Colors.teal[600], fontWeight: FontWeight.w600)),
                        ],
                      ),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Now following Sarah J.'), backgroundColor: Color(0xFF10B981)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: Color(0xFF0F62FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Follow', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'How can I naturally lower my blood pressure?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F2042), height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            'I was recently told my blood pressure is a bit high (around 145/95). I don\'t want to go on medication if I can avoid it. What lifestyle changes or natural remedies have worked for you?',
            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag('Blood Pressure'),
              _buildTag('Lifestyle'),
              _buildTag('Natural Remedies'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('256 Views', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('28 Replies', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 6),
                  Text('34 Likes', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.ios_share, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Share', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: Colors.teal[700], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRepliesHeader() {
    return Row(
      children: [
        const Text('Top Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F2042))),
        const Spacer(),
        _buildFilterChip('All Replies', 0),
        const SizedBox(width: 8),
        _buildFilterChip('Doctor Answers', 1),
        const SizedBox(width: 8),
        _buildFilterChip('Most Liked', 2),
      ],
    );
  }

  Widget _buildFilterChip(String text, int index) {
    final isSelected = index == _selectedFilterIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorReply() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // very light blue/slate
        borderRadius: BorderRadius.circular(20),
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
                    radius: 20,
                    backgroundColor: Color(0xFF0F62FE),
                    child: Text('I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
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
                        const Text('Dr. Ibrahim Musa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: Color(0xFF0F62FE)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            border: Border.all(color: Colors.teal[200]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 10, color: Colors.teal[700]),
                              const SizedBox(width: 2),
                              Text('Verified Doctor', style: TextStyle(fontSize: 9, color: Colors.teal[700], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Internal Medicine Specialist', style: TextStyle(color: Colors.cyan[600], fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('1h ago • Doctor Answer', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF0F62FE)),
                    SizedBox(width: 4),
                    Text('Verified Medical Response', style: TextStyle(fontSize: 10, color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Great question, Sarah! High blood pressure can often be managed with lifestyle changes. Here are some effective, natural ways:',
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildCheckListItem('Reduce salt intake', 'Aim for less than 5g per day.'),
          _buildCheckListItem('Exercise regularly', '30 minutes of walking daily can make a big difference.'),
          _buildCheckListItem('Eat potassium-rich foods', 'Bananas, spinach, and avocados help.'),
          _buildCheckListItem('Manage stress', 'Meditation, deep breathing, and good sleep are key.'),
          _buildCheckListItem('Stay hydrated and avoid excessive alcohol.', null),
          const SizedBox(height: 12),
          Text(
            'Consistency is important. If your BP remains high, consult your doctor.',
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Helpful (24)', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Reply', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 6),
                  Text('12', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCheckListItem(String title, String? desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2042))),
                  if (desc != null) TextSpan(text: '– $desc', style: TextStyle(color: Colors.grey[800])),
                ],
              ),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalReply(String name, String timeAgo, String content, int helpful, int likes, String authorInitial) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                    Text('Community Member', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Helpful ($helpful)', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Reply', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 6),
                  Text('$likes', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF10B981),
                child: Text('Y', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.image_outlined, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 12),
                  Icon(Icons.gif_box_outlined, color: Colors.grey[500], size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F62FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
