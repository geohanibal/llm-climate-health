/// Smoke test: the app boots and shows its title bar.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/app.dart';

void main() {
  testWidgets('App boots and shows the platform title', (WidgetTester tester) async {
    await tester.pumpWidget(const ClimateHealthApp());

    expect(find.text('Climate-Health Data Integration Platform'), findsOneWidget);
  });
}
