import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';

GeographicBounds? geographicBoundsFromMap(LatLngBounds bounds) {
  final southwest = bounds.southwest;
  final northeast = bounds.northeast;
  if (southwest.longitude >= northeast.longitude ||
      southwest.latitude >= northeast.latitude) {
    return null;
  }

  return GeographicBounds(
    west: _roundCoordinate(southwest.longitude),
    south: _roundCoordinate(southwest.latitude),
    east: _roundCoordinate(northeast.longitude),
    north: _roundCoordinate(northeast.latitude),
  );
}

double _roundCoordinate(double value) {
  return (value * 1000000).round() / 1000000;
}
