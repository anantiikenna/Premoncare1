import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile/core/supabase_locator.dart';
import 'package:mobile/features/verification/verification_provider.dart';

class FakeUser extends Fake implements User {
  @override
  String get id => 'uid-verify-1';
}

class FakeAuth extends Fake implements GoTrueClient {
  FakeAuth(this.currentUser);
  final User? currentUser;
}

class FakeBuilder {
  Map<String, dynamic>? lastUpdatePayload;
  String? lastEqColumn;
  dynamic lastEqValue;
  Map<String, dynamic>? singleRow;
  Object? throwOnUpdate;
}

class FakeMapTransform implements PostgrestTransformBuilder<PostgrestMap> {
  FakeMapTransform(this.r);
  final FakeBuilder r;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #then:
        final onValue = invocation.positionalArguments[0];
        return Future<dynamic>.delayed(Duration.zero,
            () => onValue(r.singleRow ?? <String, dynamic>{}));
      default:
        throw UnimplementedError('MapTransform.${invocation.memberName}');
    }
  }
}

class FakeListTransform implements PostgrestTransformBuilder<PostgrestList> {
  FakeListTransform(this.r);
  final FakeBuilder r;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #select:
      case #order:
      case #range:
        return this;
      case #eq:
        return FakeListFilter(r);
      case #single:
        return FakeMapTransform(r);
      case #then:
        final onValue = invocation.positionalArguments[0];
        return Future<dynamic>.delayed(
            Duration.zero, () => onValue(<Map<String, dynamic>>[]));
      default:
        throw UnimplementedError('ListTransform.${invocation.memberName}');
    }
  }
}

class FakeListFilter implements PostgrestFilterBuilder<PostgrestList> {
  FakeListFilter(this.r);
  final FakeBuilder r;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #update:
        if (r.throwOnUpdate != null) throw r.throwOnUpdate!;
        r.lastUpdatePayload = Map<String, dynamic>.from(
            invocation.positionalArguments.first as Map);
        return this;
      case #eq:
        r.lastEqColumn = invocation.positionalArguments[0] as String;
        r.lastEqValue = invocation.positionalArguments[1];
        return this;
      case #select:
      case #order:
      case #range:
        return this;
      case #single:
        return FakeMapTransform(r);
      case #then:
        final onValue = invocation.positionalArguments[0];
        return Future<dynamic>.delayed(
            Duration.zero, () => onValue(<Map<String, dynamic>>[]));
      default:
        throw UnimplementedError('ListFilter.${invocation.memberName}');
    }
  }
}

class FakeTable implements SupabaseQueryBuilder {
  FakeTable(this.r);
  final FakeBuilder r;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #update:
      case #insert:
      case #upsert:
        if (r.throwOnUpdate != null) throw r.throwOnUpdate!;
        r.lastUpdatePayload = Map<String, dynamic>.from(
            invocation.positionalArguments.first as Map);
        return FakeListFilter(r);
      case #select:
        return FakeListFilter(r);
      default:
        throw UnimplementedError('FakeTable.${invocation.memberName}');
    }
  }
}

class FakeBucket extends Fake implements StorageFileApi {
  FakeBucket(this.client);
  final FakeSupabaseClient client;

  @override
  Future<String> upload(
    String path,
    dynamic file, {
    FileOptions fileOptions = const FileOptions(),
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    client.lastUploadPath = path;
    client.lastUploadBucket = client.lastStorageFrom;
    client.lastUploadUpsert = fileOptions.upsert;
    return path;
  }
}

class FakeStorage extends Fake implements SupabaseStorageClient {
  FakeStorage(this.client);
  final FakeSupabaseClient client;

