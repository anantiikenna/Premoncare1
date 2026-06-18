import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class ForumCategory {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final bool isActive;

  ForumCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.isActive,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> json) {
    return ForumCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['icon_name'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorRole;
  final String title;
  final String content;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final List<String> attachments;
  final bool isAnonymous;
  final bool isAskDoctorQueue;
  final String status;
  final int upvotes;
  final int viewCount;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole,
    required this.title,
    required this.content,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.attachments = const [],
    this.isAnonymous = false,
    this.isAskDoctorQueue = false,
    this.status = 'approved',
    this.upvotes = 0,
    this.viewCount = 0,
    this.replyCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    final category = json['forum_categories'] as Map<String, dynamic>?;
    return ForumPost(
      id: json['id'],
      authorId: json['author_id'],
      authorName: (json['is_anonymous'] == true)
          ? 'Anonymous'
          : (author?['full_name'] ?? 'Anonymous'),
      authorAvatar:
          (json['is_anonymous'] == true) ? null : author?['avatar_url'],
      authorRole: author?['role'],
      title: json['title'],
      content: json['content'],
      categoryId: json['category_id'],
      categoryName: category?['name'],
      categoryIcon: category?['icon_name'],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isAnonymous: json['is_anonymous'] ?? false,
      isAskDoctorQueue: json['is_ask_doctor_queue'] ?? false,
      status: json['status'] ?? 'approved',
      upvotes: json['upvotes'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
    );
  }
}

class ForumReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorRole;
  final String content;
  final List<String> attachments;
  final bool isAnonymous;
  final bool repliedAsDoctor;
  final int helpfulVotes;
  final bool isAcceptedAnswer;
  final String status;
  final DateTime createdAt;

  ForumReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole,
    required this.content,
    this.attachments = const [],
    this.isAnonymous = false,
    this.repliedAsDoctor = false,
    this.helpfulVotes = 0,
    this.isAcceptedAnswer = false,
    this.status = 'approved',
    required this.createdAt,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    return ForumReply(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      authorName: (json['is_anonymous'] == true)
          ? 'Anonymous'
          : (author?['full_name'] ?? 'Anonymous'),
      authorAvatar:
          (json['is_anonymous'] == true) ? null : author?['avatar_url'],
      authorRole: author?['role'],
      content: json['content'],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isAnonymous: json['is_anonymous'] ?? false,
      repliedAsDoctor: json['replied_as_doctor'] ?? false,
      helpfulVotes: json['helpful_votes'] ?? 0,
      isAcceptedAnswer: json['is_accepted_answer'] ?? false,
      status: json['status'] ?? 'approved',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// Stream all active forum categories
final forumCategoriesProvider = StreamProvider<List<ForumCategory>>((ref) {
  return supabase
      .from('forum_categories')
      .stream(primaryKey: ['id'])
      .order('name', ascending: true)
      .map((data) => data
          .where((item) => item['is_active'] == true)
          .map((item) => ForumCategory.fromJson(item))
          .toList());
});

/// Stream approved forum posts with author + category hydration
final forumPostsProvider = StreamProvider<List<ForumPost>>((ref) {
  return supabase
      .from('forum_posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
    final posts = <ForumPost>[];
    for (final item in data) {
      if (item['status'] != 'approved') continue;
      // Hydrate author profile
      Map<String, dynamic>? authorData;
      try {
        authorData = await supabase
            .from('profiles')
            .select('full_name, avatar_url, role')
            .eq('id', item['author_id'])
            .single();
      } catch (e) {
        debugPrint('Error fetching post author: $e');
      }
      // Hydrate category
      Map<String, dynamic>? categoryData;
      if (item['category_id'] != null) {
        try {
          categoryData = await supabase
              .from('forum_categories')
              .select('name')
              .eq('id', item['category_id'])
              .single();
        } catch (e) {
          debugPrint('Error fetching post category: $e');
        }
      }
      posts.add(ForumPost.fromJson({
        ...item,
        'profiles': authorData,
        'forum_categories': categoryData,
      }));
    }
    return posts;
  });
});

/// Stream replies for a specific post with author hydration
final forumRepliesProvider =
    StreamProvider.family<List<ForumReply>, String>((ref, postId) {
  return supabase
      .from('forum_replies')
      .stream(primaryKey: ['id'])
      .eq('post_id', postId)
      .order('created_at', ascending: true)
      .asyncMap((data) async {
    final replies = <ForumReply>[];
    for (final item in data) {
      Map<String, dynamic>? authorData;
      try {
        authorData = await supabase
            .from('profiles')
            .select('full_name, avatar_url, role')
            .eq('id', item['author_id'])
            .single();
      } catch (e) {
        debugPrint('Error fetching reply author: $e');
      }
      replies.add(ForumReply.fromJson({
        ...item,
        'profiles': authorData,
      }));
    }
    return replies;
  });
});

/// Stream user's saved posts
final forumSavedPostsProvider = StreamProvider<List<String>>((ref) {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  return supabase
      .from('forum_saves')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((item) => item['post_id'] as String).toList());
});

