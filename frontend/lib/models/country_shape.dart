/// Data model for one country's boundary polygons, as bundled in
/// `assets/world_countries.json` (a simplified Natural Earth outline).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:ui';

class CountryShape {
  final String iso3;
  final String name;

  /// One or more closed rings (multi-part countries like archipelagos have
  /// several), each a list of (longitude, latitude) points.
  final List<List<Offset>> polygons;

  const CountryShape({
    required this.iso3,
    required this.name,
    required this.polygons,
  });

  factory CountryShape.fromJson(Map<String, dynamic> json) {
    final rawPolygons = json['polygons'] as List;
    return CountryShape(
      iso3: json['id'] as String,
      name: json['name'] as String,
      polygons: rawPolygons
          .map(
            (ring) => (ring as List)
                .map((point) => Offset((point[0] as num).toDouble(), (point[1] as num).toDouble()))
                .toList(),
          )
          .toList(),
    );
  }
}
