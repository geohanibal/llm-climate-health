/// Data models for source comparison (FR-27 / Task F / A19).
///
/// Compares two data sources (e.g. ERA5 vs NASA POWER for climate, builtin
/// vs custom_url for cases) over their temporal overlap, reporting Pearson r,
/// mean difference, and deterministic heuristic verdicts without modifying the
/// main integrated dataset.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

class SourceComparisonRequest {
  final String disease;
  final String region;
  final List<String> variables;
  final String startDate;
  final String endDate;
  final String aggregation;
  final String climateSource;
  final String caseDataSource;
  final String populationSource;
  final String? customSourceUrl;
  final String? whoIndicatorCode;
  final String? whoIndicatorName;
  final String? customPopulationUrl;
  final String? populationIndicatorCode;
  final String? populationIndicatorName;
  final String compareKind; // "climate" or "cases"
  final String? alternativeClimateSource;
  final String? alternativeCaseDataSource;
  final String? alternativeCustomSourceUrl;
  final String? alternativeWhoIndicatorCode;
  final String? alternativeWhoIndicatorName;

  SourceComparisonRequest({
    required this.disease,
    required this.region,
    this.variables = const ['temperature', 'precipitation'],
    required this.startDate,
    required this.endDate,
    this.aggregation = 'native',
    this.climateSource = 'open-meteo-era5',
    this.caseDataSource = 'builtin',
    this.populationSource = 'worldbank',
    this.customSourceUrl,
    this.whoIndicatorCode,
    this.whoIndicatorName,
    this.customPopulationUrl,
    this.populationIndicatorCode,
    this.populationIndicatorName,
    this.compareKind = 'climate',
    this.alternativeClimateSource,
    this.alternativeCaseDataSource,
    this.alternativeCustomSourceUrl,
    this.alternativeWhoIndicatorCode,
    this.alternativeWhoIndicatorName,
  });

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'region': region,
      'variables': variables,
      'start_date': startDate,
      'end_date': endDate,
      'aggregation': aggregation,
      'climate_source': climateSource,
      'case_data_source': caseDataSource,
      'population_source': populationSource,
      if (customSourceUrl != null) 'custom_source_url': customSourceUrl,
      if (whoIndicatorCode != null) 'who_indicator_code': whoIndicatorCode,
      if (whoIndicatorName != null) 'who_indicator_name': whoIndicatorName,
      if (customPopulationUrl != null) 'custom_population_url': customPopulationUrl,
      if (populationIndicatorCode != null) 'population_indicator_code': populationIndicatorCode,
      if (populationIndicatorName != null) 'population_indicator_name': populationIndicatorName,
      'compare_kind': compareKind,
      if (alternativeClimateSource != null) 'alternative_climate_source': alternativeClimateSource,
      if (alternativeCaseDataSource != null) 'alternative_case_data_source': alternativeCaseDataSource,
      if (alternativeCustomSourceUrl != null) 'alternative_custom_source_url': alternativeCustomSourceUrl,
      if (alternativeWhoIndicatorCode != null) 'alternative_who_indicator_code': alternativeWhoIndicatorCode,
      if (alternativeWhoIndicatorName != null) 'alternative_who_indicator_name': alternativeWhoIndicatorName,
    };
  }
}

class SeriesPoint {
  final String period;
  final double? value;

  SeriesPoint({
    required this.period,
    this.value,
  });

  factory SeriesPoint.fromJson(Map<String, dynamic> json) {
    return SeriesPoint(
      period: json['period'] as String,
      value: (json['value'] as num?)?.toDouble(),
    );
  }
}

class VariableComparison {
  final String variable;
  final int overlapPeriods;
  final double? pearsonR;
  final double? pValue;
  final String? formattedPValue;
  final double? meanDifference;
  final double? meanAbsoluteDifference;
  final double? relativeMeanAbsoluteDifferencePercent;
  final String verdict;
  final String verdictExplanation;
  final bool tooFewPoints;
  final List<SeriesPoint> seriesA;
  final List<SeriesPoint> seriesB;

  VariableComparison({
    required this.variable,
    required this.overlapPeriods,
    this.pearsonR,
    this.pValue,
    this.formattedPValue,
    this.meanDifference,
    this.meanAbsoluteDifference,
    this.relativeMeanAbsoluteDifferencePercent,
    required this.verdict,
    required this.verdictExplanation,
    this.tooFewPoints = false,
    this.seriesA = const [],
    this.seriesB = const [],
  });

  factory VariableComparison.fromJson(Map<String, dynamic> json) {
    return VariableComparison(
      variable: json['variable'] as String,
      overlapPeriods: json['overlap_periods'] as int,
      pearsonR: (json['pearson_r'] as num?)?.toDouble(),
      pValue: (json['p_value'] as num?)?.toDouble(),
      formattedPValue: json['formatted_p_value'] as String?,
      meanDifference: (json['mean_difference'] as num?)?.toDouble(),
      meanAbsoluteDifference: (json['mean_absolute_difference'] as num?)?.toDouble(),
      relativeMeanAbsoluteDifferencePercent:
          (json['relative_mean_absolute_difference_percent'] as num?)?.toDouble(),
      verdict: json['verdict'] as String,
      verdictExplanation: json['verdict_explanation'] as String,
      tooFewPoints: json['too_few_points'] as bool? ?? false,
      seriesA: (json['series_a'] as List<dynamic>?)
              ?.map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      seriesB: (json['series_b'] as List<dynamic>?)
              ?.map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class SourceComparisonResponse {
  final String compareKind;
  final String sourceALabel;
  final String sourceBLabel;
  final String resolution;
  final List<VariableComparison> variables;
  final String methodologyNote;
  final bool resolutionMismatch;
  final String? resolutionMismatchMessage;
  final bool comparedAtYearlyResolution;
  final List<String> excludedYears;

  SourceComparisonResponse({
    required this.compareKind,
    required this.sourceALabel,
    required this.sourceBLabel,
    required this.resolution,
    required this.variables,
    required this.methodologyNote,
    this.resolutionMismatch = false,
    this.resolutionMismatchMessage,
    this.comparedAtYearlyResolution = false,
    this.excludedYears = const [],
  });

  factory SourceComparisonResponse.fromJson(Map<String, dynamic> json) {
    return SourceComparisonResponse(
      compareKind: json['compare_kind'] as String,
      sourceALabel: json['source_a_label'] as String,
      sourceBLabel: json['source_b_label'] as String,
      resolution: json['resolution'] as String,
      variables: (json['variables'] as List<dynamic>?)
              ?.map((e) => VariableComparison.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      methodologyNote: json['methodology_note'] as String,
      resolutionMismatch: json['resolution_mismatch'] as bool? ?? false,
      resolutionMismatchMessage: json['resolution_mismatch_message'] as String?,
      comparedAtYearlyResolution: json['compared_at_yearly_resolution'] as bool? ?? false,
      excludedYears: (json['excluded_years'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

