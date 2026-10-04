/// Widget tests for RequestFormCard's state machine: region-first source
/// filtering, construction-time regression guards, and submit-time
/// validation. Driven mostly through the public `RequestFormCardState`
/// (reachable via a GlobalKey, the same way HomePage drives `applyPrefill`
/// in the real app) rather than simulating raw dropdown taps.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/data_source_info.dart';
import 'package:climate_health_frontend/models/disease_info.dart';
import 'package:climate_health_frontend/models/integration_request_params.dart';
import 'package:climate_health_frontend/models/parsed_request.dart';
import 'package:climate_health_frontend/models/platform_options.dart';
import 'package:climate_health_frontend/models/region_info.dart';
import 'package:climate_health_frontend/widgets/request_form_card.dart';

const _defaultCaseSources = [
  DataSourceInfo(id: 'builtin', label: 'Built-in', citation: 'cite'),
  DataSourceInfo(id: 'who_gho', label: 'WHO GHO', citation: 'cite'),
  DataSourceInfo(id: 'custom_url', label: 'Custom URL', citation: 'cite'),
  DataSourceInfo(id: 'custom_upload', label: 'Upload', citation: 'cite'),
];

PlatformOptions _options({
  Map<String, DiseaseInfo>? diseases,
  Map<String, RegionInfo>? regions,
  List<DataSourceInfo>? climateSources,
  Map<String, List<String>>? climateSourceRegions,
  List<DataSourceInfo>? caseDataSources,
}) {
  return PlatformOptions(
    diseases: diseases ??
        const {
          'dengue': DiseaseInfo(
            key: 'dengue',
            label: 'Dengue',
            nativeResolution: 'month',
            regions: ['Thailand'],
            regionCoverage: {},
          ),
        },
    regions: regions ??
        const {
          'Thailand': RegionInfo(label: 'Thailand', lat: 15.87, lon: 100.99),
          'Kenya': RegionInfo(label: 'Kenya', lat: -0.02, lon: 37.9),
        },
    variables: const ['temperature', 'precipitation'],
    aggregations: const ['native', 'yearly', 'decadal'],
    climateSources: climateSources ??
        const [
          DataSourceInfo(id: 'open-meteo-era5', label: 'Open-Meteo', citation: 'cite'),
          DataSourceInfo(id: 'tmd', label: 'TMD', citation: 'cite'),
        ],
    climateSourceRegions: climateSourceRegions ?? const {'tmd': ['Thailand']},
    caseDataSources: caseDataSources ?? _defaultCaseSources,
  );
}

