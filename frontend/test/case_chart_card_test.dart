/// Widget tests for the interactive multi-series climate-health chart.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/widgets/case_chart_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('renders series and their toggle chips when data is present', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0, precipitationSumMm: 120.0),
      PeriodRecord(period: '2020-02', caseCount: 12, temperatureMeanC: 27.5, precipitationSumMm: 150.0),
      PeriodRecord(period: '2020-03', caseCount: 3, temperatureMeanC: 25.1, precipitationSumMm: 80.0),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Case counts & climate per month'), findsOneWidget);
    expect(find.text('Cases (left axis)'), findsOneWidget);
    expect(find.text('Temperature (right axis)'), findsOneWidget);
    expect(find.text('Precipitation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows only the case-count toggle when temperature/precipitation are missing', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', caseCount: 5),
      PeriodRecord(period: '2020-02', caseCount: 12),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Cases (left axis)'), findsOneWidget);
    expect(find.text('Temperature (right axis)'), findsNothing);
    expect(find.text('Precipitation'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling a series off updates chart state without error', (tester) async {
    const data = [
      PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0),
      PeriodRecord(period: '2020-02', caseCount: 12, temperatureMeanC: 27.5),
    ];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('Cases (left axis)'), findsOneWidget);
    await tester.tap(find.text('Cases (left axis)'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a no-data message when neither series has any values', (tester) async {
    const data = [PeriodRecord(period: '2020-01'), PeriodRecord(period: '2020-02')];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(find.text('No case or climate data available for this selection.'), findsOneWidget);
  });

  testWidgets('handles a single data point without dividing by zero', (tester) async {
    const data = [PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0)];

    await tester.pumpWidget(_wrap(const CaseChartCard(data: data, resolution: 'month')));

    expect(tester.takeException(), isNull);
  });
}
