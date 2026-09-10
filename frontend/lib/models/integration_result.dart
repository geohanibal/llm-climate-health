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
  final bool cached;
  final String lastVerified;
  final DataTransformationAudit? transformationAudit;
  final StatisticalSummary? statisticalSummary;

  const IntegrationResult({
    required this.disease,
    required this.region,
    required this.resolution,
    required this.steps,
    required this.explanation,
    required this.explanationSource,
    required this.data,
    required this.sources,
    required this.cached,
    required this.lastVerified,
    this.transformationAudit,
    this.statisticalSummary,
  });

  factory IntegrationResult.fromJson(Map<String, dynamic> json) {
    final requestEcho = json['request_echo'] as Map<String, dynamic>? ?? const {};
    final auditJson = json['transformation_audit'] as Map<String, dynamic>?;
    final statsJson = json['statistical_summary'] as Map<String, dynamic>?;
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
      cached: json['cached'] as bool? ?? false,
      lastVerified: json['last_verified'] as String? ?? '',
      transformationAudit: auditJson != null ? DataTransformationAudit.fromJson(auditJson) : null,
      statisticalSummary: statsJson != null ? StatisticalSummary.fromJson(statsJson) : null,
    );
  }
}
