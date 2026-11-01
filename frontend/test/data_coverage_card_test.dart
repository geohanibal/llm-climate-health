/// Widget tests for DataCoverageCard (FR-26, A18).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/core/localization.dart';
import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/widgets/data_coverage_card.dart';

void main() {
  setUp(() {
    appLocale.setLanguage(AppLanguage.en);
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('renders nothing when there are no missing periods', (tester) async {
    const coverage = [
      DataCoverage(
        column: 'case_count',
        totalPeriods: 10,
        periodsWithValue: 10,
        missingCount: 0,
        missingPercent: 0.0,
      ),
      DataCoverage(
        column: 'temperature_mean_c',
        totalPeriods: 10,
        periodsWithValue: 10,
        missingCount: 0,
        missingPercent: 0.0,
      ),
    ];

    await tester.pumpWidget(wrap(const DataCoverageCard(coverage: coverage)));
    expect(find.byType(Card), findsNothing);
    expect(find.text('Data Completeness & Gaps'), findsNothing);
  });

  testWidgets('renders warning card and action buttons when gaps exist', (tester) async {
    bool searchCasesCalled = false;
    DateTime? adjustedStart;
    DateTime? adjustedEnd;

    const coverage = [
      DataCoverage(
        column: 'case_count',
        totalPeriods: 72,
        periodsWithValue: 24,
        missingCount: 48,
        missingPercent: 66.7,
        missingRanges: [MissingRange(start: '2005-01', end: '2008-12')],
        firstAvailable: '2009-01',
        lastAvailable: '2010-12',
        reason: 'outside_source_coverage',
        availableRange: {'start': '2009-01', 'end': '2023-12'},
      ),
      DataCoverage(
        column: 'temperature_mean_c',
        totalPeriods: 72,
        periodsWithValue: 72,
        missingCount: 0,
        missingPercent: 0.0,
      ),
    ];

    await tester.pumpWidget(
      wrap(
        DataCoverageCard(
          coverage: coverage,
          onSearchCaseSources: () => searchCasesCalled = true,
          onAdjustDateRange: (s, e) {
            adjustedStart = s;
            adjustedEnd = e;
          },
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Data Completeness & Gaps'), findsOneWidget);
    expect(find.textContaining('missing for 48 of 72 periods (2005-01 – 2008-12)'), findsOneWidget);
    expect(find.textContaining('Reason: the selected source only covers 2009-01 – 2023-12'), findsOneWidget);
    expect(find.text('Search other case-data sources'), findsOneWidget);
    expect(find.textContaining('Adjust period to available data'), findsOneWidget);

    // Tap search button
    await tester.tap(find.text('Search other case-data sources'));
    await tester.pump();
    expect(searchCasesCalled, isTrue);

    // Tap adjust date range button
    await tester.tap(find.textContaining('Adjust period to available data'));
    await tester.pump();
    expect(adjustedStart, equals(DateTime(2009, 1, 1)));
    expect(adjustedEnd, equals(DateTime(2010, 12, 31)));
  });

  testWidgets('shows alternative climate source button when climate gaps exist', (tester) async {
    String? switchedSource;

    const coverage = [
      DataCoverage(
        column: 'temperature_mean_c',
        totalPeriods: 12,
        periodsWithValue: 6,
        missingCount: 6,
        missingPercent: 50.0,
        missingRanges: [MissingRange(start: '2020-07', end: '2020-12')],
        reason: 'gaps_inside_source',
      ),
    ];

    await tester.pumpWidget(
      wrap(
        DataCoverageCard(
          coverage: coverage,
          currentClimateSource: 'open-meteo-era5',
          onChangeClimateSource: (src) => switchedSource = src,
        ),
      ),
    );

    expect(find.text('Alternative climate source: NASA POWER'), findsOneWidget);
    await tester.tap(find.text('Alternative climate source: NASA POWER'));
    await tester.pump();
    expect(switchedSource, 'nasa-power');
  });

  testWidgets('renders neutrally when reason is not_provided_by_source', (tester) async {
    const coverage = [
      DataCoverage(
        column: 'temperature_mean_c',
        totalPeriods: 12,
        periodsWithValue: 0,
        missingCount: 12,
        missingPercent: 100.0,
        reason: 'not_provided_by_source',
      ),
    ];

    await tester.pumpWidget(wrap(const DataCoverageCard(coverage: coverage)));
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Data Completeness & Gaps'), findsOneWidget);
    expect(find.text('Reason: this variable is not provided by this data source.'), findsOneWidget);
  });
}

