/// Data model for the backend's /api/integrate response.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'period_record.dart';

/// Transparent audit trail of automated transformations performed on
/// custom or external case datasets.
class DataTransformationAudit {
  final List<String> originalColumns;
  final String? selectedDateColumn;
  final String? selectedValueColumn;
  final int totalRowsReceived;
  final int validRowsRetained;
  final int droppedRowsCount;
  final List<String> transformationsApplied;
  final String humanExplanation;

  const DataTransformationAudit({
    this.originalColumns = const [],
    this.selectedDateColumn,
    this.selectedValueColumn,
    this.totalRowsReceived = 0,
    this.validRowsRetained = 0,
    this.droppedRowsCount = 0,
    this.transformationsApplied = const [],
    this.humanExplanation = '',
  });

  factory DataTransformationAudit.fromJson(Map<String, dynamic> json) {
    return DataTransformationAudit(
      originalColumns: (json['original_columns'] as List?)?.cast<String>() ?? const [],
      selectedDateColumn: json['selected_date_column'] as String?,
      selectedValueColumn: json['selected_value_column'] as String?,
      totalRowsReceived: json['total_rows_received'] as int? ?? 0,
      validRowsRetained: json['valid_rows_retained'] as int? ?? 0,
      droppedRowsCount: json['dropped_rows_count'] as int? ?? 0,
      transformationsApplied:
          (json['transformations_applied'] as List?)?.cast<String>() ?? const [],
      humanExplanation: json['human_explanation'] as String? ?? '',
    );
  }
}

/// Statistical correlation and time-lag associations.
class CorrelationMetric {
  final String variable;
  final int lagPeriods;
  final double? pearsonR;
  final double? pearsonP;
  final double? spearmanRho;
  final double? spearmanP;
  final bool significant;
  final int sampleSize;

  const CorrelationMetric({
    required this.variable,
    required this.lagPeriods,
    this.pearsonR,
    this.pearsonP,
    this.spearmanRho,
    this.spearmanP,
    this.significant = false,
    this.sampleSize = 0,
  });

  factory CorrelationMetric.fromJson(Map<String, dynamic> json) {
    return CorrelationMetric(
      variable: json['variable'] as String? ?? '',
      lagPeriods: json['lag_periods'] as int? ?? 0,
      pearsonR: (json['pearson_r'] as num?)?.toDouble(),
      pearsonP: (json['pearson_p'] as num?)?.toDouble(),
      spearmanRho: (json['spearman_rho'] as num?)?.toDouble(),
      spearmanP: (json['spearman_p'] as num?)?.toDouble(),
      significant: json['significant'] as bool? ?? false,
      sampleSize: json['sample_size'] as int? ?? 0,
    );
  }
}

/// Epidemiological statistics across the joined dataset.
class StatisticalSummary {
  final int sampleSize;
  final List<CorrelationMetric> correlations;
  final String? peakPeriod;
  final double? peakCases;
  final double? peakIncidencePer100k;
  final double? meanTemperatureC;
  final double? meanPrecipitationMm;
  final double? totalCases;
  final String scientificDisclaimer;

  const StatisticalSummary({
    required this.sampleSize,
    this.correlations = const [],
    this.peakPeriod,
    this.peakCases,
    this.peakIncidencePer100k,
    this.meanTemperatureC,
    this.meanPrecipitationMm,
    this.totalCases,
    this.scientificDisclaimer = '',
  });

  factory StatisticalSummary.fromJson(Map<String, dynamic> json) {
    return StatisticalSummary(
      sampleSize: json['sample_size'] as int? ?? 0,
      correlations: (json['correlations'] as List?)
              ?.map((e) => CorrelationMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      peakPeriod: json['peak_period'] as String?,
      peakCases: (json['peak_cases'] as num?)?.toDouble(),
      peakIncidencePer100k: (json['peak_incidence_per_100k'] as num?)?.toDouble(),
      meanTemperatureC: (json['mean_temperature_c'] as num?)?.toDouble(),
      meanPrecipitationMm: (json['mean_precipitation_mm'] as num?)?.toDouble(),
      totalCases: (json['total_cases'] as num?)?.toDouble(),
      scientificDisclaimer: json['scientific_disclaimer'] as String? ?? '',
    );
  }
}

/// Temporal gap range within a single data column.
class MissingRange {
  final String start;
  final String end;

  const MissingRange({required this.start, required this.end});

  factory MissingRange.fromJson(Map<String, dynamic> json) {
    return MissingRange(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
      };
}

/// Completeness and temporal gap metrics for an integrated column (FR-26).
class DataCoverage {
  final String column;
  final int totalPeriods;
  final int periodsWithValue;
  final int missingCount;
  final double missingPercent;
  final List<MissingRange> missingRanges;
  final String? firstAvailable;
  final String? lastAvailable;
  final String? reason;
  final Map<String, String>? availableRange;

