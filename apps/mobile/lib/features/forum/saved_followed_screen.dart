import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_colors.dart';
import 'forum_provider.dart';
import 'forum_utils.dart';

class SavedFollowedScreen extends ConsumerStatefulWidget {
  const SavedFollowedScreen({super.key});

  @override
  ConsumerState<SavedFollowedScreen> createState() => _SavedFollowedScreenState();
}

class _SavedFollowedScreenState extends ConsumerState<SavedFollowedScreen> {
  int _activeTab = 0;

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
        title: Text('Saved & Followed', style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _activeTab == 0 ? _buildSavedTab() : _buildFollowedTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderOf(context)))),
      child: Row(
        children: [
          _buildTab('Saved Posts', 0),
          _buildTab('Following', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = index == _activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isSelected ? Border(bottom: BorderSide(color: AppColors.primary, width: 2)) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTab() {
    final savedAsync = ref.watch(forumSavedPostsProvider);

    return savedAsync.when(
      data: (savedIds) {
        if (savedIds.isEmpty) {
          return _buildEmptyState('No saved posts', 'Tap the bookmark icon on any post to save it here', Icons.bookmark_border);
        }

        final postsAsync = ref.watch(forumPostsProvider);
        return postsAsync.when(
          data: (posts) {
            final savedPosts = posts.where((p) => savedIds.contains(p.id)).toList();
            if (savedPosts.isEmpty) {
              return _buildEmptyState('No saved posts', 'Tap the bookmark icon on any post to save it here', Icons.bookmark_border);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) => _buildSavedPostCard(savedPosts[index]),
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

  Widget _buildFollowedTab() {
    final followedAsync = ref.watch(forumFollowedProvider);

    return followedAsync.when(
      data: (followed) {
        final followedPosts = followed.where((f) => f['post_id'] != null).toList();
        final followedCategories = followed.where((f) => f['category_id'] != null).toList();

        if (followedPosts.isEmpty && followedCategories.isEmpty) {
          return _buildEmptyState('Not following anything', 'Tap Follow on any post or category to track it here', Icons.people_outline);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (followedCategories.isNotEmpty) ...[
              Text('Followed Categories', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...followedCategories.map((f) => _buildFollowedCategoryCard(f['category_id'] as String)),
              const SizedBox(height: 24),
            ],
            if (followedPosts.isNotEmpty) ...[
              Text('Followed Posts', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...followedPosts.map((f) => _buildFollowedPostCard(f['post_id'] as String)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSavedPostCard(ForumPost post) {
    final timeAgo = timeago.format(post.createdAt);

    return GestureDetector(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                if (post.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ForumUtils.getCategoryColor(post.categoryIcon).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(post.categoryName!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ForumUtils.getCategoryColor(post.categoryIcon))),
                  ),
                const Spacer(),
                Text(timeAgo, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    try {
                      await ForumService.toggleSavePost(post.id);
                    } catch (_) {}
                  },
                  child: Icon(Icons.bookmark, color: AppColors.primary, size: 18),
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
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Text(post.authorName, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textTertiaryOf(context)),
                const SizedBox(width: 4),
                Text('${post.replyCount}', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                const SizedBox(width: 12),
                Icon(Icons.favorite_border, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('${post.upvotes}', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowedCategoryCard(String categoryId) {
    final categoriesAsync = ref.watch(forumCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final match = categories.where((c) => c.id == categoryId);
        final cat = match.isNotEmpty ? match.first : null;
        if (cat == null) return const SizedBox.shrink();

        final iconData = ForumUtils.getCategoryIcon(cat.iconName);
        final color = ForumUtils.getCategoryColor(cat.iconName);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(iconData, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(cat.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
              GestureDetector(
                onTap: () async {
                  try {
                    await ForumService.toggleFollowCategory(categoryId);
                  } catch (_) {}
                },
                child: Text('Unfollow', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFollowedPostCard(String postId) {
    final postsAsync = ref.watch(forumPostsProvider);

    return postsAsync.when(
      data: (posts) {
        final match = posts.where((p) => p.id == postId);
        final post = match.isNotEmpty ? match.first : null;
        if (post == null) return const SizedBox.shrink();
        return _buildSavedPostCard(post);
      },
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
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
            Text(subtitle, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
