/// Models for the Climate-Health Copilot chat assistant.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'integration_result.dart';
import 'parsed_request.dart';

class FormPrefillAction {
  final String? disease;
  final String? region;
  final List<String>? variables;
  final String? startDate;
  final String? endDate;
  final String? aggregation;
  final String? climateSource;

  const FormPrefillAction({
    this.disease,
    this.region,
    this.variables,
    this.startDate,
    this.endDate,
    this.aggregation,
    this.climateSource,
  });

  factory FormPrefillAction.fromJson(Map<String, dynamic> json) {
    return FormPrefillAction(
      disease: json['disease'] as String?,
      region: json['region'] as String?,
      variables: (json['variables'] as List?)?.cast<String>(),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      aggregation: json['aggregation'] as String?,
      climateSource: json['climate_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (disease != null) 'disease': disease,
        if (region != null) 'region': region,
        if (variables != null) 'variables': variables,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (aggregation != null) 'aggregation': aggregation,
        if (climateSource != null) 'climate_source': climateSource,
      };

  ParsedRequest toParsedRequest() {
    return ParsedRequest(
      disease: disease,
      region: region,
      variables: variables,
      startDate: startDate != null ? DateTime.tryParse(startDate!) : null,
      endDate: endDate != null ? DateTime.tryParse(endDate!) : null,
      aggregation: aggregation,
      climateSource: climateSource,
      notes: 'Suggested by Climate-Health Copilot',
    );
  }
}

class ActiveResultSummary {
  final String? disease;
  final String? region;
  final String? resolution;
  final int? sampleSize;
  final double? totalCases;
  final String? peakPeriod;
  final double? peakCases;
  final double? peakIncidencePer100k;
  final double? meanTemperatureC;
  final double? meanPrecipitationMm;
  final List<String>? correlationsSummary;
  final String? explanation;

  const ActiveResultSummary({
    this.disease,
    this.region,
    this.resolution,
    this.sampleSize,
    this.totalCases,
    this.peakPeriod,
    this.peakCases,
    this.peakIncidencePer100k,
    this.meanTemperatureC,
    this.meanPrecipitationMm,
    this.correlationsSummary,
    this.explanation,
  });

  factory ActiveResultSummary.fromIntegrationResult(IntegrationResult result) {
    final stats = result.statisticalSummary;

    List<String>? corrLines;
    if (stats != null && stats.correlations.isNotEmpty) {
      corrLines = stats.correlations.map((c) {
        final sig = c.significant ? ' (significant p<0.05)' : '';
        return '${c.variable} Lag ${c.lagPeriods}: r=${c.pearsonR?.toStringAsFixed(2)}$sig';
      }).toList();
    }

    return ActiveResultSummary(
      disease: result.disease,
      region: result.region,
      resolution: result.resolution,
      sampleSize: stats?.sampleSize ?? result.data.length,
      totalCases: stats?.totalCases,
      peakPeriod: stats?.peakPeriod,
      peakCases: stats?.peakCases,
      peakIncidencePer100k: stats?.peakIncidencePer100k,
      meanTemperatureC: stats?.meanTemperatureC,
      meanPrecipitationMm: stats?.meanPrecipitationMm,
      correlationsSummary: corrLines,
      explanation: result.explanation,
    );
  }

  Map<String, dynamic> toJson() => {
        if (disease != null) 'disease': disease,
        if (region != null) 'region': region,
        if (resolution != null) 'resolution': resolution,
        if (sampleSize != null) 'sample_size': sampleSize,
        if (totalCases != null) 'total_cases': totalCases,
        if (peakPeriod != null) 'peak_period': peakPeriod,
        if (peakCases != null) 'peak_cases': peakCases,
        if (peakIncidencePer100k != null) 'peak_incidence_per_100k': peakIncidencePer100k,
        if (meanTemperatureC != null) 'mean_temperature_c': meanTemperatureC,
        if (meanPrecipitationMm != null) 'mean_precipitation_mm': meanPrecipitationMm,
        if (correlationsSummary != null) 'correlations_summary': correlationsSummary,
        if (explanation != null) 'explanation': explanation,
      };
}

class ChatContext {
  final String? currentDisease;
  final String? currentRegion;
  final String? currentStartDate;
  final String? currentEndDate;
  final ActiveResultSummary? activeResult;

  const ChatContext({
    this.currentDisease,
    this.currentRegion,
    this.currentStartDate,
    this.currentEndDate,
    this.activeResult,
  });

  Map<String, dynamic> toJson() => {
        if (currentDisease != null) 'current_disease': currentDisease,
        if (currentRegion != null) 'current_region': currentRegion,
        if (currentStartDate != null) 'current_start_date': currentStartDate,
        if (currentEndDate != null) 'current_end_date': currentEndDate,
        if (activeResult != null) 'active_result': activeResult!.toJson(),
      };
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final FormPrefillAction? suggestedAction;
  final List<String> suggestedPrompts;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.suggestedAction,
    this.suggestedPrompts = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      suggestedAction: json['suggested_action'] != null
          ? FormPrefillAction.fromJson(json['suggested_action'] as Map<String, dynamic>)
          : null,
      suggestedPrompts: (json['suggested_prompts'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatResponse {
  final String reply;
  final FormPrefillAction? suggestedAction;
  final List<String> suggestedPrompts;

  const ChatResponse({
    required this.reply,
    this.suggestedAction,
    this.suggestedPrompts = const [],
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String? ?? '',
      suggestedAction: json['suggested_action'] != null
          ? FormPrefillAction.fromJson(json['suggested_action'] as Map<String, dynamic>)
          : null,
      suggestedPrompts: (json['suggested_prompts'] as List?)?.cast<String>() ?? const [],
    );
  }
}
