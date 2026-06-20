import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedFollowedScreen extends StatefulWidget {
  const SavedFollowedScreen({super.key});

  @override
  State<SavedFollowedScreen> createState() => _SavedFollowedScreenState();
}

class _SavedFollowedScreenState extends State<SavedFollowedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  // ── Sample data ──────────────────────────────────────────────────────────
  final List<_SavedPost> _savedPosts = [
    _SavedPost(
      id: '1',
      title: 'How can I naturally lower my blood pressure?',
      category: 'Heart Health',
      categoryColor: Colors.red,
      categoryIcon: Icons.favorite_border,
      authorName: 'Sarah J.',
      authorAvatar: '',
      replies: 14,
      likes: 87,
      savedAt: '2 hours ago',
      hasVerifiedAnswer: true,
      verifiedDoctor: 'Dr. Ibrahim Musa',
    ),
    _SavedPost(
      id: '2',
      title: 'Best foods to eat during the first trimester of pregnancy?',
      category: 'Pregnancy',
      categoryColor: Colors.pink,
      categoryIcon: Icons.pregnant_woman_outlined,
      authorName: 'Amaka O.',
      authorAvatar: '',
      replies: 22,
      likes: 134,
      savedAt: 'Yesterday',
      hasVerifiedAnswer: true,
      verifiedDoctor: 'Dr. Adaeze Nwosu',
    ),
    _SavedPost(
      id: '3',
      title: 'Is it safe to exercise with mild anemia?',
      category: 'General Health',
      categoryColor: Colors.teal,
      categoryIcon: Icons.health_and_safety_outlined,
      authorName: 'Emeka P.',
      authorAvatar: '',
      replies: 8,
      likes: 45,
      savedAt: '3 days ago',
      hasVerifiedAnswer: false,
      verifiedDoctor: null,
    ),
    _SavedPost(
      id: '4',
      title: 'Managing anxiety without medication — what works?',
      category: 'Mental Health',
      categoryColor: Colors.purple,
      categoryIcon: Icons.psychology_outlined,
      authorName: 'Chisom A.',
      authorAvatar: '',
      replies: 31,
      likes: 210,
      savedAt: '1 week ago',
      hasVerifiedAnswer: true,
      verifiedDoctor: 'Dr. Chinedu Okafor',
    ),
  ];

  final List<_FollowedThread> _followedThreads = [
    _FollowedThread(
      id: '1',
      title: 'Weekly Nutrition Tips from Our Dietitian',
      category: 'Nutrition',
      categoryColor: Colors.orange,
      categoryIcon: Icons.apple_outlined,
      followers: 1240,
      lastActivity: '10 mins ago',
      latestActivity: 'Dr. Adaeze Nwosu posted a new answer',
      isActive: true,
      totalPosts: 56,
    ),
    _FollowedThread(
      id: '2',
      title: 'High Blood Pressure Support Group',
      category: 'Heart Health',
      categoryColor: Colors.red,
      categoryIcon: Icons.favorite_border,
      followers: 3860,
      lastActivity: '1 hour ago',
      latestActivity: 'Sarah J. asked a new question',
      isActive: true,
      totalPosts: 142,
    ),
    _FollowedThread(
      id: '3',
      title: 'Pregnancy Q&A — All Trimesters',
      category: 'Pregnancy',
      categoryColor: Colors.pink,
      categoryIcon: Icons.pregnant_woman_outlined,
      followers: 5920,
      lastActivity: 'Yesterday',
      latestActivity: 'New verified answer added',
      isActive: false,
      totalPosts: 289,
    ),
    _FollowedThread(
      id: '4',
      title: 'Mental Wellness & Mindfulness Corner',
      category: 'Mental Health',
      categoryColor: Colors.purple,
      categoryIcon: Icons.psychology_outlined,
      followers: 2100,
      lastActivity: '2 days ago',
      latestActivity: 'Chisom A. shared a resource',
      isActive: false,
      totalPosts: 98,
    ),
    _FollowedThread(
      id: '5',
      title: 'Diabetes Management & Lifestyle Hacks',
      category: 'General Health',
      categoryColor: Colors.teal,
      categoryIcon: Icons.health_and_safety_outlined,
      followers: 4430,
      lastActivity: '3 days ago',
      latestActivity: 'Dr. Ibrahim Musa shared a new tip',
      isActive: false,
      totalPosts: 201,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() => _activeTab = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSavedTab(),
                _buildFollowedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          const Text('Premon',
              style: TextStyle(
                  color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
          Text('Care',
              style: TextStyle(
                  color: Colors.cyan[600], fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF0F2042)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use the search bar in the main forum to find posts'), backgroundColor: Color(0xFF6366F1)),
            );
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Color(0xFF0F2042)),
              onPressed: () => context.push('/notifications'),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Text('8',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ],
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saved & Followed',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2042))),
          const SizedBox(height: 4),
          Text('Your bookmarks and discussion threads you follow.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          // Custom tab switcher
          Row(
            children: [
              _tabPill(
                  label: 'Saved Posts',
                  icon: Icons.bookmark_outline,
                  count: _savedPosts.length,
                  index: 0),
              const SizedBox(width: 12),
              _tabPill(
                  label: 'Followed',
                  icon: Icons.notifications_active_outlined,
                  count: _followedThreads.length,
                  index: 1),
            ],
          ),
          const SizedBox(height: 0),
          // Underline indicator
          Container(
            height: 2,
            color: Colors.grey[100],
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _activeTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                    height: 2,
                    color: const Color(0xFF0F62FE),
                    margin: const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(
      {required String label,
      required IconData icon,
      required int count,
      required int index}) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _activeTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? const Color(0xFF0F62FE)
                      : Colors.grey[400]),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                      color: active
                          ? const Color(0xFF0F62FE)
                          : Colors.grey[500])),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0F62FE)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Saved Tab ─────────────────────────────────────────────────────────────
  Widget _buildSavedTab() {
    if (_savedPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'No Saved Posts Yet',
        subtitle:
            'Tap the bookmark icon on any discussion to save it here for later.',
        ctaLabel: 'Browse Forum',
        onCta: () => context.go('/forum'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSavedSummaryBanner(),
        const SizedBox(height: 8),
        ...List.generate(_savedPosts.length, (i) {
          final post = _savedPosts[i];
          return _SavedPostCard(
            post: post,
            onTap: () => context.push('/forum/post/${post.id}'),
            onUnsave: () {
              setState(() => _savedPosts.removeAt(i));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Post removed from saved'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        setState(() => _savedPosts.insert(i, post));
                      }),
                ),
              );
            },
            onShare: () => _showShareSheet(context),
          );
        }),
      ],
    );
  }

  Widget _buildSavedSummaryBanner() {
    final verifiedCount =
        _savedPosts.where((p) => p.hasVerifiedAnswer).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F62FE), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F62FE).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.bookmark, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_savedPosts.length} Saved ${_savedPosts.length == 1 ? 'Post' : 'Posts'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                    '$verifiedCount with verified doctor answers',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3))),
            child: const Text('Sort',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          )
        ],
      ),
    );
  }

  // ── Followed Tab ──────────────────────────────────────────────────────────
  Widget _buildFollowedTab() {
    if (_followedThreads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Not Following Any Threads',
        subtitle:
            'Follow discussions to get notified when new answers are posted.',
        ctaLabel: 'Browse Forum',
        onCta: () => context.go('/forum'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildFollowedSummaryBanner(),
        const SizedBox(height: 8),
        ...List.generate(_followedThreads.length, (i) {
          final thread = _followedThreads[i];
          return _FollowedThreadCard(
            thread: thread,
            onTap: () => context.push('/forum/post/${thread.id}'),
            onUnfollow: () {
              setState(() => _followedThreads.removeAt(i));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Unfollowed thread'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        setState(
                            () => _followedThreads.insert(i, thread));
                      }),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildFollowedSummaryBanner() {
    final activeCount =
        _followedThreads.where((t) => t.isActive).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF0F62FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_followedThreads.length} Followed Threads',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('$activeCount active in the last 24 hours',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3))),
            child: const Text('Manage',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          )
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required VoidCallback onCta,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F62FE).withValues(alpha: 0.07),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: const Color(0xFF0F62FE)),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2042))),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(ctaLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ShareBottomSheet(),
    );
  }
}

