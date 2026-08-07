/// Modal dialog hosting [WorldMapView] plus a legend and confirm/cancel
/// actions; returns the selected region name via [Navigator.pop].
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'world_map_view.dart';

class WorldMapDialog extends StatefulWidget {
  final Set<String> availableRegions;
  final String? initialRegion;

  const WorldMapDialog({
    super.key,
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
            _buildLegend(),
            const SizedBox(height: 8),
            SizedBox(
              height: dialogHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: WorldMapView(
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
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: const [
        _LegendEntry(color: Color(0xFF1F6F5C), label: 'Selected'),
        _LegendEntry(color: Color(0xFFA8D5C9), label: 'Has data'),
        _LegendEntry(color: Color(0xFFE0E0E0), label: 'No data for this disease/source'),
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
