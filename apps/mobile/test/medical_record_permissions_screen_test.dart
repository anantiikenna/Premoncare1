import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/supabase_locator.dart';
import 'package:mobile/features/settings/medical_record_permissions_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final List<Map<String, dynamic>> eqCalls = [];
  final Map<String, List<Map<String, dynamic>>> selectRows = {};
  String? lastDeleteTable;
  List<dynamic>? lastDeleteEq;
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
      case #eq:
        rec.eqCalls.add({
          'table': table,
          'column': invocation.positionalArguments[0],
          'value': invocation.positionalArguments[1],
        });
        return this;
      case #select:
      case #order:
        return this;
      case #delete:
        rec.lastDeleteTable = table;
        return this;
      default:
        throw UnimplementedError('ListFilter.${invocation.memberName}');
    }
  }
}

class FakeTable implements SupabaseQueryBuilder {
  FakeTable(this.rec, this.table);
  final Recorder rec;
  final String table;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #select:
      case #delete:
        return FakeListFilter(rec, table);
      default:
        throw UnimplementedError('FakeTable.${invocation.memberName}');
    }
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({required this.auth, required this.rec});
  @override
  final GoTrueClient auth;
  final Recorder rec;

  @override
  SupabaseQueryBuilder from(String table) => FakeTable(rec, table);
}

void main() {
  late Recorder rec;
  late FakeSupabaseClient fake;

  Widget wrap() => ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MedicalRecordPermissionsScreen(),
        ),
      );

  void signedInAs(String userId) {
    rec = Recorder();
    fake = FakeSupabaseClient(auth: FakeAuth(FakeUser(userId)), rec: rec);
    debugSupabaseOverride = fake;
  }

  tearDown(() => debugSupabaseOverride = null);

  testWidgets('renders granted doctor from embedded profile without a patient_id filter',
      (tester) async {
    signedInAs('patient-1');
    rec.selectRows['record_permissions'] = [
      {
        'id': 'perm-1',
        'record_id': 'rec-1',
        'doctor_id': 'doc-1',
        'granted_at': '2026-01-01T00:00:00Z',
        'profiles': {'full_name': 'Dr. Ada Cardia', 'specialty': 'Cardiology'},
      },
    ];

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Dr. Ada Cardia'), findsOneWidget);
    expect(find.text('Cardiology'), findsOneWidget);
    expect(find.text('Revoke'), findsOneWidget);
    expect(
      rec.eqCalls.where((c) => c['column'] == 'patient_id'),
      isEmpty,
      reason:
          'record_permissions has no patient_id column — RLS scopes rows via the medical_records join',
    );
  });

  testWidgets('shows empty state when no permissions are granted', (tester) async {
    signedInAs('patient-1');
    rec.selectRows['record_permissions'] = [];

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('No permissions granted'), findsOneWidget);
    expect(find.text('Revoke'), findsNothing);
  });

  testWidgets('signed out never queries', (tester) async {
    rec = Recorder();
    fake = FakeSupabaseClient(auth: FakeAuth(null), rec: rec);
    debugSupabaseOverride = fake;

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(rec.selectRows.containsKey('record_permissions'), false);
    expect(rec.eqCalls, isEmpty);
    expect(find.text('No permissions granted'), findsOneWidget);
  });
}
