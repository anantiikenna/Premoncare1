import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/flavor_config.dart';
import 'package:mobile/main_common.dart';

void main() {
  setUp(() {
    FlavorConfig(
      flavor: Flavor.user,
      appTitle: 'Premoncare',
      initialRoute: '/splash',
    );
  });

  testWidgets('PremonCareApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PremonCareApp(),
      ),
    );
    expect(find.byType(PremonCareApp), findsOneWidget);
  });
}
