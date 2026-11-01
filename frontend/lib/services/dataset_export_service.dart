/// Converts the integrated dataset to CSV/JSON and triggers a browser
/// download, so the user can save the result to their own computer.
///
/// Every export carries provenance metadata (FR-25, [ExportMetadata]):
/// - JSON: one file `{"metadata": {...}, "data": [...]}`;
/// - CSV: the data file stays a plain table (readable by Excel/pandas without
///   special options) and a second file `<prefix>_metadata.json` is
///   downloaded next to it. Comment lines starting with `#` inside the CSV
///   were rejected because many tools misread them as data.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';

import '../models/export_metadata.dart';
import '../models/integration_result.dart';
import '../models/period_record.dart';
import 'browser_download_service.dart';

enum ExportFormat { csv, json }

/// Builds downloadable files from an integration result. The actual browser
/// download mechanics live in [BrowserDownloadService], shared with the PDF
/// report export.
class DatasetExportService {
  /// Injectable so tests can supply a fake and assert on what would have
  /// been downloaded, without touching the browser.
  final BrowserDownloadService download;

  const DatasetExportService({this.download = const BrowserDownloadService()});

  static const _encoder = JsonEncoder.withIndent('  ');

  /// [exportedAt] is only passed by tests, to get a fixed timestamp.
  void export(
    IntegrationResult result,
    ExportFormat format, {
    String fileNamePrefix = 'climate_health_dataset',
    DateTime? exportedAt,
  }) {
    final metadata = ExportMetadata.fromResult(result, exportedAt: exportedAt);
    switch (format) {
      case ExportFormat.csv:
        download.downloadText(toCsv(result.data), 'text/csv', '$fileNamePrefix.csv');
        download.downloadText(
          _encoder.convert(metadata.toJson()),
          'application/json',
          '${fileNamePrefix}_metadata.json',
        );
      case ExportFormat.json:
        download.downloadText(toJson(result.data, metadata), 'application/json', '$fileNamePrefix.json');
    }
  }

  /// Plain CSV table. Optional columns (Tmin/Tmax, lag columns) only appear
  /// when at least one row has them, so older-style requests keep the
  /// original six-column layout.
  String toCsv(List<PeriodRecord> data) {
    final hasMin = data.any((r) => r.temperatureMinC != null);
    final hasMax = data.any((r) => r.temperatureMaxC != null);
    final lagColumns = PeriodRecord.lagColumnNames(data);

    final header = [
      'period',
      'case_count',
      'population',
      'incidence_rate_per_100k',
      'temperature_mean_c',
      if (hasMin) 'temperature_min_c',
      if (hasMax) 'temperature_max_c',
      'precipitation_sum_mm',
      ...lagColumns,
    ].join(',');

    final buffer = StringBuffer('$header\n');
    for (final record in data) {
      final row = [
        record.period,
        record.caseCount ?? '',
        record.population ?? '',
        record.incidenceRatePer100k ?? '',
        record.temperatureMeanC ?? '',
        if (hasMin) record.temperatureMinC ?? '',
        if (hasMax) record.temperatureMaxC ?? '',
        record.precipitationSumMm ?? '',
        for (final column in lagColumns) record.lagValues[column] ?? '',
      ].join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  /// JSON export: each row keeps exactly the columns listed in
  /// `metadata.columns`, so unrequested Tmin/Tmax fields do not appear as
  /// all-null keys (found in the live export check 2026-11-01).
  String toJson(List<PeriodRecord> data, ExportMetadata metadata) {
    final keep = metadata.columns.keys.toSet();
    return _encoder.convert({
      'metadata': metadata.toJson(),
      'data': [
        for (final r in data)
          Map.fromEntries(r.toJson().entries.where((e) => keep.contains(e.key))),
      ],
    });
  }
}