  @override
  StorageFileApi from(String bucketId) {
    client.lastStorageFrom = bucketId;
    return FakeBucket(client);
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({User? user}) : auth = FakeAuth(user);

  @override
  final GoTrueClient auth;

  final FakeBuilder builder = FakeBuilder();

  String? lastStorageFrom;
  String? lastUploadBucket;
  String? lastUploadPath;
  bool? lastUploadUpsert;
  String? lastFromTable;

  @override
  SupabaseQueryBuilder from(String table) {
    lastFromTable = table;
    return FakeTable(builder);
  }

  @override
  SupabaseStorageClient get storage => FakeStorage(this);
}

void main() {
  late FakeSupabaseClient fake;
  late ProviderContainer container;

  VerificationState state() => container.read(verificationProvider);
  VerificationNotifier notifier() =>
      container.read(verificationProvider.notifier);

  setUp(() {
    fake = FakeSupabaseClient();
    debugSupabaseOverride = fake;
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    debugSupabaseOverride = null;
  });

  group('wizard step machine', () {
    test('starts at the professional step', () {
      expect(state().currentStep, VerificationStep.professional);
    });

    test('nextStep walks professional → identity → facial → review and clamps', () {
      notifier().nextStep();
      expect(state().currentStep, VerificationStep.identity);
      notifier().nextStep();
      expect(state().currentStep, VerificationStep.facial);
      notifier().nextStep();
      expect(state().currentStep, VerificationStep.review);
      notifier().nextStep();
      expect(state().currentStep, VerificationStep.review);
    });

    test('previousStep clamps at professional', () {
      notifier().goToStep(VerificationStep.facial);
      notifier().previousStep();
      expect(state().currentStep, VerificationStep.identity);
      notifier().previousStep();
      expect(state().currentStep, VerificationStep.professional);
      notifier().previousStep();
      expect(state().currentStep, VerificationStep.professional);
    });
  });

  group('consultation modes', () {
    test('toggle adds then removes a mode', () {
      notifier().toggleConsultationMode('video');
      expect(state().consultationModes, ['video']);
      notifier().toggleConsultationMode('audio');
      expect(state().consultationModes, ['video', 'audio']);
      notifier().toggleConsultationMode('video');
      expect(state().consultationModes, ['audio']);
    });
  });

  group('submit payload (profiles update contract)', () {
    test('maps experience text to years, forces requested_role=pending gate, and never reads an id from state', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;

      notifier()
        ..updateProfessional('Cardiologist', 'Cardiology', '5 years', 'NL-12345')
        ..updateIdType('passport')
        ..toggleConsultationMode('video')
        ..setAgreed(true);

      final ok = await notifier().submit();

      expect(ok, isTrue);
      expect(fake.lastFromTable, 'profiles');
      expect(fake.builder.lastEqColumn, 'id');
      expect(fake.builder.lastEqValue, 'uid-verify-1');

      final payload = fake.builder.lastUpdatePayload!;
      expect(payload['specialty'], 'Cardiology');
      expect(payload['experience_years'], 5);
      expect(payload['medical_license_number'], 'NL-12345');
      expect(payload['identity_type'], 'passport');
      expect(payload['preferred_consultation_types'], ['video']);
      expect(payload['requested_role'], 'doctor');
      expect(payload['verification_status'], 'pending');
      expect(payload['live_selfie_url'], isNull);
      expect(payload['identity_document_url'], isNull);
    });

    test('unified identity URL falls back to the front image when idUrl is absent', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;

      await notifier().uploadFile(File('front.jpg'),
          VerificationField.govtIdFront, 'front.jpg');

      await notifier().submit();

      expect(fake.builder.lastUpdatePayload!['identity_document_url'],
          'uid-verify-1/front.jpg');
      expect(fake.builder.lastUpdatePayload!['identity_document_front_url'],
          'uid-verify-1/front.jpg');
    });

    test('experience without digits becomes 0 years', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;

      await notifier().submit();

      expect(fake.builder.lastUpdatePayload!['experience_years'], 0);
    });

    test('fails cleanly when signed out — no profiles write happens', () async {
      final ok = await notifier().submit();

      expect(ok, isFalse);
      expect(state().error, contains('Not authenticated'));
      expect(state().isSubmitting, isFalse);
      expect(fake.lastFromTable, isNull);
    });

    test('propagates database errors into state and returns false', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;
      fake.builder.throwOnUpdate = Exception('RLS: update denied');

      final ok = await notifier().submit();

      expect(ok, isFalse);
      expect(state().error, contains('RLS: update denied'));
      expect(state().isSubmitting, isFalse);
    });
  });

  group('upload routing', () {
    test('license uploads to doctor-verifications under the user folder', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;

      await notifier()
          .uploadFile(File('license.pdf'), VerificationField.license, 'license.pdf');

      expect(fake.lastUploadBucket, 'doctor-verifications');
      expect(fake.lastUploadPath, 'uid-verify-1/license.pdf');
      expect(fake.lastUploadUpsert, isTrue);
      expect(state().licenseUrl, 'uid-verify-1/license.pdf');
      expect(state().isUploading, isFalse);
      expect(state().error, isNull);
    });

    test('identity documents route to doctor-identities and land in their state fields', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;

      await notifier().uploadFile(
          File('id.jpg'), VerificationField.govtIdBack, 'id.jpg');
      await notifier().uploadFile(
          File('me.jpg'), VerificationField.selfie, 'me.jpg');
      await notifier().uploadFile(
          File('addr.jpg'), VerificationField.address, 'addr.jpg');

      expect(fake.lastUploadBucket, 'doctor-identities');
      expect(state().idBackUrl, 'uid-verify-1/id.jpg');
      expect(state().selfieUrl, 'uid-verify-1/me.jpg');
      expect(state().addressUrl, 'uid-verify-1/addr.jpg');
    });

    test('signs out mid-upload — surfaces error and clears the uploading flag', () async {
      await notifier()
          .uploadFile(File('x.jpg'), VerificationField.license, 'x.jpg');

      expect(state().isUploading, isFalse);
      expect(state().error, contains('Not authenticated'));
    });
  });

  group('initial status fetch', () {
    test('hydrates state from the profiles row with unsubmitted fallback', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;
      fake.builder.singleRow = {
        'verification_status': 'approved',
        'title': 'Neurologist',
        'specialty': 'Neurology',
        'experience_years': 12,
        'medical_license_number': 'NL-777',
        'rejection_reason': null,
      };

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(verificationProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final hydrated = container2.read(verificationProvider);
      expect(hydrated.verificationStatus, 'approved');
      expect(hydrated.title, 'Neurologist');
      expect(hydrated.specialty, 'Neurology');
      expect(hydrated.experience, '12');
      expect(hydrated.licenseNumber, 'NL-777');
    });

    test('missing verification_status defaults to unsubmitted', () async {
      fake = FakeSupabaseClient(user: FakeUser());
      debugSupabaseOverride = fake;
      fake.builder.singleRow = {'verification_status': null};

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(verificationProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container2.read(verificationProvider).verificationStatus,
          'unsubmitted');
    });
  });
}
