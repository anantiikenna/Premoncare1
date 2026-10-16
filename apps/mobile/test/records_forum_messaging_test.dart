import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile/core/supabase_locator.dart';
import 'package:mobile/features/forum/forum_provider.dart';
import 'package:mobile/features/messaging/messaging_provider.dart';
import 'package:mobile/features/records/records_provider.dart';

class FakeUser extends Fake implements User {
  FakeUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

class FakeAuth extends Fake implements GoTrueClient {
  FakeAuth(this.currentUser);
  @override
  final User? currentUser;
}

class Recorder {
  final Map<String, List<Map<String, dynamic>>> streamRows = {};
  final Map<String, List<Map<String, dynamic>>> selectRows = {};
  final List<Map<String, dynamic>> eqCalls = [];
  Map<String, dynamic>? maybeSingleRow;
  Map<String, dynamic>? singleRow;
  String? lastInsertTable;
  Map<String, dynamic>? lastInsertPayload;
  String? lastUpdateTable;
  Map<String, dynamic>? lastUpdatePayload;
  String? lastStorageFrom;
  String? lastUploadPath;
  List<String>? lastRemovePaths;
  String? lastRpcName;
  Map<String, dynamic>? lastRpcParams;
  Object? throwOnInsert;
}

class FakeMapTransform implements PostgrestTransformBuilder<PostgrestMap> {
  FakeMapTransform(this.rec);
  final Recorder rec;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestMap>.delayed(Duration.zero,
              () => rec.singleRow ?? <String, dynamic>{})
          .then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('MapTransform.${invocation.memberName}');
}

class FakeMaybeSingle
    implements PostgrestTransformBuilder<PostgrestMap?> {
  FakeMaybeSingle(this.rec);
  final Recorder rec;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestMap?>.delayed(Duration.zero, () => rec.maybeSingleRow)
          .then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('MaybeSingle.${invocation.memberName}');
}

class FakeListFilter implements PostgrestFilterBuilder<PostgrestList> {
  FakeListFilter(this.rec, this.table);
  final Recorder rec;
  final String table;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    final rows = rec.selectRows[table] ?? <Map<String, dynamic>>[];
    return Future<PostgrestList>.delayed(Duration.zero, () => rows)
        .then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #insert:
        if (rec.throwOnInsert != null) throw rec.throwOnInsert!;
        rec.lastInsertTable = table;
        rec.lastInsertPayload =
            Map<String, dynamic>.from(invocation.positionalArguments.first as Map);
        return this;
      case #update:
        rec.lastUpdateTable = table;
        rec.lastUpdatePayload =
            Map<String, dynamic>.from(invocation.positionalArguments.first as Map);
        return this;
      case #delete:
        return this;
      case #eq:
        rec.eqCalls.add({
          'table': table,
          'column': invocation.positionalArguments[0],
          'value': invocation.positionalArguments[1],
        });
        return this;
      case #inFilter:
        rec.eqCalls.add({
          'table': table,
          'column': invocation.positionalArguments[0],
          'value': invocation.positionalArguments[1],
        });
        return this;
      case #select:
      case #order:
      case #range:
        return this;
      case #single:
        return FakeMapTransform(rec);
      case #maybeSingle:
        return FakeMaybeSingle(rec);
      default:
        throw UnimplementedError('ListFilter.${invocation.memberName}');
    }
  }
}

class FakeStreamBuilder implements SupabaseStreamFilterBuilder {
  FakeStreamBuilder(this.rec, this.table);
  final Recorder rec;
  final String table;

  List<Map<String, dynamic>> get _rows =>
      rec.streamRows[table] ?? const <Map<String, dynamic>>[];

  @override
  SupabaseStreamFilterBuilder eq(String column, Object value) {
    rec.eqCalls.add({'table': table, 'column': column, 'value': value});
    return this;
  }

