import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'messaging_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(Icons.chat, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Chats',
              style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: conversationsAsync.when(
                data: (conversations) => Text(
                  '${conversations.where((c) => c.unreadCount > 0).length}',
                  style: TextStyle(color: AppColors.textInverse, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse)),
                error: (_, _) => Text('0', style: TextStyle(color: AppColors.textInverse, fontSize: 12)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.edit, color: AppColors.textPrimaryOf(context), size: 18),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('To start a conversation, go to a doctor\'s profile and tap Send Message')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLightOf(context)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiaryOf(context), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip(context, 'All', true),
                _buildFilterChip(context, 'Doctors', false, count: 7),
                _buildFilterChip(context, 'Support', false),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = conversations[index];
                    return _ChatTile(contact: contact);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, {int? count}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.borderLightOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textInverse : AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? AppColors.textInverse.withValues(alpha: 0.7) : AppColors.textTertiaryOf(context),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble, size: 64, color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat with a specialist to see it here.',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatContact contact;

  const _ChatTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat/${contact.userId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLightOf(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: contact.avatarUrl != null
                        ? DecorationImage(image: NetworkImage(contact.avatarUrl!), fit: BoxFit.cover)
                        : null,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: contact.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                if (contact.isOnline)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceOf(context), width: 2.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        contact.fullName,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context)),
                      ),
                      Text(
                        _formatTime(contact.lastMessage.createdAt),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiaryOf(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.specialty ?? 'Premon Care Support',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.lastMessage.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (contact.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            contact.unreadCount.toString(),
                            style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final m = date.minute.toString().padLeft(2, '0');
      final p = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
  }
}
