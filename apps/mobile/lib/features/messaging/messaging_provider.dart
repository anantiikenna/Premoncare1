import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/supabase_locator.dart';

enum MessageType { text, attachment, audio, location }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final MessageType type;
  final List<dynamic> attachments;
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.type = MessageType.text,
    this.attachments = const [],
    this.metadata = const {},
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      attachments: json['attachments'] ?? [],
      metadata: json['metadata'] ?? {},
    );
  }
}

class ChatContact {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? specialty;
  final Message lastMessage;
  final int unreadCount;
  final bool isOnline;

  ChatContact({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.specialty,
    required this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

/// Provider for real-time messages in a specific conversation
final chatMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, partnerId) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((data) => data
          .map((m) => Message.fromJson(m))
          .where((m) => 
            (m.senderId == user.id && m.receiverId == partnerId) || 
            (m.senderId == partnerId && m.receiverId == user.id))
          .toList());
});

/// Provider for the list of unique conversations (Inbox)
final conversationsProvider = StreamProvider.autoDispose<List<ChatContact>>((ref) async* {
  final user = supabase.auth.currentUser;
  if (user == null) {
      yield [];
      return;
  }

  final messageStream = supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  await for (final data in messageStream) {
    if (data.isEmpty) {
      yield [];
      continue;
    }

    final messages = data.map((m) => Message.fromJson(m)).toList();
    final Map<String, List<Message>> grouped = {};

    for (final m in messages) {
      final partnerId = m.senderId == user.id ? m.receiverId : m.senderId;
      grouped.putIfAbsent(partnerId, () => []).add(m);
    }

    final partnerIds = grouped.keys.toList();
    final profilesData = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, specialty, is_online')
        .inFilter('id', partnerIds);
    
    final Map<String, Map<String, dynamic>> profileMap = {
      for (var p in profilesData) p['id']: p
    };

    final contacts = partnerIds.map((pid) {
      final p = profileMap[pid] ?? {'full_name': 'Unknown User'};
      final chatMsgs = grouped[pid]!;
      return ChatContact(
        userId: pid,
        fullName: p['full_name'],
        avatarUrl: p['avatar_url'],
        specialty: p['specialty'],
        lastMessage: chatMsgs.first,
        unreadCount: chatMsgs.where((m) => m.receiverId == user.id && !m.isRead).length,
        isOnline: p['is_online'] ?? false,
      );
    }).toList();

    yield contacts;
  }
});

class MessagingService {
  static Future<void> sendMessage(
    String receiverId, 
    String content, {
    MessageType type = MessageType.text,
    List<dynamic> attachments = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': content,
        'type': type.name,
        'attachments': attachments,
        'metadata': metadata,
      });

      // Dispatch notification to recipient via web API (DB + FCM push)
      try {
        final senderProfile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        final senderName = senderProfile['full_name'] ?? 'Someone';

        final siteUrl = const String.fromEnvironment('NEXT_PUBLIC_SITE_URL', defaultValue: 'https://premoncare.com');
        final session = supabase.auth.currentSession;
        await http.post(
          Uri.parse('$siteUrl/api/notifications/dispatch'),
          headers: {
            'Content-Type': 'application/json',
            if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({
            'userId': receiverId,
            'title': 'New Message',
            'message': 'You have a new message from $senderName',
            'type': 'message',
          }),
        );
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) debugPrint('Error sending message: $e');
    }
  }

  static Future<void> markAsRead(String senderId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', user.id)
          .eq('sender_id', senderId)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking messages as read: $e');
    }
  }
}
