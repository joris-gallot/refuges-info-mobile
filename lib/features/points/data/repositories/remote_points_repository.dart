import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:refuges_info_mobile/features/points/data/models/bbox_response.dart';
import 'package:refuges_info_mobile/features/points/data/services/refuges_info_api_client.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class RemotePointsRepository implements PointsRepository {
  const RemotePointsRepository(this._api);

  final RefugesInfoApi _api;

  @override
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds,
  ) async {
    try {
      final response = await _api.fetchPointsInBounds(bounds: bounds);
      return List.unmodifiable(response.points.map(_toDomainModel));
    } on http.ClientException catch (_) {
      throw const PointsConnectionException();
    } on TimeoutException catch (_) {
      throw const PointsConnectionException();
    } on RefugesInfoApiException catch (_) {
      throw const PointsDataException();
    } on FormatException catch (_) {
      throw const PointsDataException();
    }
  }

  PointOfInterest _toDomainModel(RefugesInfoPoint point) {
    return PointOfInterest(
      id: point.id,
      name: point.name,
      longitude: point.longitude,
      latitude: point.latitude,
      altitude: point.altitude,
      type: PointOfInterestType(id: point.type.id, name: point.type.name),
      state: point.state.trim().isEmpty ? null : point.state,
      sleepingPlaces: point.sleepingPlaces,
      website: point.website,
    );
  }
}