  @override
  SupabaseStreamFilterBuilder inFilter(String column, List<Object> values) {
    rec.eqCalls.add({'table': table, 'column': column, 'value': values});
    return this;
  }

  @override
  SupabaseStreamBuilder order(String column, {bool ascending = false}) =>
      this;

  @override
  SupabaseStreamBuilder limit(int count) => this;

  @override
  Stream<T> map<T>(
          T Function(SupabaseStreamEvent event) convert) =>
      Stream<SupabaseStreamEvent>.fromIterable([_rows]).map(convert);

  @override
  Stream<R> asyncMap<R>(
          FutureOr<R> Function(SupabaseStreamEvent event) convert) =>
      Stream<SupabaseStreamEvent>.fromIterable([_rows]).asyncMap(convert);

  @override
  StreamSubscription<SupabaseStreamEvent> listen(
    void Function(SupabaseStreamEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<SupabaseStreamEvent>.fromIterable([_rows]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('StreamBuilder.${invocation.memberName}');
}

class FakeTable implements SupabaseQueryBuilder {
  FakeTable(this.rec, this.table);
  final Recorder rec;
  final String table;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #insert:
        if (rec.throwOnInsert != null) throw rec.throwOnInsert!;
        rec.lastInsertTable = table;
        rec.lastInsertPayload = Map<String, dynamic>.from(
            invocation.positionalArguments.first as Map);
        return FakeListFilter(rec, table);
      case #update:
      case #upsert:
        rec.lastUpdateTable = table;
        rec.lastUpdatePayload = Map<String, dynamic>.from(
            invocation.positionalArguments.first as Map);
        return FakeListFilter(rec, table);
      case #delete:
      case #select:
        return FakeListFilter(rec, table);
      case #stream:
        return FakeStreamBuilder(rec, table);
      default:
        throw UnimplementedError('FakeTable.${invocation.memberName}');
    }
  }
}

class FakeBucket extends Fake implements StorageFileApi {
  FakeBucket(this.rec);
  final Recorder rec;

  @override
  Future<String> upload(
    String path,
    dynamic file, {
    FileOptions fileOptions = const FileOptions(),
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    rec.lastUploadPath = path;
    return path;
  }

  @override
  Future<List<FileObject>> remove(List<String> paths) async {
    rec.lastRemovePaths = paths;
    return const [];
  }
}

class FakeStorage extends Fake implements SupabaseStorageClient {
  FakeStorage(this.rec);
  final Recorder rec;

  @override
  StorageFileApi from(String bucketId) {
    rec.lastStorageFrom = bucketId;
    return FakeBucket(rec);
  }
}

class FakeChannel extends Fake implements RealtimeChannel {
  FakeChannel(this.rec);
  final Recorder rec;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload payload) callback,
  }) =>
      this;

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus status, Object? error)? callback,
    Duration? timeout,
  ]) =>
      this;

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({User? user})
      : auth = FakeAuth(user),
        rec = Recorder();

  @override
  final GoTrueClient auth;
  final Recorder rec;

  @override
  SupabaseQueryBuilder from(String table) => FakeTable(rec, table);

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) =>
      FakeChannel(rec);

  @override
  SupabaseStorageClient get storage => FakeStorage(rec);

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rec.lastRpcName = fn;
    rec.lastRpcParams = params;
    return FakeListFilter(rec, fn) as PostgrestFilterBuilder<T>;
  }
}

class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _NoNetworkHttpClient();
}

class _NoNetworkHttpClient extends Fake implements HttpClient {}

Map<String, dynamic> recordJson({
  String id = 'rec-1',
  String patientId = 'patient-1',
  String? recordType = 'labResult',
  List<String>? authorizedDoctors,
  String title = 'Blood panel',
}) =>
    {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'description': null,
      'record_type': recordType,
      'document_url': '$patientId/file.pdf',
      'authorized_doctors': authorizedDoctors,
      'created_at': '2026-01-01T10:00:00Z',
    };

