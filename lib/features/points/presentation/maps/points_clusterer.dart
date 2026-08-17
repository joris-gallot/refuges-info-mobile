import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:supercluster/supercluster.dart';

class PointsClusterer {
  PointsClusterer(List<PointOfInterest> points)
    : _supercluster = SuperclusterImmutable<PointOfInterest>(
        getX: (point) => point.longitude,
        getY: (point) => point.latitude,
        maxZoom: 16,
        radius: 48,
      )..load(points);

  final SuperclusterImmutable<PointOfInterest> _supercluster;

  Map<String, dynamic> geoJson(GeographicBounds bounds, double zoom) {
    final elements = _supercluster.search(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom.floor(),
    );

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final element in elements)
          element.handle(
            cluster: (cluster) => {
              'type': 'Feature',
              'id': int.parse(cluster.uuid),
              'geometry': {
                'type': 'Point',
                'coordinates': [cluster.longitude, cluster.latitude],
              },
              'properties': {
                'cluster': true,
                'cluster_id': int.parse(cluster.uuid),
                'point_count': cluster.childPointCount,
                'point_count_abbreviated': _abbreviate(cluster.childPointCount),
              },
            },
            point: (point) {
              final value = point.originalPoint;
              return {
                'type': 'Feature',
                'id': value.id,
                'geometry': {
                  'type': 'Point',
                  'coordinates': [value.longitude, value.latitude],
                },
                'properties': {'id': value.id, 'name': value.name},
              };
            },
          ),
      ],
    };
  }

  double expansionZoom(int clusterId) {
    return _supercluster.expansionZoomOf(clusterId).toDouble();
  }

  String _abbreviate(int count) {
    if (count < 1000) {
      return '$count';
    }
    final thousands = count / 1000;
    return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
  }
}
