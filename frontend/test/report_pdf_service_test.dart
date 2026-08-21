/// Unit tests for ReportPdfService's PDF byte-building logic. Only
/// `buildDocumentBytes` (pure `package:pdf` document construction) is
/// tested here — the browser download trigger itself needs a real browser
/// and is out of scope for a VM-based `flutter test` run.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/services/report_pdf_service.dart';

IntegrationResult _result() => const IntegrationResult(
      disease: 'dengue',
      region: 'Thailand',
      resolution: 'month',
      steps: ['step one', 'step two'],
      explanation: 'A plain-language summary.',
      explanationSource: 'fallback',
      data: [
        PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0, precipitationSumMm: 10.0),
      ],
      sources: ['Climate: cite A', 'Cases: cite B'],
      cached: false,
      lastVerified: '2024-01-01T00:00:00Z',
    );

void main() {
  test('buildDocumentBytes produces non-empty, well-formed PDF bytes', () async {
    const service = ReportPdfService();
    final bytes = await service.buildDocumentBytes(
      result: _result(),
      disease: 'Dengue',
      region: 'Thailand',
    );

    expect(bytes, isNotEmpty);
    // Every PDF file starts with this magic header, regardless of content.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
