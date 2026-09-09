import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import 'messaging_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String partnerId;
  const ChatDetailScreen({super.key, required this.partnerId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _partnerProfile;

  @override
  void initState() {
    super.initState();
    _loadPartnerProfile();
    Future.microtask(() => MessagingService.markAsRead(widget.partnerId));
  }

  Future<void> _loadPartnerProfile() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, avatar_url, specialty, is_online')
          .eq('id', widget.partnerId)
          .single();
      if (mounted) setState(() => _partnerProfile = data);
    } catch (e) {
      debugPrint('Error loading partner profile: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await MessagingService.sendMessage(widget.partnerId, content);
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.partnerId));
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: _partnerProfile == null 
          ? const SizedBox.shrink()
          : Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: _partnerProfile!['avatar_url'] != null
                            ? DecorationImage(image: NetworkImage(_partnerProfile!['avatar_url']), fit: BoxFit.cover)
                            : null,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: _partnerProfile!['avatar_url'] == null ? const Icon(Icons.person, size: 20) : null,
                    ),
                    if (_partnerProfile!['is_online'] == true)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceOf(context), width: 2)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_partnerProfile!['full_name'], style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.w900)),
                    Text(
                      '${_partnerProfile!['specialty'] ?? 'Specialist'} • ${_partnerProfile!['is_online'] == true ? 'Online' : 'Offline'}',
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone, color: AppColors.primary, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone call feature - start a consultation to use this.')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: AppColors.primary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature - start a consultation to use this.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppColors.borderLightOf(context).withValues(alpha: 0.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Messages are encrypted in transit via TLS.',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();
                final reversedMessages = messages.reversed.toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    final isMe = msg.senderId == currentUserId;
                    
                    bool showUnreadDivider = false;
                    if (index > 0 && !msg.isRead && !isMe && reversedMessages[index - 1].isRead) {
                      showUnreadDivider = true;
                    }

                    return Column(
                      children: [
                        if (showUnreadDivider) _buildUnreadDivider(),
                        _MessageBubble(message: msg, isMe: isMe, primaryColor: AppColors.primary, partnerAvatar: _partnerProfile?['avatar_url']),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUnreadDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.primary.withValues(alpha: 0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('1 Unread Message', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          Expanded(child: Container(height: 1, color: AppColors.primary.withValues(alpha: 0.2))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text('Start your consultation', style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text('Feel free to ask questions or share symptoms with your specialist.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          SafeArea(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showAttachmentSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.add, color: AppColors.textSecondaryOf(context), size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.backgroundOf(context), borderRadius: BorderRadius.circular(16)),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type\ a\ message\.\.\.',
                        hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Icon(Icons.send, color: AppColors.textInverse, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () { Navigator.pop(context); context.push('/vault'); },
                  child: _buildAttachmentOption(Icons.description, 'Prescription', AppColors.success),
                ),
                GestureDetector(
                  onTap: () { Navigator.pop(context); context.push('/vault'); },
                  child: _buildAttachmentOption(Icons.assignment, 'Reports', AppColors.primary),
                ),
                GestureDetector(
                  onTap: () { Navigator.pop(context); context.push('/vault'); },
                  child: _buildAttachmentOption(Icons.image, 'Images', AppColors.primary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: _buildAttachmentOption(Icons.location_on, 'Location', AppColors.info),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(context))),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Color primaryColor;
  final String? partnerAvatar;

  const _MessageBubble({required this.message, required this.isMe, required this.primaryColor, this.partnerAvatar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: partnerAvatar != null ? DecorationImage(image: NetworkImage(partnerAvatar!), fit: BoxFit.cover) : null,
                color: AppColors.borderLightOf(context),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : AppColors.surfaceOf(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: isMe ? AppColors.textInverse : AppColors.textPrimaryOf(context), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(color: (isMe ? AppColors.textInverse : AppColors.textTertiaryOf(context)), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 12, color: message.isRead ? AppColors.info : AppColors.textInverse),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final m = date.minute.toString().padLeft(2, '0');
    final p = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }
}
