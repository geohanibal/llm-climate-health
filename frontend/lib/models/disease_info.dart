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

  const DiseaseInfo({
    required this.key,
    required this.label,
    required this.nativeResolution,
    required this.regions,
  });

  factory DiseaseInfo.fromEntry(String key, Map<String, dynamic> json) {
    return DiseaseInfo(
      key: key,
      label: json['label'] as String,
      nativeResolution: json['native_resolution'] as String,
      regions: (json['regions'] as List).cast<String>(),
    );
  }
}
