import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'forum_provider.dart';

class MyActivityScreen extends ConsumerStatefulWidget {
  const MyActivityScreen({super.key});

  @override
  ConsumerState<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends ConsumerState<MyActivityScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        title: Text('My Activity', style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: GlobalUserAvatar(radius: 16),
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['My Posts', 'Saved', 'Following'];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderOf(context)))),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: isSelected ? Border(bottom: BorderSide(color: AppColors.primary, width: 2)) : null,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Center(child: Text('Not authenticated'));

    switch (_selectedTabIndex) {
      case 0:
        return _buildMyPosts(userId);
      case 1:
        return _buildSavedPosts();
      case 2:
        return _buildFollowing();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMyPosts(String userId) {
    final postsAsync = ref.watch(forumPostsProvider);

    return postsAsync.when(
      data: (posts) {
        final myPosts = posts.where((p) => p.authorId == userId).toList();

        if (myPosts.isEmpty) {
          return _buildEmptyState('No posts yet', 'Your posts will appear here', Icons.article_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: myPosts.length,
          itemBuilder: (context, index) {
            final post = myPosts[index];
            return _buildPostCard(post);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSavedPosts() {
    final savedAsync = ref.watch(forumSavedPostsProvider);

    return savedAsync.when(
      data: (savedIds) {
        if (savedIds.isEmpty) {
          return _buildEmptyState('No saved posts', 'Posts you save will appear here', Icons.bookmark_border);
        }

        final postsAsync = ref.watch(forumPostsProvider);
        return postsAsync.when(
          data: (posts) {
            final savedPosts = posts.where((p) => savedIds.contains(p.id)).toList();
            if (savedPosts.isEmpty) {
              return _buildEmptyState('No saved posts', 'Posts you save will appear here', Icons.bookmark_border);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) => _buildPostCard(savedPosts[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFollowing() {
    final followedAsync = ref.watch(forumFollowedProvider);

    return followedAsync.when(
      data: (followed) {
        final followedPostIds = followed.where((f) => f['post_id'] != null).map((f) => f['post_id'] as String).toList();

        if (followedPostIds.isEmpty) {
          return _buildEmptyState('Not following anything', 'Posts you follow will appear here', Icons.people_outline);
        }

        final postsAsync = ref.watch(forumPostsProvider);
        return postsAsync.when(
          data: (posts) {
            final followedPosts = posts.where((p) => followedPostIds.contains(p.id)).toList();
            if (followedPosts.isEmpty) {
              return _buildEmptyState('Not following any posts', 'Posts you follow will appear here', Icons.people_outline);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: followedPosts.length,
              itemBuilder: (context, index) => _buildPostCard(followedPosts[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textTertiaryOf(context), size: 56),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final timeAgo = timeago.format(post.createdAt);
    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(authorInitial, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimaryOf(context))),
                      Text(timeAgo, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                    ],
                  ),
                ),
                if (post.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.successLightOf(context), borderRadius: BorderRadius.circular(6)),
                    child: Text(post.categoryName!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.teal)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 6),
            Text(post.content, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textTertiaryOf(context)),
                const SizedBox(width: 4),
                Text('${post.replyCount}', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                const SizedBox(width: 16),
                Icon(Icons.favorite_border, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('${post.upvotes}', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                const SizedBox(width: 16),
                Icon(Icons.visibility_outlined, size: 14, color: AppColors.textTertiaryOf(context)),
                const SizedBox(width: 4),
                Text('${post.viewCount}', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
