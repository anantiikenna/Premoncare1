import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_colors.dart';
import 'forum_provider.dart';
import 'forum_utils.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final ForumPost? post;
  const PostDetailScreen({super.key, required this.postId, this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  int _selectedFilterIndex = 0;
  final _replyController = TextEditingController();
  bool _isSubmittingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingReply = true);
    try {
      await ForumService.addReply(postId: widget.postId, content: content);
      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text\('Reply\ posted'\), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reply: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final repliesAsync = ref.watch(forumRepliesProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        title: Text('Post Detail', style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: AppColors.textPrimaryOf(context)),
            onPressed: () async {
              try {
                await ForumService.toggleSavePost(widget.postId);
                if (!mounted) return;
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text\('Post\ saved'\), backgroundColor: AppColors.success));
              } catch (e) {
                if (!mounted) return;
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: AppColors.textPrimaryOf(context)),
            onPressed: () => _showPostOptions(),
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
                  _buildBreadcrumbs(post),
                  const SizedBox(height: 20),
                  _buildOriginalPost(post),
                  const SizedBox(height: 32),
                  _buildRepliesHeader(),
                  const SizedBox(height: 16),
                  repliesAsync.when(
                    data: (replies) {
                      var filtered = replies;
                      if (_selectedFilterIndex == 1) {
                        filtered = replies.where((r) => r.repliedAsDoctor).toList();
                      } else if (_selectedFilterIndex == 2) {
                        filtered = List.from(replies)..sort((a, b) => b.helpfulVotes.compareTo(a.helpfulVotes));
                      }

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: AppColors.textTertiaryOf(context), size: 48),
                                const SizedBox(height: 12),
                                Text('No replies yet', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Be the first to reply', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: filtered.map((reply) {
                          final isDoctor = reply.repliedAsDoctor;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: isDoctor ? _buildDoctorReplyWidget(reply) : _buildNormalReplyWidget(reply),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Error: $e'))),
                  ),
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

  Widget _buildBreadcrumbs(ForumPost? post) {
    return Row(
      children: [
        Text('Forum', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiaryOf(context)),
        Text(post?.categoryName ?? 'General', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiaryOf(context)),
        Text('Post Details', style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOriginalPost(ForumPost? post) {
    if (post == null) return const SizedBox.shrink();

    final authorInitial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U';
    final timeAgo = timeago.format(post.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(authorInitial, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                    Text(post.authorRole == 'doctor' ? 'Doctor' : 'Community Member', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: timeAgo),
                        if (post.categoryName != null) ...[
                          TextSpan(text: ' • Posted in '),
                          TextSpan(text: post.categoryName!, style: TextStyle(color: ForumUtils.getCategoryColor(post.categoryIcon), fontWeight: FontWeight.w600)),
                        ],
                      ]),
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await ForumService.toggleFollowPost(post.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text\('Follow\ toggled'\), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Follow', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            post.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimaryOf(context), height: 1.6),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatAction(Icons.visibility_outlined, '${post.viewCount} Views'),
              _buildStatAction(Icons.chat_bubble_outline, '${post.replyCount} Replies'),
              GestureDetector(
                onTap: () async {
                  try {
                    await ForumService.upvotePost(post.id);
                  } catch (_) {}
                },
                child: _buildStatAction(Icons.favorite_border, '${post.upvotes} Likes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatAction(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryOf(context)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRepliesHeader() {
    return Row(
      children: [
        Text('Top Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
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
          color: isSelected ? AppColors.primary : AppColors.borderLightOf(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.textInverse : AppColors.textSecondaryOf(context),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorReplyWidget(ForumReply reply) {
    final authorInitial = reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : 'D';
    final timeAgo = timeago.format(reply.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.infoLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(authorInitial, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceOf(context), width: 2),
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
                        Text(reply.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successLightOf(context),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 10, color: AppColors.success),
                              const SizedBox(width: 2),
                              Text('Verified Doctor', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(timeAgo, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(reply.content, style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context), height: 1.5)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await ForumService.voteReplyHelpful(reply.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text\('Marked\ as\ helpful'\), backgroundColor: AppColors.success));
                  } catch (_) {}
                },
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 6),
                    Text('Helpful (${reply.helpfulVotes})', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _replyController.text = '@${reply.authorName} ',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 6),
                    Text('Reply', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNormalReplyWidget(ForumReply reply) {
    final authorInitial = reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : 'U';
    final timeAgo = timeago.format(reply.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(authorInitial, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reply.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context))),
                    Text('Community Member', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(timeAgo, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(reply.content, style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context), height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await ForumService.voteReplyHelpful(reply.id);
                  } catch (_) {}
                },
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 6),
                    Text('Helpful (${reply.helpfulVotes})', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _replyController.text = '@${reply.authorName} ',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 6),
                    Text('Reply', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                  ],
                ),
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
        color: AppColors.surfaceOf(context),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.borderLightOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _replyController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write\ a\ reply\.\.\.',
                  hintStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSubmittingReply ? null : _submitReply,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSubmittingReply
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.send, color: AppColors.textInverse, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions() {
    final post = widget.post;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppColors.textTertiaryOf(context), borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: AppColors.primary),
              title: const Text\('Share\ Post'\),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text\('Post\ link\ copied\ to\ clipboard'\), backgroundColor: AppColors.success));
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text\('Report\ Post'\),
              onTap: () async {
                Navigator.pop(context);
                if (post != null) {
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
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text\('Post\ reported'\), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