/// Stream user's followed post/category IDs
final forumFollowedProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  return supabase
      .from('forum_follows')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data
          .map((item) => {
                'post_id': item['post_id'],
                'category_id': item['category_id'],
              })
          .toList());
});

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

class ForumService {
  /// Create a new forum post
  static Future<void> createPost({
    required String title,
    required String content,
    String? categoryId,
    List<String>? attachments,
    bool isAnonymous = false,
    bool isAskDoctorQueue = false,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await supabase.from('forum_posts').insert({
        'author_id': user.id,
        'title': title,
        'content': content,
        'category_id': categoryId,
        'attachments': attachments ?? [],
        'is_anonymous': isAnonymous,
        'is_ask_doctor_queue': isAskDoctorQueue,
        'status': 'approved',
      });
    } catch (e) {
      debugPrint('Error creating forum post: $e');
      rethrow;
    }
  }

  /// Add a reply to a post
  static Future<void> addReply({
    required String postId,
    required String content,
    List<String>? attachments,
    bool isAnonymous = false,
    bool repliedAsDoctor = false,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await supabase.from('forum_replies').insert({
        'post_id': postId,
        'author_id': user.id,
        'content': content,
        'attachments': attachments ?? [],
        'is_anonymous': isAnonymous,
        'replied_as_doctor': repliedAsDoctor,
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
      rethrow;
    }
  }

  /// Save / unsave a post
  static Future<void> toggleSavePost(String postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final existing = await supabase
          .from('forum_saves')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase.from('forum_saves').delete().eq('id', existing['id']);
      } else {
        await supabase.from('forum_saves').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling save on post: $e');
      rethrow;
    }
  }

  /// Follow / unfollow a post
  static Future<void> toggleFollowPost(String postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final existing = await supabase
          .from('forum_follows')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase.from('forum_follows').delete().eq('id', existing['id']);
      } else {
        await supabase.from('forum_follows').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow on post: $e');
      rethrow;
    }
  }

  /// Follow / unfollow a category
  static Future<void> toggleFollowCategory(String categoryId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await supabase
        .from('forum_follows')
        .select('id')
        .eq('user_id', user.id)
        .eq('category_id', categoryId)
        .maybeSingle();

    if (existing != null) {
      await supabase.from('forum_follows').delete().eq('id', existing['id']);
    } else {
      await supabase.from('forum_follows').insert({
        'user_id': user.id,
        'category_id': categoryId,
      });
    }
  }

  /// Report a post or reply
  static Future<void> report({
    String? postId,
    String? replyId,
    required String reason,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await supabase.from('forum_reports').insert({
      'reporter_id': user.id,
      'post_id': postId,
      'reply_id': replyId,
      'reason': reason,
    });
  }

  /// Upvote a post (increment)
  static Future<void> upvotePost(String postId) async {
    try {
      await supabase.rpc('increment_forum_upvote', params: {'post_id': postId});
    } catch (e) {
      debugPrint('Error upvoting post: $e');
      rethrow;
    }
  }

  /// Vote a reply as helpful (increment)
  static Future<void> voteReplyHelpful(String replyId) async {
    await supabase
        .rpc('increment_reply_helpful', params: {'reply_id': replyId});
  }
}
