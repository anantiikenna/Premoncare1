import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
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
          const SnackBar(content: Text('Reply posted'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reply: $e'), backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2042)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post Detail', style: TextStyle(color: Color(0xFF0F2042), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Color(0xFF0F2042)),
            onPressed: () async {
              try {
                await ForumService.toggleSavePost(widget.postId);
                if (!mounted) return;
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post saved'), backgroundColor: Color(0xFF10B981)));
              } catch (e) {
                if (!mounted) return;
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0F2042)),
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
                                Icon(Icons.chat_bubble_outline, color: Colors.grey[300], size: 48),
                                const SizedBox(height: 12),
                                Text('No replies yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Be the first to reply', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
        Text('Forum', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        Text(post?.categoryName ?? 'General', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        const Text('Post Details', style: TextStyle(color: Color(0xFF0F2042), fontSize: 13, fontWeight: FontWeight.bold)),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F62FE))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                    Text(post.authorRole == 'doctor' ? 'Doctor' : 'Community Member', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: timeAgo),
                        if (post.categoryName != null) ...[
                          const TextSpan(text: ' • Posted in '),
                          TextSpan(text: post.categoryName!, style: TextStyle(color: ForumUtils.getCategoryColor(post.categoryIcon), fontWeight: FontWeight.w600)),
                        ],
                      ]),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await ForumService.toggleFollowPost(post.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow toggled'), backgroundColor: Color(0xFF10B981)));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: Color(0xFF0F62FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Follow', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            post.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F2042), height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
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
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
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

  Widget _buildDoctorReplyWidget(ForumReply reply) {
    final authorInitial = reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : 'D';
    final timeAgo = timeago.format(reply.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                    child: Text(authorInitial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F62FE))),
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
                        Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
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
                    Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(reply.content, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await ForumService.voteReplyHelpful(reply.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as helpful'), backgroundColor: Color(0xFF10B981)));
                  } catch (_) {}
                },
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('Helpful (${reply.helpfulVotes})', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _replyController.text = '@${reply.authorName} ',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('Reply', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
                    Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                    Text('Community Member', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(reply.content, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
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
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('Helpful (${reply.helpfulVotes})', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _replyController.text = '@${reply.authorName} ',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('Reply', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _replyController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
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
              decoration: const BoxDecoration(
                color: Color(0xFF0F62FE),
                shape: BoxShape.circle,
              ),
              child: _isSubmittingReply
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post link copied to clipboard'), backgroundColor: Color(0xFF10B981)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('Report Post'),
              onTap: () async {
                Navigator.pop(context);
                if (post != null) {
                  try {
                    await ForumService.report(postId: post.id, reason: 'Reported by user');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post reported'), backgroundColor: Color(0xFF10B981)));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
