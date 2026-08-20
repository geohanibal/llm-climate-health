/// Modal dialog hosting the region picker (2D map by default, with an
/// optional 3D globe toggle) plus a legend and confirm/cancel actions;
/// returns the selected region name via [Navigator.pop].
///
/// The 2D map is the default because it renders reliably everywhere. The
/// 3D globe (flutter_earth_globe) is offered as an opt-in alternative: on
/// some browser/GPU combinations its shader-based renderer fails silently
/// and shows a blank sphere — see `world_globe_view.dart`'s doc comment.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/region_info.dart';
import 'world_globe_view.dart';
import 'world_map_view.dart';

enum _MapMode { flat, globe }

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
  _MapMode _mode = _MapMode.flat;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRegion;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 700 ? size.width * 0.95 : 720.0;
    final dialogHeight = (dialogWidth * 0.55).clamp(320.0, 460.0);

    return AlertDialog(
      title: const Text('Choose a region'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildLegend()),
                SegmentedButton<_MapMode>(
                  segments: const [
                    ButtonSegment(
                      value: _MapMode.flat,
                      label: Text('2D map'),
                      icon: Icon(Icons.map_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: _MapMode.globe,
                      label: Text('3D globe'),
                      icon: Icon(Icons.public, size: 16),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            if (_mode == _MapMode.globe)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Experimental: on some browsers this renders as a blank '
                  'sphere. Switch back to the 2D map if that happens.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: dialogHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: _mode == _MapMode.flat
                    ? WorldMapView(
                        availableRegions: widget.availableRegions,
                        selectedRegion: _selected,
                        onRegionTap: (region) => setState(() => _selected = region),
                      )
                    : WorldGlobeView(
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
