/// Data model for a selectable region: display label plus the reference
/// coordinate the backend's ETL pipeline actually fetches climate data for
/// (used to place the region's marker dot on the 2D world map).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

class RegionInfo {
  final String label;
  final double lat;
  final double lon;

  const RegionInfo({required this.label, required this.lat, required this.lon});

  factory RegionInfo.fromJson(Map<String, dynamic> json) {
    return RegionInfo(
      label: json['label'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}