Map<String, dynamic> postJson({
  String id = 'post-1',
  String authorId = 'author-1',
  bool isAnonymous = false,
  String status = 'approved',
  String? categoryId = 'cat-1',
  Map<String, dynamic>? profiles,
  Map<String, dynamic>? categories,
}) =>
    {
      'id': id,
      'author_id': authorId,
      'title': 'Headache for 3 days',
      'content': 'Persistent migraine, light sensitivity',
      'category_id': categoryId,
      'attachments': <dynamic>[],
      'is_anonymous': isAnonymous,
      'is_ask_doctor_queue': false,
      'status': status,
      'upvotes': 0,
      'view_count': 0,
      'reply_count': 0,
      'created_at': '2026-01-02T09:00:00Z',
      'updated_at': '2026-01-02T09:00:00Z',
      'profiles': ?profiles,
      'forum_categories': ?categories,
    };

Map<String, dynamic> messageJson({
  String id = 'msg-1',
  String senderId = 'me',
  String receiverId = 'partner',
  bool isRead = false,
  String type = 'text',
  List<dynamic> attachments = const [],
  Map<String, dynamic> metadata = const {},
}) =>
    {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': 'Hello doctor',
      'created_at': '2026-01-03T08:00:00Z',
      'is_read': isRead,
      'type': type,
      'attachments': attachments,
      'metadata': metadata,
    };

