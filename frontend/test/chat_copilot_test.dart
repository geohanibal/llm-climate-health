/// Unit and widget tests for the Climate-Health Copilot chat models and drawer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:climate_health_frontend/core/localization.dart';
import 'package:climate_health_frontend/models/chat_models.dart';
import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/parsed_request.dart';
import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/widgets/chat_copilot_drawer.dart';

void main() {
  setUp(() {
    appLocale.setLanguage(AppLanguage.ka);
  });
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

      expect(find.textContaining('${I18n.t('activeData')}: dengue • Thailand'), findsOneWidget);
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

    testWidgets('renders maximize button and calls onToggleExpand callback', (tester) async {
      bool toggled = false;

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
              isExpanded: false,
              onToggleExpand: () => toggled = true,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fullscreen_rounded));
      expect(toggled, isTrue);
    });

    testWidgets('renders prompt chips scroll controls and allows expanding to Wrap', (tester) async {
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
              onClose: () {},
            ),
          ),
        ),
      );

      // In welcome state, default chips are present
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.unfold_more), findsOneWidget);

      // Tap unfold_more to expand prompts
      await tester.tap(find.byIcon(Icons.unfold_more));
      await tester.pumpAndSettle();

      expect(find.textContaining('სავარაუდო კითხვები'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('displays searching indicator when isSearching is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: null,
              isSearching: true,
              currentDisease: null,
              currentRegion: null,
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('მიმდინარეობს ძებნა და ინტეგრაცია'), findsOneWidget);
      expect(find.textContaining('ინტეგრაცია მიმდინარეობს'), findsOneWidget);
    });

    testWidgets('renders active result toolbar with export, analysis, and new search buttons', (tester) async {
      const result = IntegrationResult(
        disease: 'dengue',
        region: 'Thailand',
        resolution: 'month',
        steps: [],
        explanation: 'Loaded successfully',
        explanationSource: 'llm',
        data: [
          PeriodRecord(period: '2020-01', caseCount: 100),
        ],
        sources: ['WHO GHO'],
        cached: false,
        lastVerified: '2026-10-04',
      );

      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: result,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onResetSearch: () => resetCalled = true,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('აქტიური მონაცემები: dengue (Thailand)'), findsOneWidget);
      expect(find.text('CSV'), findsWidgets);
      expect(find.text('JSON'), findsWidgets);
      expect(find.text('PDF რეპორტი'), findsWidgets);
      expect(find.textContaining('ანალიზი'), findsWidgets);
      expect(find.text('ახალი ძიება'), findsWidgets);

      // Tap new search button
      await tester.tap(find.text('ახალი ძიება').first);
      await tester.pumpAndSettle();

      expect(resetCalled, isTrue);
      expect(find.textContaining('ახალი ძიების რეჟიმი გააქტიურებულია', findRichText: true), findsOneWidget);
    });

    testWidgets('auto-injects result summary message into chat when activeResult arrives', (tester) async {
      const initialResult = null;
      const newResult = IntegrationResult(
        disease: 'dengue',
        region: 'Thailand',
        resolution: 'month',
        steps: [],
        explanation: 'Automated seasonal pattern detected.',
        explanationSource: 'llm',
        data: [
          PeriodRecord(period: '2020-01', caseCount: 50),
          PeriodRecord(period: '2020-02', caseCount: 150),
        ],
        sources: ['OpenDengue'],
        cached: false,
        lastVerified: '2026-10-04',
        statisticalSummary: StatisticalSummary(
          sampleSize: 2,
          totalCases: 200,
          peakPeriod: '2020-02',
          peakCases: 150,
          meanTemperatureC: 28.2,
          meanPrecipitationMm: 145.0,
          correlations: [
            CorrelationMetric(
              variable: 'temperature',
              lagPeriods: 1,
              pearsonR: 0.62,
              significant: true,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: initialResult,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ძებნა და ინტეგრაცია წარმატებით დასრულდა', findRichText: true), findsNothing);

      // Now update widget with new result
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              options: null,
              activeResult: newResult,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ძებნა და ინტეგრაცია წარმატებით დასრულდა', findRichText: true), findsOneWidget);
      expect(find.textContaining('სულ დაფიქსირებული შემთხვევები: 200', findRichText: true), findsOneWidget);
      expect(find.textContaining('ტემპერატურა: 28.2 °C | ნალექი: 145.0 მმ', findRichText: true), findsOneWidget);
      expect(find.textContaining('temperature Lag 1: r = 0.62', findRichText: true), findsOneWidget);
      expect(find.textContaining('სწრაფი მოქმედებები'), findsWidgets);
    });

    testWidgets('suggested action renders Apply & Search and calls onApplyAndSearch', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/chat') {
          return http.Response(
            jsonEncode({
              'reply': 'რეკომენდებული პარამეტრები:',
              'suggested_action': {
                'disease': 'dengue',
                'region': 'Thailand',
                'start_date': '2018-01-01',
                'end_date': '2022-12-01',
              },
              'suggested_prompts': ['შეკითხვა 1'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      ParsedRequest? searchedRequest;
      ParsedRequest? prefilledRequest;

      await http.runWithClient(() async {
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
                onApplyPrefill: (r) => prefilledRequest = r,
                onApplyAndSearch: (r) => searchedRequest = r,
                onClose: () {},
              ),
            ),
          ),
        );

        // Enter text and send
        await tester.enterText(find.byType(TextField), 'დამიყენე დენგე ტაილანდში');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        // Both buttons should be present with localized labels
        expect(find.text(I18n.t('applyAndSearch')), findsOneWidget);
        expect(find.text(I18n.t('applyToForm')), findsOneWidget);

        // Tap Apply & Search
        await tester.tap(find.text(I18n.t('applyAndSearch')));
        await tester.pumpAndSettle();

        expect(searchedRequest, isNotNull);
        expect(searchedRequest?.disease, 'dengue');
        expect(searchedRequest?.region, 'Thailand');

        // Tap Apply to Form
        await tester.tap(find.text(I18n.t('applyToForm')));
        await tester.pumpAndSettle();

        expect(prefilledRequest, isNotNull);
        expect(prefilledRequest?.disease, 'dengue');
        expect(prefilledRequest?.region, 'Thailand');
      }, () => mockClient);
    });

    testWidgets('switching language between ka, en, and de updates Copilot correctly', (tester) async {
      // Test English
      appLocale.setLanguage(AppLanguage.en);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              key: const ValueKey('copilot_en'),
              options: null,
              activeResult: null,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Your intelligent research assistant', findRichText: true), findsOneWidget);

      // Test German
      appLocale.setLanguage(AppLanguage.de);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCopilotDrawer(
              key: const ValueKey('copilot_de'),
              options: null,
              activeResult: null,
              currentDisease: 'dengue',
              currentRegion: 'Thailand',
              currentStartDate: null,
              currentEndDate: null,
              onApplyPrefill: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Forschungsassistent', findRichText: true), findsOneWidget);

      // Reset to Georgian
      appLocale.setLanguage(AppLanguage.ka);
    });
  });
}
