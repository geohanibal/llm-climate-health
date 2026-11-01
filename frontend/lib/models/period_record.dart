/// Data model for a single aligned (period, case-count, climate) row. The
/// period's meaning depends on the response's resolution: a month
/// ("2020-07"), a year ("2020"), or a decade ("2020s").
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

class PeriodRecord {
  final String period;
  final double? caseCount;
  final double? population;
  final double? incidenceRatePer100k;
  final double? temperatureMeanC;
  final double? temperatureMinC;
  final double? temperatureMaxC;
  final double? precipitationSumMm;

  const PeriodRecord({
    required this.period,
    this.caseCount,
    this.population,
    this.incidenceRatePer100k,
    this.temperatureMeanC,
    this.temperatureMinC,
    this.temperatureMaxC,
    this.precipitationSumMm,
  });

  factory PeriodRecord.fromJson(Map<String, dynamic> json) {
    return PeriodRecord(
      period: json['period'] as String,
      caseCount: (json['case_count'] as num?)?.toDouble(),
      population: (json['population'] as num?)?.toDouble(),
      incidenceRatePer100k: (json['incidence_rate_per_100k'] as num?)?.toDouble(),
      temperatureMeanC: (json['temperature_mean_c'] as num?)?.toDouble(),
      temperatureMinC: (json['temperature_min_c'] as num?)?.toDouble(),
      temperatureMaxC: (json['temperature_max_c'] as num?)?.toDouble(),
      precipitationSumMm: (json['precipitation_sum_mm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'case_count': caseCount,
        'population': population,
        'incidence_rate_per_100k': incidenceRatePer100k,
        'temperature_mean_c': temperatureMeanC,
        'temperature_min_c': temperatureMinC,
        'temperature_max_c': temperatureMaxC,
        'precipitation_sum_mm': precipitationSumMm,
      };
}
