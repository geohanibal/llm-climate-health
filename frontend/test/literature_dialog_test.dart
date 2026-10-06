/// Widget tests for LiteratureKnowledgeDialog, LiteratureReaderDialog, and AddLiteratureDialog.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/core/localization.dart';
import 'package:climate_health_frontend/models/literature_item.dart';
import 'package:climate_health_frontend/services/api_client.dart';
import 'package:climate_health_frontend/widgets/add_literature_dialog.dart';
import 'package:climate_health_frontend/widgets/literature_knowledge_dialog.dart';
import 'package:climate_health_frontend/widgets/literature_reader_dialog.dart';

class FakeExtractApiClient extends ApiClient {
  final LiteratureExtractionResult mockResult;
  const FakeExtractApiClient(this.mockResult);

  @override
  Future<LiteratureExtractionResult> extractLiterature({
    Uint8List? fileBytes,
    String? fileName,
    String? url,
  }) async {
    return mockResult;
  }
}

void main() {
  setUp(() {
    appLocale.setLanguage(AppLanguage.ka);
    CustomLiteratureStore.instance.clear();
  });

  group('Literature Dialog Widget Tests', () {
    testWidgets('LiteratureKnowledgeDialog renders corpora, add button, and action buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiteratureKnowledgeDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & add button exist
      expect(find.text(I18n.t('literatureKnowledge')), findsAtLeastNWidgets(1));
      expect(find.text(I18n.t('addLiterature')), findsOneWidget);

      // Verify default corpora cards are rendered
      expect(find.text('Global Vector Control Response 2017–2030 & Operational Guidelines'), findsOneWidget);
      expect(find.text('The 2023 Report of the Lancet Countdown on Health and Climate Change'), findsOneWidget);

      // Verify Read Full Text and Download buttons exist
      expect(find.text(I18n.t('readFullLiterature')), findsAtLeastNWidgets(1));
      expect(find.text(I18n.t('downloadFullBook')), findsAtLeastNWidgets(1));
      expect(find.text(I18n.t('downloadSummaryDigest')), findsAtLeastNWidgets(1));
    });

    testWidgets('LiteratureReaderDialog renders tabs, abstract, and citation',
        (tester) async {
      final sampleItem = kScientificCorpora.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiteratureReaderDialog(item: sampleItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(sampleItem.title), findsOneWidget);
      expect(find.text(I18n.t('abstractTab')), findsOneWidget);
      expect(find.text(I18n.t('methodologyTab')), findsOneWidget);
      expect(find.text(I18n.t('keyFindingsTab')), findsOneWidget);
      expect(find.text(I18n.t('citationTab')), findsOneWidget);

      // Switch to citation tab
      await tester.tap(find.text(I18n.t('citationTab')));
      await tester.pumpAndSettle();

      expect(find.text(sampleItem.citation), findsOneWidget);
      expect(find.text(I18n.t('copyCitation')), findsAtLeastNWidgets(1));
    });

    testWidgets('AddLiteratureDialog validates required fields and submits',
        (tester) async {
      LiteratureItem? addedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddLiteratureDialog(
              onLiteratureAdded: (item) => addedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to save while empty -> validation errors
      await tester.tap(find.text(I18n.t('saveLiterature')));
      await tester.pumpAndSettle();
      expect(addedItem, isNull);

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'Climate Study on Malaria');
      await tester.enterText(find.byType(TextFormField).at(1), 'Koniashvili, S.');
      await tester.enterText(find.byType(TextFormField).at(2), '2025');
      await tester.enterText(find.byType(TextFormField).at(3), 'Nature Medicine');
      await tester.enterText(find.byType(TextFormField).at(4), 'https://doi.org/10.1038/example');
      await tester.enterText(find.byType(TextFormField).at(5), 'Research abstract on precipitation thresholds.');
      await tester.enterText(find.byType(TextFormField).at(6), 'Focuses on regional high-resolution data.');

      await tester.tap(find.text(I18n.t('saveLiterature')));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem!.title, 'Climate Study on Malaria');
      expect(addedItem!.authors, 'Koniashvili, S.');
      expect(addedItem!.isCustom, isTrue);
      expect(CustomLiteratureStore.instance.customItems.length, 1);
    });

    testWidgets('AddLiteratureDialog auto-populates empty fields upon AI extraction',
        (tester) async {
      const mockResult = LiteratureExtractionResult(
        title: 'Auto Extracted Title',
        authors: 'Auto Author',
        year: '2025',
        journal: 'The Lancet',
        url: 'https://doi.org/10.1016/sample',
        abstract: 'Auto extracted abstract content.',
        differences: 'Auto extracted differences.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddLiteratureDialog(
              apiClient: FakeExtractApiClient(mockResult),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter URL
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'https://doi.org/10.1016/sample',
      );

      // Tap AI extract button in URL field
      await tester.tap(find.widgetWithIcon(IconButton, Icons.auto_awesome).first);
      await tester.pumpAndSettle();

      // Form fields should be automatically populated
      expect(find.text('Auto Extracted Title'), findsOneWidget);
      expect(find.text('Auto Author'), findsOneWidget);
      expect(find.text('The Lancet'), findsOneWidget);
      expect(find.text('Auto extracted abstract content.'), findsOneWidget);
    });

    testWidgets('AddLiteratureDialog prompts user when fields are already filled',
        (tester) async {
      const mockResult = LiteratureExtractionResult(
        title: 'AI Extracted Title',
        authors: 'AI Author',
        year: '2026',
        journal: 'Nature Climate Change',
        url: 'https://doi.org/10.1038/example',
        abstract: 'AI Abstract',
        differences: 'AI Differences',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddLiteratureDialog(
              apiClient: FakeExtractApiClient(mockResult),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // User manually fills in fields first
      await tester.enterText(find.byType(TextFormField).at(0), 'User Manual Title');
      await tester.enterText(find.byType(TextFormField).at(1), 'User Author');
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'https://doi.org/10.1038/example',
      );

      // Trigger AI extraction
      await tester.tap(find.widgetWithIcon(IconButton, Icons.auto_awesome).first);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible!
      expect(find.text(I18n.t('aiOverwritePromptTitle')), findsOneWidget);
      expect(find.text(I18n.t('aiOverwriteKeepMine')), findsOneWidget);
      expect(find.text(I18n.t('aiOverwriteAccept')), findsOneWidget);

      // User clicks "Keep mine"
      await tester.tap(find.text(I18n.t('aiOverwriteKeepMine')));
      await tester.pumpAndSettle();

      // User's manual title remains intact!
      expect(find.text('User Manual Title'), findsOneWidget);
      expect(find.text('AI Extracted Title'), findsNothing);

      // User triggers extraction again
      await tester.tap(find.widgetWithIcon(IconButton, Icons.auto_awesome).first);
      await tester.pumpAndSettle();

      // User accepts AI version
      await tester.tap(find.text(I18n.t('aiOverwriteAccept')));
      await tester.pumpAndSettle();

      // Now fields are overwritten with AI version
      expect(find.text('AI Extracted Title'), findsOneWidget);
      expect(find.text('User Manual Title'), findsNothing);
    });
  });
}
