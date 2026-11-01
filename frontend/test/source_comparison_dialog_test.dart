/// Widget tests for SourceComparisonDialog (FR-27 / A19).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/core/localization.dart';
import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/source_comparison.dart';
import 'package:climate_health_frontend/services/api_client.dart';
import 'package:climate_health_frontend/widgets/source_comparison_dialog.dart';

class _MockApiClient extends ApiClient {
  final SourceComparisonResponse? responseToReturn;

  const _MockApiClient({this.responseToReturn});

  @override
  Future<SourceComparisonResponse> compareSources(SourceComparisonRequest req) async {
    return responseToReturn ??
        SourceComparisonResponse(
          compareKind: req.compareKind,
          sourceALabel: 'Open-Meteo ERA5',
          sourceBLabel: 'NASA POWER',
          resolution: 'month',
          variables: [
            VariableComparison(
              variable: 'Mean temperature (°C)',
              overlapPeriods: 6,
              pearsonR: 0.99,
              pValue: 0.0001,
              formattedPValue: 'p<0.001',
              meanDifference: 0.25,
              meanAbsoluteDifference: 0.30,
              relativeMeanAbsoluteDifferencePercent: 1.2,
              verdict: 'very_similar',
              verdictExplanation:
                  'Mean temperature: correlation is r = 0.99 (p<0.001); mean difference is +0.25 °C (relative MAD: 1.2%). Very strong agreement across all periods. A high r partly reflects the shared seasonal cycle; the mean difference shows the systematic offset.',
              tooFewPoints: false,
              seriesA: [
                SeriesPoint(period: '2020-01', value: 25.0),
                SeriesPoint(period: '2020-02', value: 26.0),
              ],
              seriesB: [
                SeriesPoint(period: '2020-01', value: 25.2),
                SeriesPoint(period: '2020-02', value: 26.3),
              ],
            )
          ],
          methodologyNote:
              'Rule of thumb, not a statistical test. No significance is claimed.',
        );
  }
}

IntegrationResult _fakeResult() {
  return IntegrationResult(
    disease: 'dengue',
    region: 'Thailand',
    resolution: 'month',
    sources: const ['Open-Meteo ERA5', 'OpenDengue', 'World Bank'],
    licenses: const ['CC-BY 4.0'],
    steps: const ['Step 1'],
    explanation: 'Test explanation',
    explanationSource: 'Gemini',
    data: const [],
    cached: false,
    lastVerified: '2026-11-01',
    requestEcho: const {
      'disease': 'dengue',
      'region': 'Thailand',
      'variables': ['temperature', 'precipitation'],
      'start_date': '2020-01-01',
      'end_date': '2020-06-30',
      'aggregation': 'native',
      'climate_source': 'open-meteo-era5',
      'case_data_source': 'builtin',
    },
  );
}

