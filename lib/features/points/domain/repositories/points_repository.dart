import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';

abstract interface class PointsRepository {
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds, {
    Set<int> typeIds = const {},
  });
}

sealed class PointsRepositoryException implements Exception {
  const PointsRepositoryException();
}

class PointsConnectionException extends PointsRepositoryException {
  const PointsConnectionException();
}

class PointsDataException extends PointsRepositoryException {
  const PointsDataException();
}
