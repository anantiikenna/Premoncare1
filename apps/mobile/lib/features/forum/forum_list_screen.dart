import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'forum_provider.dart';
import 'forum_utils.dart';

class ForumListScreen extends ConsumerStatefulWidget {
  const ForumListScreen({super.key});

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> {
  String? _selectedCategoryId;
  int _selectedTabIndex = 0;

  // Hardcoded fallback if no categories loaded yet. We keep an "All Topics" conceptually,
  // but it's handled via `_selectedCategoryId = null`.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: _buildCategoriesStrip(),
          ),
          SliverToBoxAdapter(
            child: _buildTrendingSection(),
          ),
          SliverToBoxAdapter(
            child: _buildLatestDiscussionsTabs(),
          ),
          ref.watch(forumPostsProvider).when(
            data: (posts) {
              final filteredPosts = _selectedCategoryId == null 
                  ? posts 
                  : posts.where((p) => p.categoryId == _selectedCategoryId).toList();
              
              if (filteredPosts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No posts found for this category.')),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildDiscussionCard(filteredPosts[index]),
                  childCount: filteredPosts.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 100), // Space for bottom CTA
          ),
        ],
        ),
      ),
      bottomSheet: _buildJoinConversationCTA(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Forum',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F2042), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask questions, share experiences and learn from others',
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
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
                        'Search topics, questions or keywords...',
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
        ],
      ),
    );
  }

  Widget _buildCategoriesStrip() {
    final categoriesAsync = ref.watch(forumCategoriesProvider);

    return SizedBox(
      height: 100,
      child: categoriesAsync.when(
        data: (categories) {
          // Prepend an "All Topics" category locally.
          final allTopics = ForumCategory(
            id: 'all',
            name: 'All Topics',
            iconName: 'article',
            description: '',
            isActive: true,
          );
          final displayCategories = [allTopics, ...categories];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final cat = displayCategories[index];
              final isSelected = _selectedCategoryId == (cat.id == 'all' ? null : cat.id);
              final iconData = ForumUtils.getCategoryIcon(cat.iconName);
              final color = ForumUtils.getCategoryColor(cat.iconName);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedCategoryId = cat.id == 'all' ? null : cat.id;
                  });
                  if (cat.name == 'Ask Doctors') {
                    context.push('/forum/ask-doctor');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
                          border: Border.all(
                            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(iconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? const Color(0xFF0F2042) : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 3,
                          width: 24,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load categories: $err')),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Trending Discussions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2042)),
                  ),
                ],
              ),
              Text(
                'View all',
                style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildTrendingCard('Trending', 'How can I naturally boost my immune system?', 'Sarah J.', '2h ago', 32, Colors.teal, 'S'),
              _buildTrendingCard('Hot', 'Best foods to eat for a healthy heart', 'Michael T.', '4h ago', 28, Colors.orange, 'M'),
              _buildTrendingCard('Trending', 'Tips for better sleep and stress relief', 'Amaka P.', '5h ago', 21, Colors.teal, 'A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(String badgeText, String title, String author, String time, int comments, MaterialColor badgeColor, String authorInitial) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 10, color: badgeColor[600]),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor[700]),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042), height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                child: Text(authorInitial, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('$comments', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLatestDiscussionsTabs() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 24, left: 20, right: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              _buildTab('Latest Discussions', 0),
              _buildTab('Most Answered', 1),
              _buildTab('Most Liked', 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = index == _selectedTabIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, right: 24),
        decoration: BoxDecoration(
          border: isSelected ? const Border(bottom: BorderSide(color: Color(0xFF0F62FE), width: 2)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionCard(ForumPost post) {
    // For now, if author profile is not joined properly or has no avatar, use a placeholder
    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';
    final authorName = post.authorName;
    final timeAgo = timeago.format(post.createdAt);
    
    return InkWell(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                  child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F62FE))),
                ),
                if (!post.isAnonymous) 
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2042)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Render Category if available
                  if (post.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ForumUtils.getCategoryColor(post.categoryIcon).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.categoryName!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ForumUtils.getCategoryColor(post.categoryIcon),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '$authorName • $timeAgo',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('${post.viewCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('${post.replyCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.favorite_border, size: 14, color: Colors.red[300]),
                          const SizedBox(width: 4),
                          Text('${post.upvotes}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinConversationCTA() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), // 32 for safe area bottom if not wrapped in SafeArea
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.people_alt, color: Color(0xFF0F62FE), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join the conversation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                const SizedBox(height: 2),
                Text(
                  'Ask questions, share your experiences and help others in the community.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => context.push('/forum/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B4D8), // Cyan-blue matching image
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 6),
                Text('Ask a Question', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
