/// Unit tests for LiteraturePdfService and CustomLiteratureStore.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/core/localization.dart';
import 'package:climate_health_frontend/models/literature_item.dart';
import 'package:climate_health_frontend/services/literature_pdf_service.dart';

void main() {
  group('LiteratureItem & Store Tests', () {
    test('Default scientific corpora are non-empty and well-formed', () {
      expect(kScientificCorpora, isNotEmpty);
      expect(kScientificCorpora.length, 4);

      for (final item in kScientificCorpora) {
        expect(item.title, isNotEmpty);
        expect(item.authors, isNotEmpty);
        expect(item.citation, isNotEmpty);
        expect(item.getFocus(AppLanguage.ka), isNotEmpty);
        expect(item.getFocus(AppLanguage.en), isNotEmpty);
        expect(item.getFocus(AppLanguage.de), isNotEmpty);
        expect(item.getBibTeX(), contains('@article'));
      }
    });

    test('CustomLiteratureStore adds and removes custom items reactively', () {
      final store = CustomLiteratureStore.instance;
      store.clear();
      expect(store.customItems, isEmpty);

      const customItem = LiteratureItem(
        corpus: LiteratureCorpus.custom,
        id: 'test_item_1',
        tag: 'Custom 2024',
        title: 'Custom Vector Study',
        authors: 'Tester, A.',
        year: '2024',
        journal: 'Journal of Testing',
        citation: 'Tester, A. (2024). Custom Vector Study. Journal of Testing.',
        focusKa: 'ფოკუსი ქართულად',
        focusEn: 'Focus in English',
        focusDe: 'Fokus auf Deutsch',
        differencesKa: 'განსხვავება',
        differencesEn: 'Differences',
        differencesDe: 'Unterschiede',
        abstractKa: 'რეზიუმე',
        abstractEn: 'Abstract',
        abstractDe: 'Zusammenfassung',
        methodologyKa: 'მეთოდოლოგია',
        methodologyEn: 'Methodology',
        methodologyDe: 'Methodik',
        keyFindingsKa: 'მიგნებები',
        keyFindingsEn: 'Key findings',
        keyFindingsDe: 'Erkenntnisse',
        isCustom: true,
      );

      store.addCustomItem(customItem);
      expect(store.customItems.length, 1);
      expect(store.customItems.first.title, 'Custom Vector Study');

      store.removeCustomItem('test_item_1');
      expect(store.customItems, isEmpty);
    });
  });

  group('LiteraturePdfService Tests', () {
    test('buildDocumentBytes produces valid PDF bytes for standard WHO corpus', () async {
      const service = LiteraturePdfService();
      final bytes = await service.buildDocumentBytes(
        item: kScientificCorpora.first,
        lang: AppLanguage.en,
      );

      expect(bytes, isNotEmpty);
      // Valid PDF magic bytes
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('buildDocumentBytes produces valid PDF bytes for custom literature item', () async {
      const service = LiteraturePdfService();
      const customItem = LiteratureItem(
        corpus: LiteratureCorpus.custom,
        id: 'custom_doc',
        tag: 'Custom 2024',
        title: 'Empirical Dengue Modeling in Southeast Asia',
        authors: 'Koniashvili, S.',
        year: '2024',
        journal: 'University of Bremen Thesis Series',
        citation: 'Koniashvili, S. (2024). Empirical Dengue Modeling in Southeast Asia.',
        url: 'https://github.com/geohanibal/llm-climate-health',
        focusKa: 'ფოკუსი',
        focusEn: 'Focus on thermal suitability and climate lags.',
        focusDe: 'Fokus',
        differencesKa: 'განსხვავება',
        differencesEn: 'Integrates ERA5 reanalysis directly with monthly epidemiological surveillance.',
        differencesDe: 'Unterschiede',
        abstractKa: 'რეზიუმე',
        abstractEn: 'This study presents an end-to-end framework linking weather reanalysis with case counts.',
        abstractDe: 'Abstract',
        methodologyKa: 'მეთოდოლოგია',
        methodologyEn: 'Harmonization across spatial resolutions and cross-correlation estimation.',
        methodologyDe: 'Methodik',
        keyFindingsKa: 'მიგნებები',
        keyFindingsEn: 'Strongest cross-correlation observed at lag 1 to 2 months.',
        keyFindingsDe: 'Erkenntnisse',
        isCustom: true,
      );

      final bytes = await service.buildDocumentBytes(
        item: customItem,
        lang: AppLanguage.en,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
