import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/flavor_config.dart';
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
  Object? throwOnLoad;
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
    final failure = rec.throwOnLoad;
    if (failure != null) {
      return Future<PostgrestList>.error(failure)
          .then(onValue, onError: onError);
    }
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

  Widget wrap({ThemeData? theme}) => ProviderScope(
        child: MaterialApp(
          theme: theme,
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

  group('visual pass', () {
    final permissionRows = [
      {
        'id': 'perm-1',
        'record_id': 'rec-1',
        'doctor_id': 'doc-1',
        'granted_at': '2026-01-01T00:00:00Z',
        'profiles': {
          'full_name': 'Dr. Ada Cardia',
          'specialty': 'Cardiology'
        },
      },
    ];

    for (final flavor in [Flavor.user, Flavor.admin]) {
      testWidgets(
          '${flavor.name} flavor renders in light AND dark with distinct surfaces and no exceptions',
          (tester) async {
        FlavorConfig(
          flavor: flavor,
          appTitle: 'Premoncare',
          initialRoute: '/splash',
        );
        signedInAs('patient-1');
        rec.selectRows['record_permissions'] = permissionRows;

        await tester.pumpWidget(wrap(theme: ThemeData.light()));
        await tester.pumpAndSettle();
        expect(find.text('Dr. Ada Cardia'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final lightBg =
            (find.byType(Scaffold).evaluate().first.widget as Scaffold)
                .backgroundColor;

        await tester.pumpWidget(wrap(theme: ThemeData.dark()));
        await tester.pumpAndSettle();
        expect(find.text('Dr. Ada Cardia'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final darkBg =
            (find.byType(Scaffold).evaluate().first.widget as Scaffold)
                .backgroundColor;

        expect(lightBg, isNotNull);
        expect(darkBg, isNotNull);
        expect(lightBg == darkBg, isFalse,
            reason:
                'AppColors must resolve different surfaces for light vs dark');
      });
    }

    testWidgets('responsive matrix 320/360/768/1280 — no overflow, revoke target >= 40px',
        (tester) async {
      signedInAs('patient-1');
      rec.selectRows['record_permissions'] = permissionRows;

      void setViewport(Size size) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      for (final size in const [
        Size(320, 568),
        Size(360, 800),
        Size(768, 1024),
        Size(1280, 900),
      ]) {
        setViewport(size);
        await tester.pumpWidget(wrap(theme: ThemeData.light()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'no overflow at ${size.width}x${size.height}');
        expect(find.text('Dr. Ada Cardia'), findsOneWidget);

        final revoke = find.widgetWithText(TextButton, 'Revoke');
        expect(revoke, findsOneWidget);
        expect(tester.getSize(revoke).height, greaterThanOrEqualTo(40.0),
            reason: 'touch target at ${size.width}px');
      }
    });

    testWidgets('loading state shows spinner while the query is in flight',
        (tester) async {
      signedInAs('patient-1');
      rec.selectRows['record_permissions'] = permissionRows;

      await tester.pumpWidget(wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('query failure falls back to the empty state, not a stuck spinner',
        (tester) async {
      signedInAs('patient-1');
      rec.throwOnLoad = Exception('boom');

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No permissions granted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
