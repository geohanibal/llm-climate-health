/// Converts the integrated dataset to CSV/JSON and triggers a browser
/// download, so the user can save the result to their own computer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';

import '../models/period_record.dart';
import 'browser_download_service.dart';

enum ExportFormat { csv, json }

/// Builds a downloadable file from the joined dataset. The actual browser
/// download mechanics live in [BrowserDownloadService], shared with the PDF
/// report export.
class DatasetExportService {
  /// Injectable so tests can supply a fake and assert on what would have
  /// been downloaded, without touching the browser.
  final BrowserDownloadService download;

  const DatasetExportService({this.download = const BrowserDownloadService()});

  void export(
    List<PeriodRecord> data,
    ExportFormat format, {
    String fileNamePrefix = 'climate_health_dataset',
  }) {
    switch (format) {
      case ExportFormat.csv:
        download.downloadText(toCsv(data), 'text/csv', '$fileNamePrefix.csv');
      case ExportFormat.json:
        download.downloadText(toJson(data), 'application/json', '$fileNamePrefix.json');
    }
  }

  String toCsv(List<PeriodRecord> data) {
    final buffer = StringBuffer(
      'period,case_count,population,incidence_rate_per_100k,temperature_mean_c,precipitation_sum_mm\n',
    );
    for (final record in data) {
      buffer.writeln(
        '${record.period},${record.caseCount ?? ''},'
        '${record.population ?? ''},${record.incidenceRatePer100k ?? ''},'
        '${record.temperatureMeanC ?? ''},${record.precipitationSumMm ?? ''}',
      );
    }
    return buffer.toString();
  }

  String toJson(List<PeriodRecord> data) {
    return const JsonEncoder.withIndent('  ').convert(data.map((r) => r.toJson()).toList());
  }
}
