import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_clusterer.dart';

void main() {
  group('PointsClusterer', () {
    test('groups nearby points at low zoom', () {
      final clusterer = PointsClusterer(_points);

      final geoJson = clusterer.geoJson(_bounds, 2);
      final features = geoJson['features'] as List<dynamic>;
      final feature = features.single as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;

      expect(feature['id'], isA<int>());
      expect(properties['cluster'], isTrue);
      expect(properties['point_count'], 3);
      expect(properties['point_count_abbreviated'], '3');
      expect(properties['cluster_id'], isA<int>());
    });

    test('returns individual points at maximum zoom', () {
      final clusterer = PointsClusterer(_points);

      final geoJson = clusterer.geoJson(_bounds, 17);
      final features = geoJson['features'] as List<dynamic>;
      final ids = features.map(
        (feature) => (feature as Map<String, dynamic>)['id'],
      );

      expect(ids, containsAll([1, 2, 3]));
    });

    test('returns an expansion zoom for a cluster', () {
      final clusterer = PointsClusterer(_points);
      final geoJson = clusterer.geoJson(_bounds, 2);
      final feature =
          (geoJson['features'] as List<dynamic>).single as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;

      final zoom = clusterer.expansionZoom(properties['cluster_id'] as int);

      expect(zoom, greaterThan(2));
      expect(zoom, lessThanOrEqualTo(16));
    });
  });
}

final _bounds = GeographicBounds(west: 5, south: 44, east: 7, north: 46);

final _points = [
  _point(1, 5.8, 45.1),
  _point(2, 5.81, 45.11),
  _point(3, 5.82, 45.12),
];

PointOfInterest _point(int id, double longitude, double latitude) {
  return PointOfInterest(
    id: id,
    name: 'Point $id',
    longitude: longitude,
    latitude: latitude,
    altitude: null,
    type: const PointOfInterestType(id: 7, name: 'cabane non gardée'),
    state: null,
    sleepingPlaces: null,
    website: Uri.parse('https://www.refuges.info/point/$id'),
  );
}
