/// Data model for the backend's /api/integrate response.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'period_record.dart';

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
  final List<PeriodRecord> data;
  final List<String> sources;
  final bool cached;
  final String lastVerified;

  const IntegrationResult({
    required this.disease,
    required this.region,
    required this.resolution,
    required this.steps,
    required this.explanation,
    required this.data,
    required this.sources,
    required this.cached,
    required this.lastVerified,
  });

  factory IntegrationResult.fromJson(Map<String, dynamic> json) {
    final requestEcho = json['request_echo'] as Map<String, dynamic>? ?? const {};
    return IntegrationResult(
      disease: requestEcho['disease'] as String? ?? '',
      region: requestEcho['region'] as String? ?? '',
      resolution: json['resolution'] as String? ?? 'month',
      steps: (json['steps'] as List).cast<String>(),
      explanation: json['explanation'] as String,
      data: (json['data'] as List)
          .map((e) => PeriodRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      sources: (json['sources'] as List).cast<String>(),
      cached: json['cached'] as bool? ?? false,
      lastVerified: json['last_verified'] as String? ?? '',
    );
  }
}
