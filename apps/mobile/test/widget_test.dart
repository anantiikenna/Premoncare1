import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/flavor_config.dart';
import 'package:mobile/core/theme_provider.dart';
import 'package:mobile/main_common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    FlavorConfig(
      flavor: Flavor.user,
      appTitle: 'Premoncare',
      initialRoute: '/splash',
    );
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PremonCareApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
        child: const PremonCareApp(),
      ),
    );
    expect(find.byType(PremonCareApp), findsOneWidget);
  });
}
