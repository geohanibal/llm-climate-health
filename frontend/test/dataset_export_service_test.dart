/// Unit tests for DatasetExportService's CSV/JSON byte-building logic and
/// the provenance metadata exported with every dataset (FR-25). A fake
/// BrowserDownloadService (injected via the constructor) captures every file
/// that would have been downloaded, without touching the browser.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/services/browser_download_service.dart';
import 'package:climate_health_frontend/services/dataset_export_service.dart';

/// One captured download.
class _Download {
  final String content;
  final String mimeType;
  final String fileName;
  const _Download(this.content, this.mimeType, this.fileName);
}

class _FakeDownloadService implements BrowserDownloadService {
  final List<_Download> downloads = [];

  @override
  void downloadBytes(Uint8List bytes, String mimeType, String fileName) {
    throw UnimplementedError('not used by DatasetExportService');
  }

  @override
  void downloadText(String content, String mimeType, String fileName) {
    downloads.add(_Download(content, mimeType, fileName));
  }

  @override
  void openUrl(String url) {}
}

void main() {
  const data = [
    PeriodRecord(
      period: '2020-01',
      caseCount: 5,
      population: 70000000,
      incidenceRatePer100k: 0.007,
      temperatureMeanC: 26.0,
      precipitationSumMm: 10.0,
    ),
    PeriodRecord(period: '2020-02'),
  ];

  const result = IntegrationResult(
    disease: 'dengue',
    region: 'Thailand',
    resolution: 'month',
    steps: ['Received request', 'Joined case and climate data'],
    explanation: 'test',
    explanationSource: 'fallback',
    data: data,
    sources: ['Climate data: ERA5', 'Case counts: OpenDengue', 'Demographics & Population: World Bank'],
    licenses: [
      'Climate data: CC BY 4.0',
      'Case counts: OpenDengue V1.3: CC BY 4.0',
      'Demographics & Population: CC BY 4.0',
    ],
    systemVersion: 'git-abc1234',
    requestEcho: {'start_date': '2020-01-01', 'end_date': '2020-02-29', 'lag_periods': <int>[]},
    cached: false,
    lastVerified: '2026-11-01T10:00:00Z',
  );
  final exportedAt = DateTime.utc(2026, 11, 1, 12);

  test('toCsv renders one header row plus one row per record, blanking null fields', () {
    const service = DatasetExportService();
    final csv = service.toCsv(data);
    final lines = const LineSplitter().convert(csv.trim());

    expect(
      lines[0],
      'period,case_count,population,incidence_rate_per_100k,temperature_mean_c,precipitation_sum_mm',
    );
    expect(lines[1], '2020-01,5.0,70000000.0,0.007,26.0,10.0');
    expect(lines[2], '2020-02,,,,,');
  });

  test('export(json) writes {metadata, data}; data rows are unchanged', () {
    final fake = _FakeDownloadService();
    DatasetExportService(download: fake)
        .export(result, ExportFormat.json, fileNamePrefix: 'my_dataset', exportedAt: exportedAt);

    expect(fake.downloads, hasLength(1));
    expect(fake.downloads.single.fileName, 'my_dataset.json');
    expect(fake.downloads.single.mimeType, 'application/json');
    final decoded = jsonDecode(fake.downloads.single.content) as Map<String, dynamic>;
    final rows = decoded['data'] as List;
    expect(rows, hasLength(2));
    expect(rows[0]['period'], '2020-01');
    expect(rows[0]['case_count'], 5.0);
    expect(rows[0]['population'], 70000000.0);
    expect(rows[0]['incidence_rate_per_100k'], 0.007);
    expect(rows[1]['case_count'], isNull);
  });

  test('exported metadata answers what, where, when, from which source, licence and version', () {
    final fake = _FakeDownloadService();
    DatasetExportService(download: fake).export(result, ExportFormat.json, exportedAt: exportedAt);

    final decoded = jsonDecode(fake.downloads.single.content) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;
    expect(metadata['disease'], 'dengue');
    expect(metadata['region'], 'Thailand');
    expect(metadata['resolution'], 'month');
    expect(metadata['period_start'], '2020-01');
    expect(metadata['period_end'], '2020-02');
    // Only 2020-01 has a case count, so the covered case period is narrower.
    expect(metadata['case_data_start'], '2020-01');
    expect(metadata['case_data_end'], '2020-01');
    expect(metadata['sources'], hasLength(3));
    expect(metadata['licenses'], contains('Case counts: OpenDengue V1.3: CC BY 4.0'));
    expect(metadata['processing_steps'], hasLength(2));
    expect(metadata['retrieved_at'], '2026-11-01T10:00:00Z');
    expect(metadata['exported_at'], '2026-11-01T12:00:00.000Z');
    expect(metadata['system_version'], 'git-abc1234');
    expect((metadata['request'] as Map)['start_date'], '2020-01-01');
    expect((metadata['notes'] as List).single, contains('Case definitions'));
    expect(metadata['data_coverage'], isEmpty);
  });

  test('exported metadata includes data_coverage breakdown (FR-26)', () {
    const covResult = IntegrationResult(
      disease: 'dengue',
      region: 'Thailand',
      resolution: 'month',
      steps: ['Test step'],
      explanation: 'test',
      explanationSource: 'fallback',
      data: data,
      sources: ['Source A'],
      cached: false,
      lastVerified: '2026-11-01T10:00:00Z',
      dataCoverage: [
        DataCoverage(
          column: 'case_count',
          totalPeriods: 2,
          periodsWithValue: 1,
          missingCount: 1,
          missingPercent: 50.0,
          missingRanges: [MissingRange(start: '2020-02', end: '2020-02')],
          firstAvailable: '2020-01',
          lastAvailable: '2020-01',
          reason: 'gaps_inside_source',
        ),
      ],
    );
    final fake = _FakeDownloadService();
    DatasetExportService(download: fake).export(covResult, ExportFormat.json, exportedAt: exportedAt);

    final decoded = jsonDecode(fake.downloads.single.content) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;
    expect(metadata['data_coverage'], isA<List>());
    final covList = metadata['data_coverage'] as List;
    expect(covList, hasLength(1));
    expect(covList[0]['column'], 'case_count');
    expect(covList[0]['missing_count'], 1);
    expect(covList[0]['missing_percent'], 50.0);
    expect(covList[0]['reason'], 'gaps_inside_source');
    expect(covList[0]['missing_ranges'], hasLength(1));
    expect(covList[0]['missing_ranges'][0]['start'], '2020-02');
  });

  test('export(csv) downloads the plain CSV plus a separate metadata JSON file', () {
    final fake = _FakeDownloadService();
    DatasetExportService(download: fake)
        .export(result, ExportFormat.csv, fileNamePrefix: 'my_dataset', exportedAt: exportedAt);

    expect(fake.downloads.map((d) => d.fileName), ['my_dataset.csv', 'my_dataset_metadata.json']);
    final csv = fake.downloads[0];
    expect(csv.mimeType, 'text/csv');
    expect(csv.content, startsWith('period,'));
    expect(csv.content, isNot(contains('#')));
    expect(csv.content, contains('2020-01,5.0,70000000.0,0.007,26.0,10.0'));
    final metadata = jsonDecode(fake.downloads[1].content) as Map<String, dynamic>;
    expect(metadata['region'], 'Thailand');
    expect(metadata['licenses'], hasLength(3));
  });

  test('toCsv includes temperature_min_c and temperature_max_c when present', () {
    const minMaxData = [
      PeriodRecord(
        period: '2020-01',
        caseCount: 10,
        temperatureMeanC: 25.0,
        temperatureMinC: 20.0,
        temperatureMaxC: 30.0,
        precipitationSumMm: 50.0,
      ),
    ];
    const service = DatasetExportService();
    final csv = service.toCsv(minMaxData);
    final lines = const LineSplitter().convert(csv.trim());

    expect(
      lines[0],
      'period,case_count,population,incidence_rate_per_100k,temperature_mean_c,temperature_min_c,temperature_max_c,precipitation_sum_mm',
    );
    expect(lines[1], '2020-01,10.0,,,25.0,20.0,30.0,50.0');
  });

  test('toCsv appends lag columns (sorted) and blanks missing lag values', () {
    const lagData = [
      PeriodRecord(
        period: '2020-01',
        temperatureMeanC: 26.0,
        precipitationSumMm: 10.0,
        lagValues: {'temperature_lag1': 25.0, 'precipitation_lag1': 3.0},
      ),
      PeriodRecord(period: '2020-02', lagValues: {'temperature_lag1': null}),
    ];
    final lines = const LineSplitter().convert(const DatasetExportService().toCsv(lagData).trim());

    expect(
      lines[0],
      'period,case_count,population,incidence_rate_per_100k,temperature_mean_c,precipitation_sum_mm,'
      'precipitation_lag1,temperature_lag1',
    );
    expect(lines[1], '2020-01,,,,26.0,10.0,3.0,25.0');
    expect(lines[2], '2020-02,,,,,,,');
  });
}
