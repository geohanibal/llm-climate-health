/// HTTP client for the Climate-Health ETL backend.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/discovered_source.dart';
import '../models/integration_request_params.dart';
import '../models/integration_result.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';

/// Base URL of the FastAPI backend. Overridable at build time with
/// `--dart-define=BACKEND_URL=https://your-deployment` for production
/// builds, defaulting to the local dev server for day-to-day development.
const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// Thrown when the backend rejects a request or is unreachable, carrying a
/// message that is safe to show directly to the end user.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the backend's REST endpoints. Holds no state of its
/// own; every call is a fresh HTTP request.
class ApiClient {
  const ApiClient();

  Future<PlatformOptions> fetchOptions() async {
    final response = await http.get(Uri.parse('$backendBaseUrl/api/options'));
    _throwIfNotOk(response);
    return PlatformOptions.fromJson(_decodeJsonObject(response));
  }

  /// Sends the user's free-text description to the LLM-backed parser and
  /// returns a best-effort request plan for the form to prefill. Throws
  /// [ApiException] (e.g. 503) if the server has no LLM configured.
  Future<ParsedRequest> parseRequest(String text) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/parse-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    _throwIfNotOk(response);
    return ParsedRequest.fromJson(_decodeJsonObject(response));
  }

  /// Searches WHO GHO and HDX for real, citable case-data sources for a
  /// disease/region, so the user can pick one instead of being limited to
  /// the single built-in source. Best-effort on the backend — an empty
  /// list here means nothing was found, not necessarily an error.
  Future<List<DiscoveredSource>> searchCaseSources(String disease, String region) async {
    final uri = Uri.parse('$backendBaseUrl/api/search-case-sources').replace(
      queryParameters: {'disease': disease, 'region': region},
    );
    final response = await http.get(uri);
    _throwIfNotOk(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return decoded
        .map((e) => DiscoveredSource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IntegrationResult> runIntegration(IntegrationRequestParams params) async {
    if (params.caseDataSource == 'custom_upload') {
      return _runIntegrationWithUpload(params);
    }
    return _runIntegrationJson(params);
  }

  Future<IntegrationResult> _runIntegrationJson(IntegrationRequestParams params) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/integrate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'disease': params.disease,
        'region': params.region,
        'variables': params.variables,
        'start_date': _formatDate(params.startDate),
        'end_date': _formatDate(params.endDate),
        'scenario': 'historical',
        'aggregation': params.aggregation,
        'climate_source': params.climateSource,
        'case_data_source': params.caseDataSource,
        'population_source': params.populationSource,
        'custom_source_url': params.customSourceUrl,
        'who_indicator_code': params.whoIndicatorCode,
        'who_indicator_name': params.whoIndicatorName,
      }),
    );
    _throwIfNotOk(response);
    return IntegrationResult.fromJson(_decodeJsonObject(response));
  }

  Future<IntegrationResult> _runIntegrationWithUpload(
    IntegrationRequestParams params,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendBaseUrl/api/integrate/upload'),
    )
      ..fields['disease'] = params.disease
      ..fields['region'] = params.region
      ..fields['variables'] = params.variables.join(',')
      ..fields['start_date'] = _formatDate(params.startDate)
      ..fields['end_date'] = _formatDate(params.endDate)
      ..fields['aggregation'] = params.aggregation
      ..fields['climate_source'] = params.climateSource
      ..fields['population_source'] = params.populationSource
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          params.uploadedFileBytes!,
          filename: params.uploadedFileName ?? 'cases.csv',
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfNotOk(response);
    return IntegrationResult.fromJson(_decodeJsonObject(response));
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-01';

  Map<String, dynamic> _decodeJsonObject(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  void _throwIfNotOk(http.Response response) {
    if (response.statusCode == 200) return;
    final body = utf8.decode(response.bodyBytes);
    String detail = body;
    try {
      detail = (jsonDecode(body) as Map<String, dynamic>)['detail']?.toString() ?? body;
    } catch (_) {
      // Body wasn't JSON; fall back to the raw text already assigned above.
    }
    throw ApiException('Request failed (${response.statusCode}): $detail');
  }
}
