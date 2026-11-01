/// Provenance metadata written next to every exported dataset (FR-25).
///
/// An exported CSV/JSON file must answer, on its own: what was integrated,
/// for which region and period, from which sources, under which licences,
/// when the data were retrieved and with which software version. Without
/// this, a file on someone's disk cannot be traced back or reused correctly
/// (Clarke et al. 2024, OpenDengue: p. 4 source metadata, p. 12 version and
/// licence).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'integration_result.dart';

/// Reminder exported with every dataset: case counts are not comparable
/// across countries or years without checking how cases were defined
/// (Clarke et al. 2024, p. 10–12; RECOMMENDATIONS A15a).
const String caseDefinitionNote =
    'Case counts are reported as published by the source. Case definitions and '
    'reporting practices differ between countries and change over time; for '
    'OpenDengue, dengue_total counts all reported cases regardless of severity '
    'or laboratory confirmation. Compare across regions or periods with care.';

class ExportMetadata {
  final String disease;
  final String region;
  final String resolution;

  /// Request parameters exactly as the backend echoed them (dates,
  /// variables, sources, aggregation, lag periods), so the dataset can be
  /// re-created with the same settings.
  final Map<String, dynamic> request;

  /// First and last period present in the exported table.
  final String? periodStart;
  final String? periodEnd;

  /// First and last period that actually has a case count. Can be narrower
  /// than [periodStart]..[periodEnd] when the source has no data for part
  /// of the requested range (e.g. OpenDengue Thailand starts 2009-01).
  final String? caseDataStart;
  final String? caseDataEnd;

  final List<String> sources;
  final List<String> licenses;
  final List<String> steps;

  /// When the backend retrieved/processed the data (UTC, ISO 8601).
  final String retrievedAt;
  final bool fromCache;

  /// When the user clicked "export" (UTC, ISO 8601).
  final String exportedAt;
  final String systemVersion;
  final List<DataCoverage> dataCoverage;

  const ExportMetadata({
    required this.disease,
    required this.region,
    required this.resolution,
    required this.request,
    required this.periodStart,
    required this.periodEnd,
    required this.caseDataStart,
    required this.caseDataEnd,
    required this.sources,
    required this.licenses,
    required this.steps,
    required this.retrievedAt,
    required this.fromCache,
    required this.exportedAt,
    required this.systemVersion,
    this.dataCoverage = const [],
  });

  /// [exportedAt] is injectable so tests get a fixed timestamp.
  factory ExportMetadata.fromResult(IntegrationResult result, {DateTime? exportedAt}) {
    final data = result.data;
    final withCases = data.where((r) => r.caseCount != null).toList();
    return ExportMetadata(
      disease: result.disease,
      region: result.region,
      resolution: result.resolution,
      request: result.requestEcho,
      periodStart: data.isEmpty ? null : data.first.period,
      periodEnd: data.isEmpty ? null : data.last.period,
      caseDataStart: withCases.isEmpty ? null : withCases.first.period,
      caseDataEnd: withCases.isEmpty ? null : withCases.last.period,
      sources: result.sources,
      licenses: result.licenses,
      steps: result.steps,
      retrievedAt: result.lastVerified,
      fromCache: result.cached,
      exportedAt: (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      systemVersion: result.systemVersion,
      dataCoverage: result.dataCoverage,
    );
  }

  Map<String, dynamic> toJson() => {
        'disease': disease,
        'region': region,
        'resolution': resolution,
        'period_start': periodStart,
        'period_end': periodEnd,
        'case_data_start': caseDataStart,
        'case_data_end': caseDataEnd,
        'columns': _columnDescriptions,
        'request': request,
        'sources': sources,
        'licenses': licenses,
        'processing_steps': steps,
        'retrieved_at': retrievedAt,
        'from_cache': fromCache,
        'exported_at': exportedAt,
        'system_version': systemVersion,
        'data_coverage': dataCoverage.map((c) => c.toJson()).toList(),
        'notes': [caseDefinitionNote],
      };

  /// Units and meaning of the fixed columns; lag columns follow the pattern
  /// `<variable>_lag<k>` = value of that variable k periods earlier.
  static const Map<String, String> _columnDescriptions = {
    'period': 'time period label (YYYY-MM-DD, YYYY-MM, YYYY or YYYYs)',
    'case_count': 'reported cases in the period',
    'population': 'population (annual values linearly interpolated for monthly/daily data)',
    'incidence_rate_per_100k': 'case_count / population * 100,000',
    'temperature_mean_c': 'mean 2 m air temperature, degrees C',
    'temperature_min_c': 'mean of daily minimum temperature, degrees C',
    'temperature_max_c': 'mean of daily maximum temperature, degrees C',
    'precipitation_sum_mm': 'total precipitation, mm',
    '<variable>_lag<k>': 'value of <variable> k periods earlier',
  };
}
