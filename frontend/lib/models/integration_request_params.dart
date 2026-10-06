/// Data model bundling everything the request form collects from the user.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:typed_data';

/// Immutable snapshot of the request form's state, passed from
/// [RequestFormCard] up to [HomePage] on submit and from there to
/// [ApiClient].
class IntegrationRequestParams {
  final String disease;
  final String region;
  final List<String> variables;
  final DateTime startDate;
  final DateTime endDate;
  final String aggregation;
  final String climateSource;
  final String caseDataSource;
  final String populationSource;
  final String? customSourceUrl;
  final Uint8List? uploadedFileBytes;
  final String? uploadedFileName;
  final Uint8List? climateUploadBytes;
  final String? climateUploadFileName;
  final String? whoIndicatorCode;
  final String? whoIndicatorName;
  final String? customPopulationUrl;
  final String? populationIndicatorCode;
  final String? populationIndicatorName;
  final Uint8List? populationUploadBytes;
  final String? populationUploadFileName;

  const IntegrationRequestParams({
    required this.disease,
    required this.region,
    required this.variables,
    required this.startDate,
    required this.endDate,
    required this.aggregation,
    required this.climateSource,
    required this.caseDataSource,
    this.populationSource = 'worldbank',
    this.customSourceUrl,
    this.uploadedFileBytes,
    this.uploadedFileName,
    this.climateUploadBytes,
    this.climateUploadFileName,
    this.whoIndicatorCode,
    this.whoIndicatorName,
    this.customPopulationUrl,
    this.populationIndicatorCode,
    this.populationIndicatorName,
    this.populationUploadBytes,
    this.populationUploadFileName,
  });
}
