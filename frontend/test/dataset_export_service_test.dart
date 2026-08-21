/// Unit tests for DatasetExportService's CSV/JSON byte-building logic. A
/// fake BrowserDownloadService (injected via the constructor) captures what
/// would have been downloaded, without touching the browser.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/period_record.dart';
import 'package:climate_health_frontend/services/browser_download_service.dart';
import 'package:climate_health_frontend/services/dataset_export_service.dart';

class _FakeDownloadService implements BrowserDownloadService {
  String? lastContent;
  String? lastMimeType;
  String? lastFileName;

  @override
  void downloadBytes(Uint8List bytes, String mimeType, String fileName) {
    throw UnimplementedError('not used by DatasetExportService');
  }

  @override
  void downloadText(String content, String mimeType, String fileName) {
    lastContent = content;
    lastMimeType = mimeType;
    lastFileName = fileName;
  }
}

void main() {
  const data = [
    PeriodRecord(period: '2020-01', caseCount: 5, temperatureMeanC: 26.0, precipitationSumMm: 10.0),
    PeriodRecord(period: '2020-02'),
  ];

  test('toCsv renders one header row plus one row per record, blanking null fields', () {
    const service = DatasetExportService();
    final csv = service.toCsv(data);
    final lines = const LineSplitter().convert(csv.trim());

    expect(lines[0], 'period,case_count,temperature_mean_c,precipitation_sum_mm');
    expect(lines[1], '2020-01,5.0,26.0,10.0');
    expect(lines[2], '2020-02,,,');
  });

  test('toJson round-trips through PeriodRecord.toJson', () {
    const service = DatasetExportService();
    final decoded = jsonDecode(service.toJson(data)) as List;

    expect(decoded, hasLength(2));
    expect(decoded[0]['period'], '2020-01');
    expect(decoded[0]['case_count'], 5.0);
    expect(decoded[1]['case_count'], isNull);
  });

  test('export(csv) hands the CSV text to the injected download service', () {
    final fake = _FakeDownloadService();
    final service = DatasetExportService(download: fake);

    service.export(data, ExportFormat.csv, fileNamePrefix: 'my_dataset');

    expect(fake.lastFileName, 'my_dataset.csv');
    expect(fake.lastMimeType, 'text/csv');
    expect(fake.lastContent, contains('2020-01,5.0,26.0,10.0'));
  });

  test('export(json) hands the JSON text to the injected download service', () {
    final fake = _FakeDownloadService();
    final service = DatasetExportService(download: fake);

    service.export(data, ExportFormat.json, fileNamePrefix: 'my_dataset');

    expect(fake.lastFileName, 'my_dataset.json');
    expect(fake.lastMimeType, 'application/json');
    expect(jsonDecode(fake.lastContent!), hasLength(2));
  });
}
