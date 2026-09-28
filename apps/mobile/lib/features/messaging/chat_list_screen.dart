import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'messaging_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              AppLocalizations.of(context)!.chatsTitle,
              style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
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
                SnackBar(content: Text(AppLocalizations.of(context)!.toStartConversationDesc)),
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
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchChats,
                  hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiaryOf(context), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _buildEmptyState(context);
                }
                final filtered = _searchQuery.isEmpty
                    ? conversations
                    : conversations.where((c) =>
                        c.fullName.toLowerCase().contains(_searchQuery) ||
                        (c.specialty?.toLowerCase().contains(_searchQuery) ?? false) ||
                        c.lastMessage.content.toLowerCase().contains(_searchQuery)
                      ).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noMatchesForSearch(_searchQuery), style: TextStyle(color: AppColors.textSecondaryOf(context))),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return _ChatTile(contact: contact);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('${AppLocalizations.of(context)!.errorLabelShort}: $err')),
            ),
          ),
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
            AppLocalizations.of(context)!.noConversationsYetTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.startChatSpecialistDesc,
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
                    children: [
                      Expanded(
                        child: Text(
                          contact.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(context, contact.lastMessage.createdAt),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiaryOf(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.specialty ?? AppLocalizations.of(context)!.premonCareSupport,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
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

  String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final m = date.minute.toString().padLeft(2, '0');
      final p = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    } else if (diff.inDays == 1) {
      return AppLocalizations.of(context)!.yesterdayLabel;
    } else {
      final l10n = AppLocalizations.of(context)!;
      final List<String> days = [l10n.dayMon, l10n.dayTue, l10n.dayWed, l10n.dayThu, l10n.dayFri, l10n.daySat, l10n.daySun];
      return days[date.weekday - 1];
    }
  }
}
