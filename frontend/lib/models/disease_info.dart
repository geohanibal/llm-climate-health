/// Data model describing a selectable disease and which regions it has
/// built-in case-count data for.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

class DiseaseInfo {
  final String key;
  final String label;
  final String nativeResolution;
  final List<String> regions;

  /// Region name -> [earliest, latest] period actually present in the
  /// builtin file, e.g. "2024-01".."2025-03" for Italy's dengue data. A
  /// region can be in [regions] (has *some* data) while only covering a
  /// narrow recent window, so a query outside this range will run but
  /// return no real case counts — used to warn before that happens.
  final Map<String, List<String>> regionCoverage;

  const DiseaseInfo({
    required this.key,
    required this.label,
    required this.nativeResolution,
    required this.regions,
    required this.regionCoverage,
  });

  factory DiseaseInfo.fromEntry(String key, Map<String, dynamic> json) {
    final coverageJson = json['region_coverage'] as Map<String, dynamic>? ?? const {};
    return DiseaseInfo(
      key: key,
      label: json['label'] as String,
      nativeResolution: json['native_resolution'] as String,
      regions: (json['regions'] as List).cast<String>(),
      regionCoverage: coverageJson.map((k, v) => MapEntry(k, (v as List).cast<String>())),
    );
  }
}
