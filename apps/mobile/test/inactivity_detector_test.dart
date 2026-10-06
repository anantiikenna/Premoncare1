import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile/core/flavor_config.dart';
import 'package:mobile/core/supabase_locator.dart';
import 'package:mobile/core/widgets/inactivity_detector.dart';

class _FakeAuth implements GoTrueClient {
  Session? session;
  final StreamController<AuthState> events = StreamController<AuthState>();
  int signOutCalls = 0;

  @override
  Session? get currentSession => session;

  @override
  User? get currentUser => session?.user;

  @override
  Stream<AuthState> get onAuthStateChange => events.stream;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutCalls += 1;
    session = null;
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('unexpected: ${invocation.memberName}');
}

class _FakeSupabase implements SupabaseClient {
  _FakeSupabase(this.authClient);

  final GoTrueClient authClient;

  @override
  GoTrueClient get auth => authClient;

  @override
  Future<List<String>> removeAllChannels() async => <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('unexpected: ${invocation.memberName}');
}

Session _testSession() => Session(
      accessToken: 'access-token',
      tokenType: 'bearer',
      user: const User(
        id: 'user-1',
        appMetadata: <String, dynamic>{},
        userMetadata: <String, dynamic>{},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00.000Z',
      ),
    );

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  late _FakeAuth fakeAuth;
  late _FakeSupabase fakeSupabase;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() {
    FlavorConfig(
      flavor: Flavor.user,
      appTitle: 'Premoncare',
      initialRoute: '/splash',
    );
    SharedPreferences.setMockInitialValues({});
    fakeAuth = _FakeAuth()..session = _testSession();
    fakeSupabase = _FakeSupabase(fakeAuth);
    debugSupabaseOverride = fakeSupabase;
  });

  tearDown(() {
    debugSupabaseOverride = null;
    fakeAuth.events.close();
  });

  Future<void> pumpDetector(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InactivityDetector(
          child: const Text('child-content'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('does not arm timers or warn when there is no session',
      (tester) async {
    fakeAuth.session = null;
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 16));

    expect(find.text('Session Expiring Soon'), findsNothing);
    expect(fakeAuth.signOutCalls, 0);
    await _unmount(tester);
  });

  testWidgets('shows the warning at exactly 14 minutes of inactivity',
      (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 13) + const Duration(seconds: 59));
    expect(find.text('Session Expiring Soon'), findsNothing);
    expect(fakeAuth.signOutCalls, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Session Expiring Soon'), findsOneWidget);
    expect(find.text('Stay Logged In'), findsOneWidget);
    expect(fakeAuth.signOutCalls, 0);

    await _unmount(tester);
  });

  testWidgets('signs out after 15 minutes of inactivity', (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 15));
    await tester.pump();

    expect(fakeAuth.signOutCalls, greaterThanOrEqualTo(1));
    expect(find.text('Session Expiring Soon'), findsNothing);

    await _unmount(tester);
  });

  testWidgets('user interaction before the warning resets the window',
      (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 10));
    await tester.tap(find.text('child-content'));
    await tester.pump();

    await tester.pump(const Duration(minutes: 13) + const Duration(seconds: 59));
    expect(find.text('Session Expiring Soon'), findsNothing);
    expect(fakeAuth.signOutCalls, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Session Expiring Soon'), findsOneWidget);
    expect(fakeAuth.signOutCalls, 0);

    await _unmount(tester);
  });

  testWidgets('interaction is ignored once the warning is showing (countdown locks)',
      (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 14));
    expect(find.text('Session Expiring Soon'), findsOneWidget);

    await tester.tap(find.text('child-content'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Session Expiring Soon'), findsOneWidget);
    expect(fakeAuth.signOutCalls, 0);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(fakeAuth.signOutCalls, greaterThanOrEqualTo(1));

    await _unmount(tester);
  });

  testWidgets('"Stay Logged In" restarts the full 15-minute window',
      (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 14));
    expect(find.text('Session Expiring Soon'), findsOneWidget);

    await tester.tap(find.text('Stay Logged In'));
    await tester.pump();
    expect(find.text('Session Expiring Soon'), findsNothing);

    await tester.pump(const Duration(minutes: 14));
    await tester.pump();
    expect(find.text('Session Expiring Soon'), findsOneWidget);
    expect(fakeAuth.signOutCalls, 0);

    await _unmount(tester);
  });

  testWidgets('signed-out auth event cancels pending logout', (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 10));
    fakeAuth.events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await tester.pump();

    await tester.pump(const Duration(minutes: 16));
    expect(find.text('Session Expiring Soon'), findsNothing);
    expect(fakeAuth.signOutCalls, 0);

    await _unmount(tester);
  });

  testWidgets('dispose cancels timers (no logout after unmount)', (tester) async {
    await pumpDetector(tester);

    await tester.pump(const Duration(minutes: 10));
    await _unmount(tester);

    await tester.pump(const Duration(minutes: 16));
    expect(fakeAuth.signOutCalls, 0);
  });
}
