/// Widget tests for the combined case-count + temperature dual-axis chart.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/widgets/case_chart_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('renders both series and their legend entries when both are present', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0),
      PeriodRecord(period: '2020-02', caseCount: 12, temperatureMeanC: 27.5),
      PeriodRecord(period: '2020-03', caseCount: 3, temperatureMeanC: 25.1),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Case counts & temperature per month'), findsOneWidget);
    expect(find.text('Case counts (left axis)'), findsOneWidget);
    expect(find.text('Temperature (right axis)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows only the case-count legend entry when temperature is missing', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', caseCount: 5),
      PeriodRecord(period: '2020-02', caseCount: 12),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Case counts (left axis)'), findsOneWidget);
    expect(find.text('Temperature (right axis)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows only the temperature legend entry when case counts are missing', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', temperatureMeanC: 26.0),
      PeriodRecord(period: '2020-02', temperatureMeanC: 27.5),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Case counts (left axis)'), findsNothing);
    expect(find.text('Temperature (right axis)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a no-data message when neither series has any values', (tester) async {
    const data = [PeriodRecord(period: '2020-01'), PeriodRecord(period: '2020-02')];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('No case or temperature data available for this selection.'), findsOneWidget);
  });

  testWidgets('handles a single data point without dividing by zero', (tester) async {
    const data = [PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0)];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(tester.takeException(), isNull);
  });
}
