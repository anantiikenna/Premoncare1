import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_colors.dart';
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
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<ForumPost> _sortPosts(List<ForumPost> posts) {
    final sorted = List<ForumPost>.from(posts);
    switch (_selectedTabIndex) {
      case 1:
        sorted.sort((a, b) => b.replyCount.compareTo(a.replyCount));
        break;
      case 2:
        sorted.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildCategoriesStrip()),
            SliverToBoxAdapter(child: _buildTrendingSection()),
            SliverToBoxAdapter(child: _buildLatestDiscussionsTabs()),
            ref.watch(forumPostsProvider).when(
              data: (posts) {
                var filtered = _selectedCategoryId == null
                    ? posts
                    : posts.where((p) => p.categoryId == _selectedCategoryId).toList();

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered.where((p) =>
                    p.title.toLowerCase().contains(q) ||
                    p.content.toLowerCase().contains(q) ||
                    (p.categoryName ?? '').toLowerCase().contains(q)
                  ).toList();
                }

                final sorted = _sortPosts(filtered);

                if (sorted.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text\('No\ posts\ found\.'\)),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDiscussionCard(sorted[index]),
                    childCount: sorted.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))),
              error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forum/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Ask a Question', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Forum',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask questions, share experiences and learn from others',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      setState(() => _searchQuery = value.trim());
                    });
                  },
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search\ topics,\ questions\ or\ keywords\.\.\.',
                    hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search, color: AppColors.textTertiaryOf(context), size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceOf(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderOf(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showSortBottomSheet(),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    border: Border.all(color: AppColors.borderOf(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: AppColors.textSecondaryOf(context), size: 20),
                      const SizedBox(width: 8),
                      const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSortOption('Latest', 0),
            _buildSortOption('Most Answered', 1),
            _buildSortOption('Most Liked', 2),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () {
        setState(() => _selectedTabIndex = index);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildCategoriesStrip() {
    final categoriesAsync = ref.watch(forumCategoriesProvider);

    return SizedBox(
      height: 100,
      child: categoriesAsync.when(
        data: (categories) {
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
                          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.borderLightOf(context),
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
                          color: isSelected ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context),
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
    return ref.watch(forumPostsProvider).when(
      data: (posts) {
        final trending = List<ForumPost>.from(posts)
          ..sort((a, b) => b.upvotes.compareTo(a.upvotes));
        final top3 = trending.take(3).toList();

        if (top3.isEmpty) return const SizedBox.shrink();

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
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Trending Discussions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: top3.length,
                itemBuilder: (context, index) => _buildTrendingCard(top3[index]),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTrendingCard(ForumPost post) {
    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';
    final timeAgo = timeago.format(post.createdAt);

    return GestureDetector(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepOrange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 10, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Text(
                    post.upvotes > 10 ? 'Trending' : 'Popular',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange[700]),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              post.title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context), height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(authorInitial, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(timeAgo, style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context))),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textTertiaryOf(context)),
                    const SizedBox(width: 4),
                    Text('${post.replyCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLatestDiscussionsTabs() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 24, left: 20, right: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderOf(context))),
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
          border: isSelected ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textTertiaryOf(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionCard(ForumPost post) {
    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';
    final authorName = post.authorName;
    final timeAgo = timeago.format(post.createdAt);

    return InkWell(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLightOf(context))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                ),
                if (!post.isAnonymous)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceOf(context), width: 2),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryOf(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showPostOptions(post),
                        child: Icon(Icons.more_vert, size: 18, color: AppColors.textTertiaryOf(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
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
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context)),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: AppColors.textTertiaryOf(context)),
                          const SizedBox(width: 4),
                          Text('${post.viewCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
                          const SizedBox(width: 12),
                          Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textTertiaryOf(context)),
                          const SizedBox(width: 4),
                          Text('${post.replyCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
                          const SizedBox(width: 12),
                          Icon(Icons.favorite_border, size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text('${post.upvotes}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
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

  void _showPostOptions(ForumPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text\('Save\ Post'\),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ForumService.toggleSavePost(post.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text\('Post\ saved'\), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text\('Share\ Post'\),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text\('Post\ link\ copied\ to\ clipboard'\), backgroundColor: AppColors.success));
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.error),
                title: const Text('Report Post', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final reasonController = TextEditingController();
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text\('Report\ Post'\),
                      content: TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Why are you reporting this post?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text\(AppLocalizations.of(context)!.cancel\)),
                        TextButton(
                          onPressed: () => Navigator.pop(dctx, reasonController.text.trim()),
                          child: const Text('Submit', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  reasonController.dispose();
                  if (reason == null || reason.isEmpty) return;
                  try {
                    await ForumService.report(postId: post.id, reason: reason);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text\('Post\ reported'\), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
