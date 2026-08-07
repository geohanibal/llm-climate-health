/// Data model describing a selectable scientific data source.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

/// A climate or case-data source the backend can pull from, as advertised
/// by GET /api/options (id, human-readable label, and academic citation).
class DataSourceInfo {
  final String id;
  final String label;
  final String citation;

  const DataSourceInfo({
    required this.id,
    required this.label,
    required this.citation,
  });

  factory DataSourceInfo.fromEntry(String id, Map<String, dynamic> json) {
    return DataSourceInfo(
      id: id,
      label: json['label'] as String,
      citation: json['citation'] as String,
    );
  }
}