  const DataCoverage({
    required this.column,
    required this.totalPeriods,
    required this.periodsWithValue,
    required this.missingCount,
    required this.missingPercent,
    this.missingRanges = const [],
    this.firstAvailable,
    this.lastAvailable,
    this.reason,
    this.availableRange,
  });

  factory DataCoverage.fromJson(Map<String, dynamic> json) {
    final rangesJson = json['missing_ranges'] as List?;
    final availJson = json['available_range'] as Map<String, dynamic>?;
    return DataCoverage(
      column: json['column'] as String? ?? '',
      totalPeriods: (json['total_periods'] as num?)?.toInt() ?? 0,
      periodsWithValue: (json['periods_with_value'] as num?)?.toInt() ?? 0,
      missingCount: (json['missing_count'] as num?)?.toInt() ?? 0,
      missingPercent: (json['missing_percent'] as num?)?.toDouble() ?? 0.0,
      missingRanges: rangesJson
              ?.map((e) => MissingRange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      firstAvailable: json['first_available'] as String?,
      lastAvailable: json['last_available'] as String?,
      reason: json['reason'] as String?,
      availableRange: availJson?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'column': column,
        'total_periods': totalPeriods,
        'periods_with_value': periodsWithValue,
        'missing_count': missingCount,
        'missing_percent': missingPercent,
        'missing_ranges': missingRanges.map((e) => e.toJson()).toList(),
        if (firstAvailable != null) 'first_available': firstAvailable,
        if (lastAvailable != null) 'last_available': lastAvailable,
        if (reason != null) 'reason': reason,
        if (availableRange != null) 'available_range': availableRange,
      };
}

/// The full result of one ETL integration run: the plain-language
/// explanation, the step-by-step pipeline trace, the joined dataset (at
/// whatever [resolution] was resolved), the cited scientific sources, and
/// freshness metadata.
class IntegrationResult {
  final String disease;
  final String region;
  final String resolution;
  final List<String> steps;
  final String explanation;
  final String explanationSource;
  final List<PeriodRecord> data;
  final List<String> sources;

  /// Licence / terms of use of each source, same order as [sources] (FR-25).
  final List<String> licenses;

  /// Backend software version that produced the data (FR-25).
  final String systemVersion;

  /// Request parameters as echoed by the backend; exported with the data so
  /// the dataset can be re-created with the same settings.
  final Map<String, dynamic> requestEcho;
  final bool cached;
  final String lastVerified;
  final DataTransformationAudit? transformationAudit;
  final StatisticalSummary? statisticalSummary;
  final List<DataCoverage> dataCoverage;

  const IntegrationResult({
    required this.disease,
    required this.region,
    required this.resolution,
    required this.steps,
    required this.explanation,
    required this.explanationSource,
    required this.data,
    required this.sources,
    this.licenses = const [],
    this.systemVersion = 'unknown',
    this.requestEcho = const {},
    required this.cached,
    required this.lastVerified,
    this.transformationAudit,
    this.statisticalSummary,
    this.dataCoverage = const [],
  });

  factory IntegrationResult.fromJson(Map<String, dynamic> json) {
    final requestEcho = json['request_echo'] as Map<String, dynamic>? ?? const {};
    final auditJson = json['transformation_audit'] as Map<String, dynamic>?;
    final statsJson = json['statistical_summary'] as Map<String, dynamic>?;
    final covJson = json['data_coverage'] as List?;
    return IntegrationResult(
      disease: requestEcho['disease'] as String? ?? '',
      region: requestEcho['region'] as String? ?? '',
      resolution: json['resolution'] as String? ?? 'month',
      steps: (json['steps'] as List).cast<String>(),
      explanation: json['explanation'] as String,
      explanationSource: json['explanation_source'] as String? ?? 'fallback',
      data: (json['data'] as List)
          .map((e) => PeriodRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      sources: (json['sources'] as List).cast<String>(),
      // Defaults keep older cached responses (without these fields) readable.
      licenses: (json['licenses'] as List?)?.cast<String>() ?? const [],
      systemVersion: json['system_version'] as String? ?? 'unknown',
      requestEcho: requestEcho,
      cached: json['cached'] as bool? ?? false,
      lastVerified: json['last_verified'] as String? ?? '',
      transformationAudit: auditJson != null ? DataTransformationAudit.fromJson(auditJson) : null,
      statisticalSummary: statsJson != null ? StatisticalSummary.fromJson(statsJson) : null,
      dataCoverage: covJson
              ?.map((e) => DataCoverage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
