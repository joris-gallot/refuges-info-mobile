import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';

Map<String, dynamic> pointsToGeoJson(List<PointOfInterest> points) {
  return {
    'type': 'FeatureCollection',
    'features': [
      for (final point in points)
        {
          'type': 'Feature',
          'id': point.id,
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
          'properties': {'id': point.id, 'name': point.name},
        },
    ],
  };
}
