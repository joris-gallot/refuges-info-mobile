import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_geojson.dart';

class PointsMap extends StatefulWidget {
  const PointsMap({super.key, required this.points});

  final List<PointOfInterest> points;

  @override
  State<PointsMap> createState() => _PointsMapState();
}

class _PointsMapState extends State<PointsMap> {
  static const _sourceId = 'refuges-info-points';
  static const _layerId = 'refuges-info-points-layer';
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _initialCamera = CameraPosition(
    target: LatLng(45.15, 5.85),
    zoom: 9,
  );

  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: _styleUrl,
          initialCameraPosition: _initialCamera,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
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

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(
        data: pointsToGeoJson(widget.points),
        attribution: 'Données Refuges.info - CC BY-SA 2.0',
      ),
    );
    await controller.addCircleLayer(
      _sourceId,
      _layerId,
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: '#315C4C',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  void _onFeatureTapped(
    Point<double> _,
    LatLng _,
    String id,
    String layerId,
    Annotation? _,
  ) {
    if (!mounted || layerId != _layerId) {
      return;
    }

    final point = _findPoint(id);
    if (point == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PointPreview(point: point),
    );
  }

  PointOfInterest? _findPoint(String id) {
    for (final point in widget.points) {
      if (point.id.toString() == id) {
        return point;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
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