Widget _wrap(PlatformOptions options, {Key? formKey, ValueChanged<IntegrationRequestParams>? onSubmit}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: RequestFormCard(
          key: formKey,
          options: options,
          isSubmitting: false,
          onSubmit: onSubmit ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'does not crash when the first climate source is region-restricted and the initial region does not match it',
    (tester) async {
      // Regression test: _climateSource used to be seeded from the raw
      // (unfiltered) first climateSources entry. Here that's "tmd"
      // (restricted to Thailand), but the default disease only has data
      // for Kenya — before the fix this threw a DropdownButtonFormField
      // "exactly one item" assertion on the very first build.
      final options = _options(
        diseases: const {
          'dengue': DiseaseInfo(
            key: 'dengue',
            label: 'Dengue',
            nativeResolution: 'month',
            regions: ['Kenya'],
            regionCoverage: {},
          ),
        },
        climateSources: const [
          DataSourceInfo(id: 'tmd', label: 'TMD', citation: 'cite'),
          DataSourceInfo(id: 'open-meteo-era5', label: 'Open-Meteo', citation: 'cite'),
        ],
      );

      await tester.pumpWidget(_wrap(options));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Open-Meteo'), findsOneWidget);
    },
  );

  testWidgets(
    'does not crash when a region_coverage span has fewer than 2 elements',
    (tester) async {
      // Regression test: the "all good" status chip used to index
      // coverage[0]/coverage[1] without checking length first.
      final options = _options(
        diseases: const {
          'dengue': DiseaseInfo(
            key: 'dengue',
            label: 'Dengue',
            nativeResolution: 'month',
            regions: ['Thailand'],
            regionCoverage: {
              'Thailand': ['2020-01'],
            },
          ),
        },
      );

      await tester.pumpWidget(_wrap(options));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('has built-in Dengue data.'), findsOneWidget);
    },
  );

  testWidgets('shows a warning chip when the date range misses the coverage window', (tester) async {
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: ['Thailand'],
          regionCoverage: {
            'Thailand': ['2024-01', '2025-03'],
          },
        ),
      },
    );
    final key = GlobalKey<RequestFormCardState>();

    await tester.pumpWidget(_wrap(options, formKey: key));
    await tester.pumpAndSettle();

    // The form's default date range (2015-2023) predates the 2024-2025
    // coverage window seeded above, so the warning must already be showing.
    expect(find.textContaining('does not overlap that'), findsOneWidget);
  });

  testWidgets('applyPrefill switches disease/region and drops a stale WHO indicator', (tester) async {
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: ['Thailand'],
          regionCoverage: {},
        ),
        'malaria': DiseaseInfo(
          key: 'malaria',
          label: 'Malaria',
          nativeResolution: 'year',
          regions: ['Kenya'],
          regionCoverage: {},
        ),
      },
    );
    final key = GlobalKey<RequestFormCardState>();

    await tester.pumpWidget(_wrap(options, formKey: key));
    await tester.pumpAndSettle();

    key.currentState!.applyPrefill(
      const ParsedRequest(disease: 'malaria', region: 'Kenya', notes: ''),
    );
    await tester.pumpAndSettle();

    expect(find.text('Malaria'), findsWidgets);
    expect(find.text('Kenya has built-in Malaria data.'), findsOneWidget);
  });

  testWidgets('submit shows a validation error when custom_url has no URL entered', (tester) async {
    // Disease has no builtin regions at all, so the region-filtered
    // case-data-source init (the bug #3 fix) seeds _caseDataSource
    // directly to the first non-builtin entry — here, custom_url.
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: [],
          regionCoverage: {},
        ),
      },
      caseDataSources: const [
        DataSourceInfo(id: 'builtin', label: 'Built-in', citation: 'cite'),
        DataSourceInfo(id: 'custom_url', label: 'Custom URL', citation: 'cite'),
      ],
    );

    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    // The form is wrapped in a scroll view (as it is in the real app, under
    // HomePage) and the button can end up below the default test viewport.
    await tester.ensureVisible(find.text('Run integration'));
    await tester.tap(find.text('Run integration'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a URL for the custom data source.'), findsOneWidget);
  });

  testWidgets('submit shows a validation error when custom_upload has no file picked', (tester) async {
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: [],
          regionCoverage: {},
        ),
      },
      caseDataSources: const [
        DataSourceInfo(id: 'builtin', label: 'Built-in', citation: 'cite'),
        DataSourceInfo(id: 'custom_upload', label: 'Upload', citation: 'cite'),
      ],
    );

    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    // The form is wrapped in a scroll view (as it is in the real app, under
    // HomePage) and the button can end up below the default test viewport.
    await tester.ensureVisible(find.text('Run integration'));
    await tester.tap(find.text('Run integration'));
    await tester.pumpAndSettle();

    expect(find.text('Upload a CSV file for the custom data source.'), findsOneWidget);
  });

  testWidgets('submit shows a validation error when who_gho has no indicator picked', (tester) async {
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: [],
          regionCoverage: {},
        ),
      },
      caseDataSources: const [
        DataSourceInfo(id: 'builtin', label: 'Built-in', citation: 'cite'),
        DataSourceInfo(id: 'who_gho', label: 'WHO GHO', citation: 'cite'),
      ],
    );

    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    // The form is wrapped in a scroll view (as it is in the real app, under
    // HomePage) and the button can end up below the default test viewport.
    await tester.ensureVisible(find.text('Run integration'));
    await tester.tap(find.text('Run integration'));
    await tester.pumpAndSettle();

    expect(find.text('Search and pick a WHO indicator first.'), findsOneWidget);
  });

  testWidgets('time granularity spells out the native resolution for a monthly disease', (tester) async {
    final options = _options(); // default disease is dengue, native_resolution: month
    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    expect(find.text('As reported (monthly)'), findsOneWidget);
  });

  testWidgets('time granularity spells out the native resolution for a yearly disease', (tester) async {
    final options = _options(
      diseases: const {
        'malaria': DiseaseInfo(
          key: 'malaria',
          label: 'Malaria',
          nativeResolution: 'year',
          regions: ['Thailand'],
          regionCoverage: {},
        ),
      },
    );
    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    expect(find.text('As reported (yearly)'), findsOneWidget);
  });

  testWidgets('time granularity switches to yearly once WHO GHO is the case-data source, even for a monthly disease', (tester) async {
    // dengue has no builtin regions here, so the bug #3 fix seeds
    // _caseDataSource straight to the only non-builtin option: who_gho.
    final options = _options(
      diseases: const {
        'dengue': DiseaseInfo(
          key: 'dengue',
          label: 'Dengue',
          nativeResolution: 'month',
          regions: [],
          regionCoverage: {},
        ),
      },
      caseDataSources: const [
        DataSourceInfo(id: 'builtin', label: 'Built-in', citation: 'cite'),
        DataSourceInfo(id: 'who_gho', label: 'WHO GHO', citation: 'cite'),
      ],
    );
    await tester.pumpWidget(_wrap(options));
    await tester.pumpAndSettle();

    expect(find.text('As reported (yearly)'), findsOneWidget);
  });

  testWidgets('submit calls onSubmit with the current form state when valid', (tester) async {
    IntegrationRequestParams? submitted;
    final options = _options();

    await tester.pumpWidget(_wrap(options, onSubmit: (p) => submitted = p));
    await tester.pumpAndSettle();

    // The form is wrapped in a scroll view (as it is in the real app, under
    // HomePage) and the button can end up below the default test viewport.
    await tester.ensureVisible(find.text('Run integration'));
    await tester.tap(find.text('Run integration'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.disease, 'dengue');
    expect(submitted!.region, 'Thailand');
    expect(submitted!.caseDataSource, 'builtin');
  });

  testWidgets('submit shows a validation error when custom_upload climate has no file picked', (tester) async {
    final key = GlobalKey<RequestFormCardState>();
    final options = _options(
      climateSources: const [
        DataSourceInfo(id: 'open-meteo-era5', label: 'Open-Meteo', citation: 'cite'),
        DataSourceInfo(id: 'custom_upload', label: 'Custom Weather CSV', citation: 'cite'),
      ],
    );

    await tester.pumpWidget(_wrap(options, formKey: key));
    await tester.pumpAndSettle();

    key.currentState!.applyPrefill(const ParsedRequest(climateSource: 'custom_upload', notes: 'test'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Weather CSV'), findsOneWidget);

    await tester.ensureVisible(find.text('Run integration'));
    await tester.tap(find.text('Run integration'));
    await tester.pumpAndSettle();

    expect(find.text('Upload a CSV file for the custom weather source.'), findsOneWidget);
  });
}
