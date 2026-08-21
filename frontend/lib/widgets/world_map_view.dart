/// Interactive, self-contained world map for picking a region: draws every
/// country's outline from a bundled GeoJSON-derived asset (no external map
/// tiles, so it works offline and never depends on a third-party service
/// being up during a demo) and highlights which ones currently have data.
///
/// The bundled outline asset is a *simplified* Natural Earth extract and is
/// missing polygons for many small countries/territories entirely (e.g.
/// Maldives, Mauritius — both real, selectable dengue regions). To keep
/// every backend-supported region clickable regardless of polygon coverage
/// or size, each available region also gets a small marker dot at its
/// actual reference coordinate ([RegionInfo.lat]/[lon], the same point the
/// ETL pipeline fetches climate data for); markers are checked first on tap
/// so they always win over a thin sliver of polygon underneath.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/country_shape.dart';
import '../models/region_info.dart';
import '../services/world_map_loader.dart';

class WorldMapView extends StatefulWidget {
  /// All selectable regions with their reference coordinates, used to place
  /// marker dots.
  final Map<String, RegionInfo> regions;

  /// Region *names* (matching [PlatformOptions.regions] keys) that should
  /// render as "available" and be selectable.
  final Set<String> availableRegions;
  final String? selectedRegion;
  final ValueChanged<String> onRegionTap;

  const WorldMapView({
    super.key,
    required this.regions,
    required this.availableRegions,
    required this.onRegionTap,
    this.selectedRegion,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

/// A country's boundary, pre-projected to screen-space pixels for one
/// canvas size, so hit-testing and painting never re-run the lon/lat
/// projection per frame or per pointer event.
class _ProjectedShape {
  final CountryShape shape;
  final List<List<Offset>> screenRings;

  const _ProjectedShape(this.shape, this.screenRings);
}

class _WorldMapViewState extends State<WorldMapView> {
  static const _markerRadius = 5.0;
  static const _markerHitRadius = 9.0;

  final _loader = const WorldMapLoader();
  List<CountryShape>? _shapes;
  Object? _loadError;
  String? _hoveredName;

  Size? _projectedForSize;
  List<_ProjectedShape> _projected = const [];
  Map<String, Offset> _markers = const {};

  @override
  void initState() {
    super.initState();
    _loader.load().then((shapes) {
      if (mounted) setState(() => _shapes = shapes);
    }).catchError((Object error) {
      if (mounted) setState(() => _loadError = error);
    });
  }

  static Offset _project(List<double> lonLat, Size size) {
    final x = (lonLat[0] + 180) / 360 * size.width;
    final y = (90 - lonLat[1]) / 180 * size.height;
    return Offset(x, y);
  }

  void _ensureProjected(Size size) {
    if (_projectedForSize == size || _shapes == null) return;
    _projected = _shapes!
        .map(
          (shape) => _ProjectedShape(
            shape,
            shape.polygons
                .map((ring) => ring.map((p) => _project([p.dx, p.dy], size)).toList())
                .toList(),
          ),
        )
        .toList();
    _markers = {
      for (final name in widget.availableRegions)
        if (widget.regions[name] case final info?)
          name: _project([info.lon, info.lat], size),
    };
    _projectedForSize = size;
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      final intersects = (a.dy > point.dy) != (b.dy > point.dy) &&
          point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx;
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// Marker dots are checked before polygons: they're the reliable path for
  /// every available region (see class doc), so they should win over
  /// whatever sliver of country polygon happens to sit underneath them.
  String? _hitTest(Offset localPosition, Size size) {
    _ensureProjected(size);
    for (final entry in _markers.entries) {
      if ((entry.value - localPosition).distance <= _markerHitRadius) return entry.key;
    }
    for (final entry in _projected) {
      for (final ring in entry.screenRings) {
        if (_pointInPolygon(localPosition, ring)) return entry.shape.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(child: Text('Could not load the world map: $_loadError'));
    }
    if (_shapes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureProjected(size);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MouseRegion(
                onHover: (event) {
                  final hit = _hitTest(event.localPosition, size);
                  if (hit != _hoveredName) setState(() => _hoveredName = hit);
                },
                onExit: (_) => setState(() => _hoveredName = null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final hit = _hitTest(details.localPosition, size);
                    if (hit != null && widget.availableRegions.contains(hit)) {
                      widget.onRegionTap(hit);
                    }
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _WorldMapPainter(
                      shapes: _projected,
                      markers: _markers,
                      availableRegions: widget.availableRegions,
                      selectedRegion: widget.selectedRegion,
                      hoveredName: _hoveredName,
                      markerRadius: _markerRadius,
                    ),
                  ),
                ),
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

class _WorldMapPainter extends CustomPainter {
  final List<_ProjectedShape> shapes;
  final Map<String, Offset> markers;
  final Set<String> availableRegions;
  final String? selectedRegion;
  final String? hoveredName;
  final double markerRadius;

  static const _unavailableFill = AppColors.mapUnavailable;
  static const _availableFill = AppColors.mapAvailable;
  static const _selectedFill = AppColors.mapSelected;
  static const _borderColor = Color(0xFFFFFFFF);

  _WorldMapPainter({
    required this.shapes,
    required this.markers,
    required this.availableRegions,
    required this.selectedRegion,
    required this.hoveredName,
    required this.markerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7FBFA));

    final border = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final entry in shapes) {
      final name = entry.shape.name;
      final isAvailable = availableRegions.contains(name);
      final isSelected = name == selectedRegion;
      final isHovered = name == hoveredName;

      final fill = Paint()
        ..color = isSelected
            ? _selectedFill
            : isAvailable
                ? (isHovered ? _availableFill.withValues(alpha: 0.85) : _availableFill)
                : _unavailableFill;

      for (final ring in entry.screenRings) {
        if (ring.length < 3) continue;
        final path = Path()..moveTo(ring.first.dx, ring.first.dy);
        for (final point in ring.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      }
    }

    final markerBorder = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final entry in markers.entries) {
      final isSelected = entry.key == selectedRegion;
      final isHovered = entry.key == hoveredName;
      final fill = Paint()
        ..color = isSelected
            ? _selectedFill
            : (isHovered ? _availableFill.withValues(alpha: 0.85) : _availableFill);
      final radius = isSelected ? markerRadius + 1.5 : markerRadius;
      canvas.drawCircle(entry.value, radius, fill);
      canvas.drawCircle(entry.value, radius, markerBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) {
    return oldDelegate.selectedRegion != selectedRegion ||
        oldDelegate.hoveredName != hoveredName ||
        oldDelegate.availableRegions != availableRegions ||
        oldDelegate.shapes != shapes ||
        oldDelegate.markers != markers;
  }
}
