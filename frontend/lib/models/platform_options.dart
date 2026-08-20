/// Data model for the backend's /api/options response.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'data_source_info.dart';
import 'disease_info.dart';
import 'region_info.dart';

/// Everything the request form needs to populate its dropdowns, fetched
/// once at startup so the frontend never hardcodes the disease/region/
/// source list.
class PlatformOptions {
  final Map<String, DiseaseInfo> diseases;
  final Map<String, RegionInfo> regions;
  final List<String> variables;
  final List<String> aggregations;
  final List<DataSourceInfo> climateSources;

  /// climate source id -> region names it's restricted to. A source with
  /// no entry here is available for every region (e.g. Open-Meteo, NASA
  /// POWER); "tmd" maps to just `{"Thailand"}`.
  final Map<String, List<String>> climateSourceRegions;

  final List<DataSourceInfo> caseDataSources;

  const PlatformOptions({
    required this.diseases,
    required this.regions,
    required this.variables,
    required this.aggregations,
    required this.climateSources,
    required this.climateSourceRegions,
    required this.caseDataSources,
  });

  factory PlatformOptions.fromJson(Map<String, dynamic> json) {
    final diseasesJson = json['diseases'] as Map<String, dynamic>;
    final regionsJson = json['regions'] as Map<String, dynamic>;
    final climateSourcesJson = json['climate_sources'] as Map<String, dynamic>;
    final climateSourceRegionsJson =
        json['climate_source_regions'] as Map<String, dynamic>? ?? const {};
    final caseDataSourcesJson = json['case_data_sources'] as Map<String, dynamic>;

    return PlatformOptions(
      diseases: diseasesJson.map(
        (k, v) => MapEntry(k, DiseaseInfo.fromEntry(k, v as Map<String, dynamic>)),
      ),
      regions: regionsJson.map(
        (k, v) => MapEntry(k, RegionInfo.fromJson(v as Map<String, dynamic>)),
      ),
      variables: (json['variables'] as List).cast<String>(),
      aggregations: (json['aggregations'] as List).cast<String>(),
      climateSources: climateSourcesJson.entries
          .map((e) => DataSourceInfo.fromEntry(e.key, e.value as Map<String, dynamic>))
          .toList(),
      climateSourceRegions: climateSourceRegionsJson.map(
        (k, v) => MapEntry(k, (v as List).cast<String>()),
      ),
      caseDataSources: caseDataSourcesJson.entries
          .map((e) => DataSourceInfo.fromEntry(e.key, e.value as Map<String, dynamic>))
          .toList(),
    );
  }
}
