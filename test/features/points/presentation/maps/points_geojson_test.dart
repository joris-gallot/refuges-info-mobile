import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_geojson.dart';

void main() {
  test('converts points to a GeoJSON feature collection', () {
    final geoJson = pointsToGeoJson([_point]);

    expect(geoJson['type'], 'FeatureCollection');
    expect(geoJson['features'], [
      {
        'type': 'Feature',
        'id': 2240,
        'geometry': {
          'type': 'Point',
          'coordinates': [5.82853, 45.08439],
        },
        'properties': {'id': 2240, 'name': 'Baraque Pagnot'},
      },
    ]);
  });
}

final _point = PointOfInterest(
  id: 2240,
  name: 'Baraque Pagnot',
  longitude: 5.82853,
  latitude: 45.08439,
  altitude: 1390,
  type: const PointOfInterestType(id: 7, name: 'cabane non gardée'),
  state: null,
  sleepingPlaces: 6,
  website: Uri.parse(
    'https://www.refuges.info/point/2240/'
    'cabane-non-gardee/baraque-Pagnot/',
  ),
);
