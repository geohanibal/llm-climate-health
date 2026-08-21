/// Modal dialog hosting [WorldMapView] plus a legend and confirm/cancel
/// actions; returns the selected region name via [Navigator.pop].
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/region_info.dart';
import 'world_map_view.dart';

class WorldMapDialog extends StatefulWidget {
  final Map<String, RegionInfo> regions;
  final Set<String> availableRegions;
  final String? initialRegion;

  const WorldMapDialog({
    super.key,
    required this.regions,
    required this.availableRegions,
    this.initialRegion,
  });

  @override
  State<WorldMapDialog> createState() => _WorldMapDialogState();
}

class _WorldMapDialogState extends State<WorldMapDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRegion;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 700 ? size.width * 0.95 : 720.0;
    // The title bar, insets, legend, selected-region label, and actions
    // together take roughly 260px of vertical space regardless of the
    // map's own height — bound the map by whatever's actually left so it
    // can never overflow a short viewport (e.g. a small laptop window).
    final availableForMap = (size.height - 260).clamp(200.0, double.infinity);
    final dialogHeight = (dialogWidth * 0.55).clamp(240.0, 460.0);
    final mapHeight = dialogHeight < availableForMap ? dialogHeight : availableForMap;

    return AlertDialog(
      title: const Text('Choose a region'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(),
            const SizedBox(height: 8),
            SizedBox(
              height: mapHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: WorldMapView(
                  regions: widget.regions,
                  availableRegions: widget.availableRegions,
                  selectedRegion: _selected,
                  onRegionTap: (region) => setState(() => _selected = region),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: Text(
                _selected == null ? ' ' : 'Selected: $_selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
          child: const Text('Use this region'),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return const Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendEntry(color: AppColors.mapSelected, label: 'Selected'),
        _LegendEntry(color: AppColors.mapAvailable, label: 'Has data'),
        _LegendEntry(color: AppColors.mapUnavailable, label: 'No data for this disease/source'),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
