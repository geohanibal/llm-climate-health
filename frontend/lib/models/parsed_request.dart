/// Data model for the backend's /api/parse-request response: a best-effort
/// extraction of a request from free text, used only to prefill the form.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

/// Every field is nullable — the backend leaves a field unset rather than
/// guessing when the user's text didn't pin it down. [notes] explains any
/// assumptions or gaps so the user can review before running anything.
class ParsedRequest {
  final String? disease;
  final String? region;
  final List<String>? variables;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? aggregation;
  final String? climateSource;
  final String notes;

  const ParsedRequest({
    this.disease,
    this.region,
    this.variables,
    this.startDate,
    this.endDate,
    this.aggregation,
    this.climateSource,
    required this.notes,
  });

  factory ParsedRequest.fromJson(Map<String, dynamic> json) {
    return ParsedRequest(
      disease: json['disease'] as String?,
      region: json['region'] as String?,
      variables: (json['variables'] as List?)?.cast<String>(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      aggregation: json['aggregation'] as String?,
      climateSource: json['climate_source'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
