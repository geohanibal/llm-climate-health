/// Interactive 3D globe for picking a region: one point per region, colored
/// by data availability, rendered on a rotatable/zoomable Earth sphere.
///
/// Surface texture: NASA Blue Marble ("Land shallow topo"), public domain
/// (U.S. government work), via Wikimedia Commons. Drop the JPEG at
/// `assets/earth_day.jpg` before using this widget — it is not bundled in
/// git (large binary asset).
///
/// Known issue: as of flutter_earth_globe 2.2.1, the sphere can render as a
/// blank canvas on Flutter Web (confirmed even in the package's own
/// full-screen usage pattern, with no console errors) — most likely a
/// shader/texture-binding API mismatch against recent Flutter/CanvasKit
/// versions. [WorldMapDialog] offers a reliable 2D fallback for this reason.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';

import '../app.dart';
import '../models/region_info.dart';

class WorldGlobeView extends StatefulWidget {
  /// All selectable regions with their reference coordinates.
  final Map<String, RegionInfo> regions;

  /// Region *names* that should render as "available" and be selectable.
  final Set<String> availableRegions;
  final String? selectedRegion;
  final ValueChanged<String> onRegionTap;

  const WorldGlobeView({
    super.key,
    required this.regions,
    required this.availableRegions,
    required this.onRegionTap,
    this.selectedRegion,
  });

  @override
  State<WorldGlobeView> createState() => _WorldGlobeViewState();
}

class _WorldGlobeViewState extends State<WorldGlobeView> {
  static const _unavailableColor = AppColors.mapUnavailable;
  static const _availableColor = AppColors.mapAvailable;
  static const _selectedColor = AppColors.mapSelected;

  late final FlutterEarthGlobeController _controller = FlutterEarthGlobeController(
    rotationSpeed: 0.05,
    isBackgroundFollowingSphereRotation: false,
    surface: const AssetImage('assets/earth_day.jpg'),
  );

  String? _hoveredName;

  @override
  void initState() {
    super.initState();
    _rebuildPoints();
  }

  @override
  void didUpdateWidget(covariant WorldGlobeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableRegions != widget.availableRegions ||
        oldWidget.selectedRegion != widget.selectedRegion ||
        oldWidget.regions != widget.regions) {
      _rebuildPoints();
    }
    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _focusOnSelected();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // `FlutterEarthGlobeController.updatePoint` silently no-ops (it computes
  // a copyWith() but never stores it back), so the only reliable way to
  // change a point's color/label is to remove it and add it back.
  void _rebuildPoints() {
    for (final point in List.of(_controller.points)) {
      _controller.removePoint(point.id);
    }
    for (final entry in widget.regions.entries) {
      final name = entry.key;
      final info = entry.value;
      final isSelected = name == widget.selectedRegion;
      final isAvailable = widget.availableRegions.contains(name);
      _controller.addPoint(
        Point(
          id: name,
          coordinates: GlobeCoordinates(info.lat, info.lon),
          label: name,
          isLabelVisible: isSelected,
          style: PointStyle(
            size: isSelected ? 7 : 4,
            color: isSelected
                ? _selectedColor
                : isAvailable
                    ? _availableColor
                    : _unavailableColor,
          ),
          onTap: isAvailable ? () => widget.onRegionTap(name) : null,
          onHover: () => setState(() => _hoveredName = name),
        ),
      );
    }
  }

  void _focusOnSelected() {
    final selected = widget.selectedRegion;
    if (selected == null) return;
    final info = widget.regions[selected];
    if (info == null) return;
    _controller.focusOnCoordinates(GlobeCoordinates(info.lat, info.lon), animate: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = (constraints.biggest.shortestSide / 2 - 12).clamp(60.0, 220.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: FlutterEarthGlobe(controller: _controller, radius: radius),
              ),
            ),
            SizedBox(
              height: 18,
              child: Text(
                _hoveredName ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
