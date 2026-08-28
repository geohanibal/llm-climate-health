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
  });

  factory IntegrationResult.fromJson(Map<String, dynamic> json) {
    final requestEcho = json['request_echo'] as Map<String, dynamic>? ?? const {};
    final auditJson = json['transformation_audit'] as Map<String, dynamic>?;
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
    );
  }
}
