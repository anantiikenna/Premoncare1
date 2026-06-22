import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_colors.dart';
import 'forum_provider.dart';
import 'forum_utils.dart';

class AskDoctorScreen extends ConsumerStatefulWidget {
  const AskDoctorScreen({super.key});

  @override
  ConsumerState<AskDoctorScreen> createState() => _AskDoctorScreenState();
}

class _AskDoctorScreenState extends ConsumerState<AskDoctorScreen> {
  String? _selectedCategory;
  String _searchQuery = '';

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
        title: Text('Ask a Doctor', style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
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
            _buildAskDoctorPosts(),
            const SizedBox(height: 32),
            _buildBottomCTASection(context),
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
          Text('Ask a Doctor', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 4),
          Text('Get answers from verified healthcare professionals.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13)),
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
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search health questions...',
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
        ],
      ),
    );
  }

  Widget _buildCategoriesStrip() {
    final categories = [
      {'name': 'All', 'icon': null, 'color': AppColors.primary, 'bg': AppColors.primary, 'text': Colors.white},
      {'name': 'Heart Health', 'icon': Icons.favorite_border, 'color': AppColors.error, 'bg': AppColors.surfaceOf(context), 'text': AppColors.textPrimaryOf(context)},
      {'name': 'Mental Health', 'icon': Icons.psychology_outlined, 'color': AppColors.pink, 'bg': AppColors.surfaceOf(context), 'text': AppColors.textPrimaryOf(context)},
      {'name': 'Nutrition', 'icon': Icons.apple_outlined, 'color': AppColors.warning, 'bg': AppColors.surfaceOf(context), 'text': AppColors.textPrimaryOf(context)},
      {'name': 'Pregnancy', 'icon': Icons.pregnant_woman_outlined, 'color': AppColors.pink, 'bg': AppColors.surfaceOf(context), 'text': AppColors.textPrimaryOf(context)},
      {'name': 'General Health', 'icon': Icons.health_and_safety_outlined, 'color': AppColors.teal, 'bg': AppColors.surfaceOf(context), 'text': AppColors.textPrimaryOf(context)},
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
          final name = cat['name'] as String;
          final isSelected = _selectedCategory == null
              ? name == 'All'
              : _selectedCategory == name;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = name == 'All' ? null : name;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? (cat['bg'] as Color) : AppColors.surfaceOf(context),
                border: Border.all(
                  color: isSelected
                      ? (cat['bg'] as Color)
                      : (hasIcon ? (cat['color'] as MaterialColor)[100]! : AppColors.borderOf(context)),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasIcon) ...[
                    Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : cat['color'] as Color, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : cat['text'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
          colors: [AppColors.primary, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 32),
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
              foregroundColor: AppColors.primary,
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

  Widget _buildAskDoctorPosts() {
    final postsAsync = ref.watch(forumPostsProvider);

    return postsAsync.when(
      data: (posts) {
        var askDoctorPosts = posts.where((p) => p.isAskDoctorQueue).toList();

        if (_selectedCategory != null) {
          askDoctorPosts = askDoctorPosts.where((p) => p.categoryName == _selectedCategory).toList();
        }

        if (_searchQuery.isNotEmpty) {
          askDoctorPosts = askDoctorPosts.where((p) =>
            p.title.toLowerCase().contains(_searchQuery) ||
            p.content.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        if (askDoctorPosts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined, color: AppColors.textTertiaryOf(context), size: 48),
                  const SizedBox(height: 12),
                  Text('No questions for doctors yet', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/forum/create'),
                    child: const Text('Ask the First Question'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: askDoctorPosts.length,
          itemBuilder: (context, index) {
            final post = askDoctorPosts[index];
            return _buildPostCard(post);
          },
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';
    final timeAgo = timeago.format(post.createdAt);

    return GestureDetector(
      onTap: () => context.push('/forum/post/${post.id}', extra: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLightOf(context)),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                      Text(timeAgo, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                    ],
                  ),
                ),
                if (post.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ForumUtils.getCategoryColor(post.categoryIcon).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.categoryName!,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ForumUtils.getCategoryColor(post.categoryIcon)),
                    ),
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
                Text('${post.replyCount} replies', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                const SizedBox(width: 16),
                Icon(Icons.favorite_border, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('${post.upvotes} likes', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTASection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.infoLightOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user, color: AppColors.primary, size: 16),
            const SizedBox(height: 8),
            Text(
              'Forum responses are for educational purposes and do not replace professional consultations.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
