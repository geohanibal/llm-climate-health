/// Unit and widget tests for the Climate-Health Copilot chat models and drawer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/chat_models.dart';
import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/widgets/chat_copilot_drawer.dart';

void main() {
  group('ChatModels Unit Tests', () {
    test('FormPrefillAction toParsedRequest converts fields accurately', () {
      const action = FormPrefillAction(
        disease: 'dengue',
        region: 'Thailand',
        variables: ['temperature', 'precipitation'],
        startDate: '2018-01-01',
        endDate: '2022-12-01',
        aggregation: 'native',
        climateSource: 'open-meteo-era5',
      );

      final parsed = action.toParsedRequest();
      expect(parsed.disease, 'dengue');
      expect(parsed.region, 'Thailand');
      expect(parsed.variables, ['temperature', 'precipitation']);
      expect(parsed.startDate, DateTime(2018, 1, 1));
      expect(parsed.endDate, DateTime(2022, 12, 1));
      expect(parsed.aggregation, 'native');
      expect(parsed.climateSource, 'open-meteo-era5');
    });

    test('ActiveResultSummary.fromIntegrationResult extracts metrics cleanly', () {
      const result = IntegrationResult(
        disease: 'dengue',
        region: 'Thailand',
        resolution: 'month',
        steps: ['step 1', 'step 2'],
        explanation: 'Test explanation',
        explanationSource: 'llm',
        data: [
          PeriodRecord(period: '2020-01', caseCount: 100),
          PeriodRecord(period: '2020-02', caseCount: 200),
        ],
        sources: ['Source A'],
        cached: false,
        lastVerified: '2026-10-04',
        statisticalSummary: StatisticalSummary(
          sampleSize: 2,
          totalCases: 300,
          peakPeriod: '2020-02',
          peakCases: 200,
          meanTemperatureC: 27.5,
          meanPrecipitationMm: 120.0,
          correlations: [
            CorrelationMetric(
              variable: 'temperature',
              lagPeriods: 1,
              pearsonR: 0.55,
              significant: true,
            ),
          ],
        ),
      );

      final summary = ActiveResultSummary.fromIntegrationResult(result);
      expect(summary.disease, 'dengue');
      expect(summary.region, 'Thailand');
      expect(summary.totalCases, 300);
      expect(summary.peakPeriod, '2020-02');
      expect(summary.peakCases, 200);
      expect(summary.meanTemperatureC, 27.5);
      expect(summary.meanPrecipitationMm, 120.0);
      expect(summary.correlationsSummary, isNotNull);
      expect(summary.correlationsSummary!.first, contains('temperature Lag 1'));
    });

    test('ChatResponse.fromJson decodes reply, action, and prompts', () {
      final json = {
        'reply': 'ეს არის პასუხი',
        'suggested_action': {
          'disease': 'malaria',
          'region': 'Kenya',
        },
        'suggested_prompts': ['კითხვა 1', 'კითხვა 2'],
      };

      final resp = ChatResponse.fromJson(json);
      expect(resp.reply, 'ეს არის პასუხი');
      expect(resp.suggestedAction?.disease, 'malaria');
      expect(resp.suggestedAction?.region, 'Kenya');
      expect(resp.suggestedPrompts, ['კითხვა 1', 'კითხვა 2']);
    });
  });

  group('ChatCopilotDrawer Widget Tests', () {
    testWidgets('renders Copilot title, welcome text, and input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: null,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: DateTime(2018, 1, 1),
              currentEndDate: DateTime(2022, 12, 1),
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Climate-Health Copilot'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays active result badge when result is loaded', (tester) async {
      const result = IntegrationResult(
        disease: 'dengue',
        region: 'Thailand',
        resolution: 'month',
        steps: [],
        explanation: 'Loaded',
        explanationSource: 'llm',
        data: [],
        sources: [],
        cached: false,
        lastVerified: '2026-10-04',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: result,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: DateTime(2018, 1, 1),
              currentEndDate: DateTime(2022, 12, 1),
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Active Data: dengue • Thailand'), findsOneWidget);
    });

    testWidgets('tapping close calls onClose callback', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: null,
              currentDisease: null,
              currentRegion: null,
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });
}