void main() {
  setUp(() {
    appLocale.setLanguage(AppLanguage.en);
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders dialog, disclaimer, and comparison results', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = _MockApiClient();
    final result = _fakeResult();

    await tester.pumpWidget(wrap(SourceComparisonDialog(
      result: result,
      apiClient: mockApi,
    )));
    await tester.pumpAndSettle();

    // Verify dialog title & disclaimer banner
    expect(find.text('Source Comparison (FR-27)'), findsOneWidget);
    expect(
      find.text('This comparison does not alter your current integrated dataset or cache.'),
      findsOneWidget,
    );

    // Verify source label banner
    expect(find.textContaining('Open-Meteo ERA5'), findsWidgets);
    expect(find.textContaining('NASA POWER'), findsWidgets);

    // Verify variable name and verdict chip
    expect(find.text('Mean temperature (°C)'), findsOneWidget);
    expect(find.text('Very Similar'), findsOneWidget);

    // Verify explanation with seasonal cycle sentence
    expect(
      find.textContaining('A high r partly reflects the shared seasonal cycle'),
      // The taller dialog shows both variable cards, so the note can appear twice.
      findsWidgets,
    );

    // Verify metrics in expansion tile
    final expansionFinder = find.textContaining('Detailed metrics');
    expect(expansionFinder, findsOneWidget);
    await tester.ensureVisible(expansionFinder);
    await tester.pumpAndSettle();
    await tester.tap(expansionFinder);
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget); // 6 overlapping points
    expect(find.text('+0.25'), findsOneWidget); // mean difference
    expect(find.text('1.2%'), findsOneWidget); // rel MAD
  });

  testWidgets('shows resolution mismatch error when sources resolve differently', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mismatchResp = SourceComparisonResponse(
      compareKind: 'climate',
      sourceALabel: 'Source A',
      sourceBLabel: 'Source B',
      resolution: 'mismatch',
      variables: const [],
      methodologyNote: 'Note',
      resolutionMismatch: true,
      resolutionMismatchMessage:
          'Resolution mismatch: primary source resolved to monthly, but alternative source resolved to yearly.',
    );

    final mockApi = _MockApiClient(responseToReturn: mismatchResp);
    final result = _fakeResult();

    await tester.pumpWidget(wrap(SourceComparisonDialog(
      result: result,
      apiClient: mockApi,
    )));
    await tester.pumpAndSettle();

    expect(
      find.text('The two sources resolve to different temporal resolutions; comparison is not possible.'),
      findsOneWidget,
    );
    expect(find.textContaining('Resolution mismatch:'), findsOneWidget);
  });

  testWidgets('shows yearly resolution banner and excluded years when comparedAtYearlyResolution is true', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final yearlyResp = SourceComparisonResponse(
      compareKind: 'cases',
      sourceALabel: 'OpenDengue',
      sourceBLabel: 'WHO GHO',
      resolution: 'year',
      comparedAtYearlyResolution: true,
      excludedYears: const ['2010'],
      variables: [
        VariableComparison(
          variable: 'Case counts',
          overlapPeriods: 2,
          pearsonR: 0.95,
          pValue: 0.01,
          formattedPValue: 'p=0.01',
          meanDifference: 100.0,
          meanAbsoluteDifference: 120.0,
          relativeMeanAbsoluteDifferencePercent: 5.0,
          verdict: 'very_similar',
          verdictExplanation: 'Strong yearly agreement.',
          tooFewPoints: true,
          seriesA: [
            SeriesPoint(period: '2011', value: 1000.0),
            SeriesPoint(period: '2012', value: 1200.0),
          ],
          seriesB: [
            SeriesPoint(period: '2011', value: 1100.0),
            SeriesPoint(period: '2012', value: 1300.0),
          ],
        ),
      ],
      methodologyNote: 'Methodology note',
    );

    final mockApi = _MockApiClient(responseToReturn: yearlyResp);
    final result = _fakeResult();

    await tester.pumpWidget(wrap(SourceComparisonDialog(
      result: result,
      apiClient: mockApi,
    )));
    await tester.pumpAndSettle();

    // Verify yearly resolution banner and excluded years text
    expect(find.textContaining('Compared at yearly resolution'), findsOneWidget);
    expect(find.textContaining('Excluded incomplete years: 2010'), findsOneWidget);
    expect(find.textContaining('Few annual data points are available (2 years)'), findsOneWidget);
  });

  testWidgets('shows source B selector options for cases and toggles between them', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = _MockApiClient();
    final result = _fakeResult();

    await tester.pumpWidget(wrap(SourceComparisonDialog(
      result: result,
      apiClient: mockApi,
    )));
    await tester.pumpAndSettle();

    // Tap on "Case data sources"
    await tester.tap(find.text('Disease/Case Sources'));
    await tester.pumpAndSettle();

    // Verify case source B options are visible
    expect(find.text('WHO GHO Indicator'), findsOneWidget);
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Upload CSV file'), findsOneWidget);
    expect(find.text('Search & pick WHO indicator'), findsOneWidget);
  });
}
