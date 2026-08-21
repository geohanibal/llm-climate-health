/// Widget tests for the case-count and temperature small-multiple charts.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/widgets/case_chart_card.dart';
import 'package:climate_health_frontend/widgets/metric_line_chart.dart';
import 'package:climate_health_frontend/widgets/temperature_chart_card.dart';

const _data = [
  PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0, precipitationSumMm: 10.0),
  PeriodRecord(period: '2020-02', caseCount: 12, temperatureMeanC: 27.5, precipitationSumMm: 8.0),
  PeriodRecord(period: '2020-03'),
];

Widget _wrapChart(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(height: 300, child: child)));

// SectionCard-wrapped cards need their natural height (title + padding +
// the 260px chart), not the fixed 300px used for the bare chart above.
Widget _wrapCard(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('MetricLineChart renders a line for populated data', (tester) async {
    await tester.pumpWidget(
      _wrapChart(
        MetricLineChart(
          data: _data,
          valueOf: (r) => r.caseCount,
          formatValue: (v) => v.toStringAsFixed(0),
          noDataMessage: 'No data',
          lightColor: Colors.teal,
          darkColor: Colors.tealAccent,
        ),
      ),
    );

    expect(find.text('No data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MetricLineChart shows the no-data message when every value is null', (tester) async {
    await tester.pumpWidget(
      _wrapChart(
        MetricLineChart(
          data: _data,
          valueOf: (r) => null,
          formatValue: (v) => v.toStringAsFixed(0),
          noDataMessage: 'No data available',
          lightColor: Colors.teal,
          darkColor: Colors.tealAccent,
        ),
      ),
    );

    expect(find.text('No data available'), findsOneWidget);
  });

  testWidgets('CaseChartCard builds without throwing', (tester) async {
    await tester.pumpWidget(_wrapCard(CaseChartCard(data: _data, resolution: 'month')));
    expect(find.text('Case counts per month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TemperatureChartCard builds without throwing', (tester) async {
    await tester.pumpWidget(_wrapCard(TemperatureChartCard(data: _data, resolution: 'month')));
    expect(find.text('Temperature per month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TemperatureChartCard shows its no-data message when no record has a temperature', (tester) async {
    const noTemp = [PeriodRecord(period: '2020-01', caseCount: 5)];
    await tester.pumpWidget(_wrapCard(TemperatureChartCard(data: noTemp, resolution: 'month')));
    expect(find.text('No temperature data available for this selection.'), findsOneWidget);
  });
}
