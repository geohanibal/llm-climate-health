/// Loads the bundled world-country boundary asset once and caches it in
/// memory for the lifetime of the app.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/country_shape.dart';

class WorldMapLoader {
  static List<CountryShape>? _cache;

  const WorldMapLoader();

  Future<List<CountryShape>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/world_countries.json');
    final decoded = jsonDecode(raw) as List;
    final shapes = decoded
        .map((e) => CountryShape.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = shapes;
    return shapes;
  }
}
