/// Data model for one candidate case-data source returned by
/// `GET /api/search-case-sources` (either a WHO GHO indicator or an HDX
/// dataset). Every field is real metadata echoed back from that source's
/// own API — never generated.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

class DiscoveredSource {
  final String sourceType; // "who_gho" | "hdx"
  final String title;
  final String organization;
  final String description;
  final String citation;
  final String datasetUrl;
  final String? resourceUrl; // HDX only: direct CSV/XLSX download link
  final String? indicatorCode; // WHO GHO only

  const DiscoveredSource({
    required this.sourceType,
    required this.title,
    required this.organization,
    required this.description,
    required this.citation,
    required this.datasetUrl,
    this.resourceUrl,
    this.indicatorCode,
  });

  bool get isWhoGho => sourceType == 'who_gho';

  factory DiscoveredSource.fromJson(Map<String, dynamic> json) {
    return DiscoveredSource(
      sourceType: json['source_type'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String,
      description: json['description'] as String,
      citation: json['citation'] as String,
      datasetUrl: json['dataset_url'] as String,
      resourceUrl: json['resource_url'] as String?,
      indicatorCode: json['indicator_code'] as String?,
    );
  }
}
