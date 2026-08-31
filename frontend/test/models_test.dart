/// Pure fromJson tests for the API response models — no network, no widget
/// pumping, just checking the backend's JSON shape decodes correctly.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/discovered_source.dart';
import 'package:climate_health_frontend/models/disease_info.dart';
import 'package:climate_health_frontend/models/integration_result.dart';
import 'package:climate_health_frontend/models/parsed_request.dart';
import 'package:climate_health_frontend/models/platform_options.dart';

void main() {
  group('DiseaseInfo.fromEntry', () {
    test('decodes a populated region_coverage map', () {
      final disease = DiseaseInfo.fromEntry('dengue', {
        'label': 'Dengue',
        'native_resolution': 'month',
        'regions': ['Thailand', 'Italy'],
        'region_coverage': {
          'Thailand': ['1990-01', '2023-12'],
          'Italy': ['2024-01', '2025-03'],
        },
      });

      expect(disease.regionCoverage['Thailand'], ['1990-01', '2023-12']);
      expect(disease.regionCoverage['Italy'], ['2024-01', '2025-03']);
    });

    test('defaults regionCoverage to an empty map when the key is missing', () {
      final disease = DiseaseInfo.fromEntry('malaria', {
        'label': 'Malaria',
        'native_resolution': 'year',
        'regions': ['Kenya'],
      });

      expect(disease.regionCoverage, isEmpty);
    });

    test('decodes a malformed (non-2-element) coverage span without throwing', () {
      // DiseaseInfo itself doesn't validate span length — RequestFormCard is
      // responsible for guarding against a short list before indexing it
      // (see request_form_card_test.dart's regression test for that guard).
      final disease = DiseaseInfo.fromEntry('dengue', {
        'label': 'Dengue',
        'native_resolution': 'month',
        'regions': ['Thailand'],
        'region_coverage': {
          'Thailand': ['2020-01'],
        },
      });

      expect(disease.regionCoverage['Thailand'], ['2020-01']);
    });
  });

  group('IntegrationResult.fromJson', () {
    test('decodes a full backend response', () {
      final result = IntegrationResult.fromJson({
        'request_echo': {'disease': 'dengue', 'region': 'Thailand'},
        'resolution': 'month',
        'steps': ['step one', 'step two'],
        'explanation': 'This dataset combines...',
        'explanation_source': 'llm',
        'data': [
          {
            'period': '2020-01',
            'case_count': 12.0,
            'population': 71641484.0,
            'incidence_rate_per_100k': 0.017,
            'temperature_mean_c': 26.5,
            'precipitation_sum_mm': 100.0,
          },
        ],
        'sources': ['source A', 'source B'],
        'cached': true,
        'last_verified': '2024-01-01T00:00:00Z',
      });

      expect(result.disease, 'dengue');
      expect(result.region, 'Thailand');
      expect(result.resolution, 'month');
      expect(result.steps, ['step one', 'step two']);
      expect(result.explanationSource, 'llm');
      expect(result.data, hasLength(1));
      expect(result.data.first.caseCount, 12.0);
      expect(result.data.first.population, 71641484.0);
      expect(result.data.first.incidenceRatePer100k, 0.017);
      expect(result.cached, true);
    });

    test('defaults explanationSource to fallback when the key is missing', () {
      final result = IntegrationResult.fromJson({
        'request_echo': {'disease': 'dengue', 'region': 'Thailand'},
        'resolution': 'month',
        'steps': <String>[],
        'explanation': 'generic text',
        'data': <Map<String, dynamic>>[],
        'sources': <String>[],
        'last_verified': '2024-01-01T00:00:00Z',
      });

      expect(result.explanationSource, 'fallback');
      expect(result.transformationAudit, isNull);
    });

    test('decodes transformation_audit when present in response', () {
      final result = IntegrationResult.fromJson({
        'request_echo': {'disease': 'dengue', 'region': 'Thailand'},
        'resolution': 'month',
        'steps': <String>[],
        'explanation': 'Audit test explanation',
        'data': <Map<String, dynamic>>[],
        'sources': <String>[],
        'last_verified': '2024-01-01T00:00:00Z',
        'transformation_audit': {
          'original_columns': ['period', 'malaria_cases'],
          'selected_date_column': 'period',
          'selected_value_column': 'malaria_cases',
          'total_rows_received': 10,
          'valid_rows_retained': 10,
          'dropped_rows_count': 0,
          'transformations_applied': ['Mapped period to date'],
          'human_explanation': 'AI audit summary.',
        },
      });

      expect(result.transformationAudit, isNotNull);
      expect(result.transformationAudit!.selectedDateColumn, 'period');
      expect(result.transformationAudit!.selectedValueColumn, 'malaria_cases');
      expect(result.transformationAudit!.totalRowsReceived, 10);
      expect(result.transformationAudit!.humanExplanation, 'AI audit summary.');
    });
  });


  group('PlatformOptions.fromJson', () {
    test('decodes diseases, regions, and data sources', () {
      final options = PlatformOptions.fromJson({
        'diseases': {
          'dengue': {
            'label': 'Dengue',
            'native_resolution': 'month',
            'regions': ['Thailand'],
          },
        },
        'regions': {
          'Thailand': {'label': 'Thailand', 'lat': 15.87, 'lon': 100.99},
        },
        'variables': ['temperature', 'precipitation'],
        'scenarios': ['historical'],
        'aggregations': ['native', 'yearly', 'decadal'],
        'climate_sources': {
          'open-meteo-era5': {'label': 'Open-Meteo', 'citation': 'cite A'},
          'tmd': {'label': 'TMD', 'citation': 'cite C'},
        },
        'climate_source_regions': {
          'tmd': ['Thailand'],
        },
        'case_data_sources': {
          'builtin': {'label': 'Built-in', 'citation': 'cite B'},
        },
      });

      expect(options.diseases['dengue']!.label, 'Dengue');
      expect(options.diseases['dengue']!.regions, ['Thailand']);
      expect(options.regions['Thailand']!.label, 'Thailand');
      expect(options.regions['Thailand']!.lat, 15.87);
      expect(options.climateSources.map((s) => s.id), contains('open-meteo-era5'));
      expect(options.climateSourceRegions['tmd'], ['Thailand']);
      expect(options.caseDataSources.single.id, 'builtin');
    });
  });

  group('DiscoveredSource.fromJson', () {
    test('decodes a WHO GHO result', () {
      final source = DiscoveredSource.fromJson({
        'source_type': 'who_gho',
        'title': 'Estimated number of malaria cases',
        'organization': 'World Health Organization (WHO)',
        'description': 'Official WHO indicator.',
        'citation': 'WHO GHO, indicator MALARIA_EST_CASES',
        'dataset_url': 'https://www.who.int/data/gho/data/indicators/indicator-details/GHO/malaria_est_cases',
        'resource_url': null,
        'indicator_code': 'MALARIA_EST_CASES',
      });

      expect(source.isWhoGho, true);
      expect(source.indicatorCode, 'MALARIA_EST_CASES');
      expect(source.resourceUrl, isNull);
    });

    test('decodes an HDX result', () {
      final source = DiscoveredSource.fromJson({
        'source_type': 'hdx',
        'title': 'Philippine Dengue Cases and Deaths',
        'organization': 'Cirrolytix',
        'description': 'Confirmed dengue cases and deaths.',
        'citation': 'Cirrolytix, "Philippine Dengue Cases and Deaths" via HDX',
        'dataset_url': 'https://data.humdata.org/dataset/philippine-dengue-cases-and-deaths',
        'resource_url': 'https://data.humdata.org/.../doh-epi-dengue-data.csv',
        'indicator_code': null,
      });

      expect(source.isWhoGho, false);
      expect(source.resourceUrl, isNotNull);
      expect(source.indicatorCode, isNull);
    });
  });

  group('ParsedRequest.fromJson', () {
    test('decodes a fully-populated parse result', () {
      final parsed = ParsedRequest.fromJson({
        'disease': 'dengue',
        'region': 'Thailand',
        'variables': ['temperature', 'precipitation'],
        'start_date': '2015-01-01',
        'end_date': '2023-12-01',
        'aggregation': 'yearly',
        'climate_source': 'nasa-power',
        'notes': 'Assumed yearly granularity.',
      });

      expect(parsed.disease, 'dengue');
      expect(parsed.region, 'Thailand');
      expect(parsed.variables, ['temperature', 'precipitation']);
      expect(parsed.startDate, DateTime(2015, 1, 1));
      expect(parsed.endDate, DateTime(2023, 12, 1));
      expect(parsed.aggregation, 'yearly');
      expect(parsed.climateSource, 'nasa-power');
      expect(parsed.notes, 'Assumed yearly granularity.');
    });

    test('leaves fields null when the backend could not determine them', () {
      final parsed = ParsedRequest.fromJson({
        'notes': 'Could not determine a region from the text.',
      });

      expect(parsed.disease, isNull);
      expect(parsed.region, isNull);
      expect(parsed.variables, isNull);
      expect(parsed.startDate, isNull);
      expect(parsed.notes, 'Could not determine a region from the text.');
    });
  });
}