// ── Saved Post Card ──────────────────────────────────────────────────────────
class _SavedPostCard extends StatelessWidget {
  final _SavedPost post;
  final VoidCallback onTap;
  final VoidCallback onUnsave;
  final VoidCallback onShare;

  const _SavedPostCard({
    required this.post,
    required this.onTap,
    required this.onUnsave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F62FE)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF0F2042))),
                      Text(post.savedAt,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: post.categoryColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: post.categoryColor.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(post.categoryIcon,
                          color: post.categoryColor, size: 10),
                      const SizedBox(width: 4),
                      Text(post.category,
                          style: TextStyle(
                              fontSize: 9,
                              color: post.categoryColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bookmark button
                GestureDetector(
                  onTap: onUnsave,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F62FE).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark,
                        color: Color(0xFF0F62FE), size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              post.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2042),
                  height: 1.4),
            ),
            // Verified answer badge
            if (post.hasVerifiedAnswer) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  border: Border.all(color: Colors.teal[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.teal[700], size: 12),
                    const SizedBox(width: 6),
                    Text(
                        'Answered by ${post.verifiedDoctor}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Footer row
            Row(
              children: [
                _statChip(Icons.chat_bubble_outline, '${post.replies} Replies',
                    Colors.grey[600]!),
                const SizedBox(width: 16),
                _statChip(
                    Icons.thumb_up_alt_outlined, '${post.likes} Likes', Colors.grey[600]!),
                const Spacer(),
                GestureDetector(
                  onTap: onShare,
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('Share',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Followed Thread Card ──────────────────────────────────────────────────────
class _FollowedThreadCard extends StatelessWidget {
  final _FollowedThread thread;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

  const _FollowedThreadCard({
    required this.thread,
    required this.onTap,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: thread.isActive
                  ? thread.categoryColor.withValues(alpha: 0.25)
                  : Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon bubble
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: thread.categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: thread.categoryColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(thread.categoryIcon,
                      color: thread.categoryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thread.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F2042),
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(thread.category,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: thread.categoryColor,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              ' · ${thread.totalPosts} posts · ${_formatFollowers(thread.followers)} followers',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                // Active indicator / unfollow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (thread.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          border: Border.all(color: Colors.teal[200]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('Active',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.teal[700],
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onUnfollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Unfollow',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            // Latest activity row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.update,
                      size: 14,
                      color: thread.isActive
                          ? Colors.teal
                          : Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(thread.latestActivity,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3)),
                  ),
                  const SizedBox(width: 8),
                  Text(thread.lastActivity,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

// ── Share Bottom Sheet ────────────────────────────────────────────────────────
class _ShareBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Share Post',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2042))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shareOption(Icons.copy, 'Copy Link', Colors.grey),
              _shareOption(Icons.message_outlined, 'Message', Colors.blue),
              _shareOption(Icons.chat_outlined, 'WhatsApp', Colors.green),
              _shareOption(Icons.more_horiz, 'More', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _SavedPost {
  final String id;
  final String title;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String authorName;
  final String authorAvatar;
  final int replies;
  final int likes;
  final String savedAt;
  final bool hasVerifiedAnswer;
  final String? verifiedDoctor;

  const _SavedPost({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    required this.authorName,
    required this.authorAvatar,
    required this.replies,
    required this.likes,
    required this.savedAt,
    required this.hasVerifiedAnswer,
    this.verifiedDoctor,
  });
}

class _FollowedThread {
  final String id;
  final String title;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final int followers;
  final String lastActivity;
  final String latestActivity;
  final bool isActive;
  final int totalPosts;

  const _FollowedThread({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    required this.followers,
    required this.lastActivity,
    required this.latestActivity,
    required this.isActive,
    required this.totalPosts,
  });
}
