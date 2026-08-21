/// Unit tests for ApiClient. ApiClient calls the top-level http.get/post
/// functions and MultipartRequest.send() rather than taking an injected
/// Client, so these run every call inside a `http.runWithClient` zone with
/// a MockClient standing in for the network.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:climate_health_frontend/models/integration_request_params.dart';
import 'package:climate_health_frontend/services/api_client.dart';

const _fullOptionsJson = {
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
  'variables': ['temperature'],
  'scenarios': ['historical'],
  'aggregations': ['native'],
  'climate_sources': {
    'open-meteo-era5': {'label': 'Open-Meteo', 'citation': 'c'},
  },
  'climate_source_regions': {},
  'case_data_sources': {
    'builtin': {'label': 'Built-in', 'citation': 'c'},
  },
};

Map<String, dynamic> _integrationResponseJson() => {
      'request_echo': {'disease': 'dengue', 'region': 'Thailand'},
      'resolution': 'month',
      'steps': ['step one'],
      'explanation': 'A summary.',
      'explanation_source': 'fallback',
      'data': [
        {'period': '2020-01', 'case_count': 5.0, 'temperature_mean_c': 26.0, 'precipitation_sum_mm': 10.0},
      ],
      'sources': ['source A', 'source B'],
      'cached': false,
      'last_verified': '2024-01-01T00:00:00Z',
    };

IntegrationRequestParams _params({String caseDataSource = 'builtin', Uint8List? uploadedFileBytes}) {
  return IntegrationRequestParams(
    disease: 'dengue',
    region: 'Thailand',
    variables: const ['temperature'],
    startDate: DateTime(2020, 1, 1),
    endDate: DateTime(2020, 3, 1),
    aggregation: 'native',
    climateSource: 'open-meteo-era5',
    caseDataSource: caseDataSource,
    uploadedFileBytes: uploadedFileBytes,
    uploadedFileName: uploadedFileBytes != null ? 'cases.csv' : null,
  );
}

void main() {
  const client = ApiClient();

  test('fetchOptions decodes a successful response', () async {
    await http.runWithClient(() async {
      final options = await client.fetchOptions();
      expect(options.diseases.containsKey('dengue'), isTrue);
      expect(options.regions['Thailand']!.lat, 15.87);
    }, () => MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/options');
          return http.Response(jsonEncode(_fullOptionsJson), 200);
        }));
  });

  test('parseRequest throws ApiException carrying the backend detail message on failure', () async {
    await http.runWithClient(() async {
      try {
        await client.parseRequest('dengue in Thailand');
        fail('expected an ApiException');
      } on ApiException catch (e) {
        expect(e.message, contains('no LLM configured'));
      }
    }, () => MockClient((request) async {
          expect(request.url.path, '/api/parse-request');
          return http.Response(jsonEncode({'detail': 'no LLM configured'}), 503);
        }));
  });

  test('a non-JSON error body falls back to the raw response text', () async {
    await http.runWithClient(() async {
      try {
        await client.fetchOptions();
        fail('expected an ApiException');
      } on ApiException catch (e) {
        expect(e.message, contains('internal server error'));
      }
    }, () => MockClient((request) async {
          return http.Response('internal server error', 500);
        }));
  });

  test('searchCaseSources decodes a list of discovered sources', () async {
    await http.runWithClient(() async {
      final results = await client.searchCaseSources('malaria', 'Kenya');
      expect(results, hasLength(1));
      expect(results.first.sourceType, 'who_gho');
    }, () => MockClient((request) async {
          expect(request.url.path, '/api/search-case-sources');
          expect(request.url.queryParameters['disease'], 'malaria');
          expect(request.url.queryParameters['region'], 'Kenya');
          return http.Response(
            jsonEncode([
              {
                'source_type': 'who_gho',
                'title': 'Estimated malaria cases',
                'organization': 'WHO',
                'description': 'desc',
                'citation': 'cite',
                'dataset_url': 'https://who.int/x',
                'resource_url': null,
                'indicator_code': 'MALARIA_EST_CASES',
              },
            ]),
            200,
          );
        }));
  });

  test('runIntegration posts JSON to /api/integrate for non-upload sources', () async {
    await http.runWithClient(() async {
      final result = await client.runIntegration(_params());
      expect(result.disease, 'dengue');
      expect(result.data, hasLength(1));
    }, () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/integrate');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['disease'], 'dengue');
          expect(body['start_date'], '2020-01-01');
          return http.Response(jsonEncode(_integrationResponseJson()), 200);
        }));
  });

  test('runIntegration sends a multipart request to /api/integrate/upload for custom_upload', () async {
    await http.runWithClient(() async {
      final result = await client.runIntegration(
        _params(caseDataSource: 'custom_upload', uploadedFileBytes: Uint8List.fromList([1, 2, 3])),
      );
      expect(result.disease, 'dengue');
    }, () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/integrate/upload');
          expect(request.headers['content-type'], contains('multipart/form-data'));
          return http.Response(jsonEncode(_integrationResponseJson()), 200);
        }));
  });
}
