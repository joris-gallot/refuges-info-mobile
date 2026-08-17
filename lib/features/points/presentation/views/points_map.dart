import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/map_bounds.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_clusterer.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_map_style.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/rendered_map_feature.dart';

class PointsMap extends StatefulWidget {
  const PointsMap({
    super.key,
    required this.points,
    required this.onViewportChanged,
  });

  final List<PointOfInterest> points;
  final Future<void> Function(GeographicBounds bounds) onViewportChanged;

  @override
  State<PointsMap> createState() => _PointsMapState();
}

class _PointsMapState extends State<PointsMap> {
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _initialCamera = CameraPosition(
    target: LatLng(45.15, 5.85),
    zoom: 9,
  );
  static final _worldBounds = GeographicBounds(
    west: -180,
    south: -90,
    east: 180,
    north: 90,
  );

  MapLibreMapController? _controller;
  late PointsClusterer _clusterer;
  var _isStyleLoaded = false;

  @override
  void initState() {
    super.initState();
    _clusterer = PointsClusterer(widget.points);
  }

  @override
  void didUpdateWidget(PointsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.points, widget.points)) {
      _clusterer = PointsClusterer(widget.points);
      if (_isStyleLoaded) {
        unawaited(_updateClusters());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: _styleUrl,
          initialCameraPosition: _initialCamera,
          onMapCreated: (controller) => _controller = controller,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraIdle: _notifyVisibleBounds,
          onMapClick: _onMapClick,
          compassEnabled: true,
          rotateGesturesEnabled: false,
        ),
        const Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: _DataAttribution(),
        ),
      ],
    );
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final initialGeoJson = _clusterer.geoJson(
      _worldBounds,
      _initialCamera.zoom,
    );
    await controller.addSource(pointsSourceId, pointsSource(initialGeoJson));
    await controller.addCircleLayer(
      pointsSourceId,
      clusterLayerId,
      clusterCircleStyle,
      filter: clusterFilter,
    );
    await controller.addCircleLayer(
      pointsSourceId,
      pointLayerId,
      individualPointStyle,
      filter: individualPointFilter,
    );
    await controller.addSymbolLayer(
      pointsSourceId,
      clusterCountLayerId,
      clusterCountStyle,
      filter: clusterFilter,
      enableInteraction: false,
    );
    _isStyleLoaded = true;
    await _notifyVisibleBounds();
  }

  Future<void> _notifyVisibleBounds() async {
    final controller = _controller;
    if (controller == null || !_isStyleLoaded) {
      return;
    }

    final mapBounds = await controller.getVisibleRegion();
    final bounds = geographicBoundsFromMap(mapBounds);
    if (bounds == null) {
      return;
    }

    await _updateClusters(bounds: bounds);
    await widget.onViewportChanged(bounds);
  }

  Future<void> _updateClusters({GeographicBounds? bounds}) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final visibleBounds =
        bounds ?? geographicBoundsFromMap(await controller.getVisibleRegion());
    if (visibleBounds == null) {
      return;
    }

    final zoom = controller.cameraPosition?.zoom ?? _initialCamera.zoom;
    final geoJson = _clusterer.geoJson(visibleBounds, zoom);
    await controller.setGeoJsonSource(pointsSourceId, geoJson);
  }

  Future<void> _onMapClick(Point<double> position, LatLng coordinates) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final features = await controller.queryRenderedFeatures(position, [
      clusterLayerId,
      pointLayerId,
    ], null);
    final feature = RenderedMapFeature.fromJson(
      features.isEmpty ? null : features.first,
    );

    switch (feature) {
      case RenderedCluster(:final id):
        await _zoomIntoCluster(id, coordinates);
      case RenderedPoint(:final id):
        _showPoint(id);
      case UnsupportedMapFeature():
        break;
    }
  }

  Future<void> _zoomIntoCluster(int id, LatLng coordinates) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final currentZoom = controller.cameraPosition?.zoom ?? _initialCamera.zoom;
    final expansionZoom = _clusterer.expansionZoom(id);
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        coordinates,
        min(max(expansionZoom, currentZoom + 1), 16),
      ),
    );
  }

  void _showPoint(int id) {
    final point = _findPoint(id);
    if (!mounted || point == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PointPreview(point: point),
    );
  }

  PointOfInterest? _findPoint(int id) {
    for (final point in widget.points) {
      if (point.id == id) {
        return point;
      }
    }
    return null;
  }
}

class _PointPreview extends StatelessWidget {
  const _PointPreview({required this.point});

  final PointOfInterest point;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(point.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(point.type.name),
            if (point.altitude case final altitude?) Text('$altitude m'),
          ],
        ),
      ),
    );
  }
}

class _DataAttribution extends StatelessWidget {
  const _DataAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            'Données Refuges.info - CC BY-SA 2.0',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}
