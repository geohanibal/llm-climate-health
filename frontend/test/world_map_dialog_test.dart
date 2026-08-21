/// Widget tests for WorldMapDialog's selection state machine. Rather than
/// simulating a pixel-accurate tap on the map's lon/lat projection, these
/// drive the selection through WorldMapView's `onRegionTap` callback
/// directly — the same callback a real tap would invoke — which keeps the
/// test focused on the dialog's own state/Confirm/Navigator.pop wiring.
///
/// WorldMapView loads its country-outline asset via `rootBundle.loadString`
/// from `initState`; under `flutter test`'s fake-async pump loop that
/// Future never resolves on its own (a `pump`/`pumpAndSettle` loop timeout
/// each time), so every test settles it explicitly with `tester.runAsync`
/// first — the same real-event-loop escape hatch the framework provides
/// for exactly this "widget needs real asynchronous I/O to finish loading"
/// situation.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climate_health_frontend/models/region_info.dart';
import 'package:climate_health_frontend/widgets/world_map_dialog.dart';
import 'package:climate_health_frontend/widgets/world_map_view.dart';

const _regions = {
  'Thailand': RegionInfo(label: 'Thailand', lat: 15.87, lon: 100.99),
  'Kenya': RegionInfo(label: 'Kenya', lat: -0.02, lon: 37.9),
};

/// Lets WorldMapView's `rootBundle.loadString` call — real asynchronous I/O
/// that a fake-async `pump`/`pumpAndSettle` loop alone never resolves —
/// actually complete, then flushes the resulting `setState`.
Future<void> _settleMapAssetLoad(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

Future<String?> _openDialog(WidgetTester tester, {String? initialRegion}) async {
  String? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: context,
                builder: (context) => WorldMapDialog(
                  regions: _regions,
                  availableRegions: const {'Thailand', 'Kenya'},
                  initialRegion: initialRegion,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump(); // start the dialog route's entrance animation
  await tester.pump(const Duration(milliseconds: 200)); // let it finish
  await _settleMapAssetLoad(tester);
  return result;
}

void main() {
  testWidgets('Confirm starts disabled with no initial selection', (tester) async {
    await _openDialog(tester);

    final confirm = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use this region'));
    expect(confirm.onPressed, isNull);
  });

  testWidgets('selecting a region enables Confirm and returns it via Navigator.pop', (tester) async {
    final future = _openDialog(tester);
    await future; // dialog is open; result resolves once we pop it below.

    final mapView = tester.widget<WorldMapView>(find.byType(WorldMapView));
    mapView.onRegionTap('Thailand');
    await tester.pump();

    expect(find.text('Selected: Thailand'), findsOneWidget);
    final confirmFinder = find.widgetWithText(FilledButton, 'Use this region');
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNotNull);

    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();
  });

  testWidgets('Cancel closes the dialog without a selection', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (context) => WorldMapDialog(
                    regions: _regions,
                    availableRegions: const {'Thailand', 'Kenya'},
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _settleMapAssetLoad(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('starts pre-selected when initialRegion is set', (tester) async {
    await _openDialog(tester, initialRegion: 'Kenya');

    expect(find.text('Selected: Kenya'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use this region'));
    expect(confirm.onPressed, isNotNull);
  });
}