void main() {
  late FakeSupabaseClient fake;
  late ProviderContainer container;
  HttpOverrides? previousHttpOverrides;

  setUp(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _NoNetworkHttpOverrides();
    debugSupabaseOverride = fake = FakeSupabaseClient();
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    debugSupabaseOverride = null;
    HttpOverrides.global = previousHttpOverrides;
  });

  void signedInAs(String userId) {
    fake = FakeSupabaseClient(user: FakeUser(userId));
    debugSupabaseOverride = fake;
  }

  Future<T> readStreamValue<T>(StreamProvider<T> provider) {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    return container.read(provider.future);
  }

  group('MedicalRecord.fromJson', () {
    test('maps record_type by enum name and defaults unknown to other', () {
      final known = MedicalRecord.fromJson(recordJson(recordType: 'prescription'));
      expect(known.recordType, RecordType.prescription);

      final unknown = MedicalRecord.fromJson(recordJson(recordType: 'wat'));
      expect(unknown.recordType, RecordType.other);
    });

    test('missing authorized_doctors becomes empty list', () {
      final rec = MedicalRecord.fromJson(recordJson(authorizedDoctors: null));
      expect(rec.authorizedDoctors, isEmpty);
    });
  });

  group('patient records scoping', () {
    test('signed out yields an empty stream and never queries', () async {
      final events = await readStreamValue(patientRecordsProvider);
      expect(events, isEmpty);
      expect(fake.rec.eqCalls, isEmpty);
    });

    test('queries own patient_id and maps rows', () async {
      signedInAs('patient-x');
      fake.rec.streamRows['medical_records'] = [
        recordJson(patientId: 'patient-x'),
        recordJson(id: 'rec-2', patientId: 'patient-x', recordType: 'imaging'),
      ];

      final events = await readStreamValue(patientRecordsProvider);

      expect(
        fake.rec.eqCalls.any((c) =>
            c['table'] == 'medical_records' &&
            c['column'] == 'patient_id' &&
            c['value'] == 'patient-x'),
        isTrue,
        reason: 'patient stream must filter by own patient_id',
      );
      expect(events, hasLength(2));
      expect(events.first.recordType, RecordType.labResult);
      expect(events.last.recordType, RecordType.imaging);
    });
  });

  group('authorized (doctor) records scoping', () {
    test('keeps only records whose authorized_doctors contains my id', () async {
      signedInAs('doctor-me');
      fake.rec.streamRows['medical_records'] = [
        recordJson(id: 'mine', authorizedDoctors: ['doctor-me']),
        recordJson(id: 'other', authorizedDoctors: ['doctor-someone-else']),
        recordJson(id: 'open', authorizedDoctors: []),
      ];

      final events = await readStreamValue(authorizedRecordsProvider);

      expect(events.map((r) => r.id), ['mine']);
      expect(
        fake.rec.eqCalls.any((c) => c['column'] == 'patient_id'),
        isFalse,
        reason: 'doctor visibility is a client-side authorized_doctors filter, '
            'not a server-side eq()',
      );
    });
  });

  group('RecordsService', () {
    test('uploadRecord rejects signed-out and writes nothing', () async {
      await expectLater(
        RecordsService.uploadRecord(
            title: 'Panel', type: RecordType.labResult, file: File('x.pdf')),
        throwsA(isA<Exception>()),
      );
      expect(fake.rec.lastInsertTable, isNull);
      expect(fake.rec.lastUploadPath, isNull);
    });

    test('uploadRecord stores in patient-medical-vault with uid/millis path and inserts record_type as enum name', () async {
      signedInAs('patient-up');
      await RecordsService.uploadRecord(
          title: 'Panel', type: RecordType.labResult, file: File('x.pdf'));

      expect(fake.rec.lastStorageFrom, 'patient-medical-vault');
      expect(fake.rec.lastUploadPath, startsWith('patient-up/'));
      expect(fake.rec.lastUploadPath, endsWith('.pdf'));
      expect(fake.rec.lastInsertTable, 'medical_records');
      final payload = fake.rec.lastInsertPayload!;
      expect(payload['patient_id'], 'patient-up');
      expect(payload['record_type'], 'labResult');
      expect(payload['title'], 'Panel');
      expect(payload['document_url'], fake.rec.lastUploadPath);
    });

    test('toggleAuthorization(authorize) adds doctor and updates the row',
        () async {
      signedInAs('patient-up');
      fake.rec.singleRow = {
        'title': 'Panel',
        'record_type': 'labResult',
        'authorized_doctors': ['doc-a'],
      };

      await RecordsService.toggleAuthorization('rec-9', 'doc-b', true);

      final payload = fake.rec.lastUpdatePayload!;
      expect(payload['authorized_doctors'], ['doc-a', 'doc-b']);
      expect(
        fake.rec.eqCalls.any((c) =>
            c['table'] == 'medical_records' &&
            c['column'] == 'id' &&
            c['value'] == 'rec-9'),
        isTrue,
      );
    });

    test('toggleAuthorization(revoke) removes only that doctor', () async {
      signedInAs('patient-up');
      fake.rec.singleRow = {
        'title': 'Panel',
        'record_type': 'labResult',
        'authorized_doctors': ['doc-a', 'doc-b'],
      };

      await RecordsService.toggleAuthorization('rec-9', 'doc-a', false);

      expect(fake.rec.lastUpdatePayload!['authorized_doctors'], ['doc-b']);
    });

    test('deleteRecord removes storage object then the row', () async {
      signedInAs('patient-up');
      final record = MedicalRecord.fromJson(
          recordJson(patientId: 'patient-up', authorizedDoctors: []));

      await RecordsService.deleteRecord(record);

      expect(fake.rec.lastStorageFrom, 'patient-medical-vault');
      expect(fake.rec.lastRemovePaths, [record.documentUrl]);
      expect(
        fake.rec.eqCalls.any((c) =>
            c['table'] == 'medical_records' &&
            c['column'] == 'id' &&
            c['value'] == record.id),
        isTrue,
      );
    });
  });

  group('ForumPost.fromJson', () {
    test('anonymous forces Anonymous and strips the avatar', () {
      final post = ForumPost.fromJson(postJson(
        isAnonymous: true,
        profiles: {'full_name': 'Leaked Name', 'avatar_url': 'http://a', 'role': 'patient'},
      ));
      expect(post.authorName, 'Anonymous');
      expect(post.authorAvatar, isNull);
    });

    test('hydrates author and category from embedded maps', () {
      final post = ForumPost.fromJson(postJson(
        profiles: {'full_name': 'Dr Who', 'avatar_url': 'http://a', 'role': 'doctor'},
        categories: {'name': 'Neurology', 'icon_name': 'brain'},
      ));
      expect(post.authorName, 'Dr Who');
      expect(post.authorRole, 'doctor');
      expect(post.categoryName, 'Neurology');
      expect(post.status, 'approved');
    });
  });

  group('forum posts scoping', () {
    test('shows approved posts and own pending posts, hides others pending',
        () async {
      signedInAs('author-me');
      fake.rec.streamRows['forum_posts'] = [
        postJson(id: 'approved-1', status: 'approved'),
        postJson(id: 'pending-mine', authorId: 'author-me', status: 'pending'),
        postJson(id: 'pending-other', authorId: 'someone-else', status: 'pending'),
      ];
      fake.rec.selectRows['profiles'] = [
        {'id': 'author-me', 'full_name': 'Me', 'avatar_url': null, 'role': 'patient'},
        {'id': 'someone-else', 'full_name': 'Them', 'avatar_url': null, 'role': 'patient'},
      ];
      fake.rec.selectRows['forum_categories'] = [];

      final posts = await readStreamValue(forumPostsProvider);

      expect(posts.map((p) => p.id), ['approved-1', 'pending-mine']);
    });
  });

  group('ForumService write contracts', () {
    test('createPost inserts with status pending and JWT author_id', () async {
      signedInAs('author-me');
      await ForumService.createPost(title: 'T', content: 'C', isAnonymous: true);

      expect(fake.rec.lastInsertTable, 'forum_posts');
      final payload = fake.rec.lastInsertPayload!;
      expect(payload['author_id'], 'author-me');
      expect(payload['status'], 'pending');
      expect(payload['is_anonymous'], isTrue);
    });

    test('createPost rethrows insert failures', () async {
      signedInAs('author-me');
      fake.rec.throwOnInsert = Exception('RLS insert denied');

      await expectLater(
        ForumService.createPost(title: 'T', content: 'C'),
        throwsA(isA<Exception>()),
      );
    });

    test('toggleSavePost inserts when absent, deletes existing save', () async {
      signedInAs('author-me');

      fake.rec.maybeSingleRow = null;
      await ForumService.toggleSavePost('post-7');
      expect(fake.rec.lastInsertTable, 'forum_saves');
      expect(fake.rec.lastInsertPayload!['post_id'], 'post-7');
      expect(fake.rec.lastInsertPayload!['user_id'], 'author-me');

      fake.rec.maybeSingleRow = {'id': 'save-3'};
      fake.rec.lastInsertTable = null;
      await ForumService.toggleSavePost('post-7');
      expect(fake.rec.lastInsertTable, isNull);
      expect(
        fake.rec.eqCalls.any((c) =>
            c['table'] == 'forum_saves' &&
            c['column'] == 'id' &&
            c['value'] == 'save-3'),
        isTrue,
        reason: 'existing save must be deleted by its row id',
      );
    });

    test('upvotePost calls the increment_forum_upvote RPC with post_id', () async {
      signedInAs('author-me');
      await ForumService.upvotePost('post-7');
      expect(fake.rec.lastRpcName, 'increment_forum_upvote');
      expect(fake.rec.lastRpcParams, {'post_id': 'post-7'});
    });
  });

  group('Message.fromJson', () {
    test('parses enum type, defaults unknown to text, keeps JSONB payloads', () {
      final known = Message.fromJson(messageJson(
        type: 'audio',
        attachments: ['a.png'],
        metadata: {'lat': 51.5},
      ));
      expect(known.type, MessageType.audio);
      expect(known.attachments, ['a.png']);
      expect(known.metadata, {'lat': 51.5});

      final unknown = Message.fromJson(messageJson(type: 'carrier-pigeon'));
      expect(unknown.type, MessageType.text);
    });
  });

  group('chat conversation scoping', () {
    test('signed out yields an empty stream', () async {
      final events = await readStreamValue(chatMessagesProvider('partner'));
      expect(events, isEmpty);
    });

    test('keeps only messages between me and the partner', () async {
      signedInAs('me');
      fake.rec.streamRows['messages'] = [
        messageJson(id: 'a', senderId: 'me', receiverId: 'partner'),
        messageJson(id: 'b', senderId: 'partner', receiverId: 'me', isRead: true),
        messageJson(id: 'c', senderId: 'me', receiverId: 'stranger'),
        messageJson(id: 'd', senderId: 'stranger', receiverId: 'me'),
      ];

      final events = await readStreamValue(chatMessagesProvider('partner'));

      expect(events.map((m) => m.id), ['a', 'b']);
    });
  });

  group('MessagingService write contracts', () {
    test('sendMessage is a silent no-op when signed out', () async {
      await MessagingService.sendMessage('partner', 'hi');
      expect(fake.rec.lastInsertTable, isNull);
    });

    test('sendMessage inserts the full message contract from the JWT user',
        () async {
      signedInAs('me');
      await MessagingService.sendMessage(
        'partner',
        'hello',
        type: MessageType.attachment,
        attachments: ['file.png'],
        metadata: {'kind': 'lab'},
      );

      expect(fake.rec.lastInsertTable, 'messages');
      final payload = fake.rec.lastInsertPayload!;
      expect(payload['sender_id'], 'me');
      expect(payload['receiver_id'], 'partner');
      expect(payload['content'], 'hello');
      expect(payload['type'], 'attachment');
      expect(payload['attachments'], ['file.png']);
      expect(payload['metadata'], {'kind': 'lab'});
    });

    test('markAsRead only flips my unread rows from that sender', () async {
      signedInAs('me');
      await MessagingService.markAsRead('partner');

      expect(fake.rec.lastUpdateTable, 'messages');
      expect(fake.rec.lastUpdatePayload, {'is_read': true});
      final filters = fake.rec.eqCalls.where((c) => c['table'] == 'messages');
      expect(filters.any((c) =>
          c['column'] == 'receiver_id' && c['value'] == 'me'), isTrue);
      expect(filters.any((c) =>
          c['column'] == 'sender_id' && c['value'] == 'partner'), isTrue);
      expect(filters.any((c) =>
          c['column'] == 'is_read' && c['value'] == false), isTrue);
    });
  });

  group('conversationsProvider inbox', () {
    test('groups by partner, counts my unread, hydrates profile presence',
        () async {
      signedInAs('me');
      fake.rec.streamRows['messages'] = [
        messageJson(id: 'newest', senderId: 'partner', receiverId: 'me'),
        messageJson(id: 'older', senderId: 'me', receiverId: 'partner', isRead: true),
        messageJson(id: 'other', senderId: 'stranger', receiverId: 'me', isRead: false),
      ];
      fake.rec.selectRows['profiles'] = [
        {'id': 'partner', 'full_name': 'Dr Partner', 'avatar_url': null,
         'specialty': 'Cardiology', 'is_online': true},
        {'id': 'stranger', 'full_name': 'Stranger', 'avatar_url': null,
         'specialty': null, 'is_online': false},
      ];

      final contacts = await readStreamValue(conversationsProvider);

      expect(contacts, hasLength(2));
      final partner = contacts.firstWhere((c) => c.userId == 'partner');
      expect(partner.fullName, 'Dr Partner');
      expect(partner.isOnline, isTrue);
      expect(partner.unreadCount, 1);
      expect(partner.lastMessage.id, 'newest');

      final stranger = contacts.firstWhere((c) => c.userId == 'stranger');
      expect(stranger.unreadCount, 1);
    });
  });
}
