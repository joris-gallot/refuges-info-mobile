import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:refuges_info_mobile/features/points/data/models/bbox_response.dart';
import 'package:refuges_info_mobile/features/points/data/models/point_details_response.dart';
import 'package:refuges_info_mobile/features/points/data/services/refuges_info_api_client.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class RemotePointsRepository implements PointsRepository {
  const RemotePointsRepository(this._api);

  final RefugesInfoApi _api;

  @override
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds, {
    Set<int> typeIds = const {},
  }) {
    return _guard(() async {
      final response = await _api.fetchPointsInBounds(
        bounds: bounds,
        typeIds: typeIds,
      );
      return List.unmodifiable(response.points.map(_toDomainModel));
    });
  }

  @override
  Future<PointDetails> getPointDetails(int id) {
    return _guard(() async {
      final response = await _api.fetchPointDetails(id);
      return _toPointDetails(response.point);
    });
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
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

  PointDetails _toPointDetails(RefugesInfoPointDetails point) {
    return PointDetails(
      point: PointOfInterest(
        id: point.id,
        name: point.name,
        longitude: point.longitude,
        latitude: point.latitude,
        altitude: point.altitude,
        type: PointOfInterestType(id: point.typeId, name: point.typeName),
        state: point.state,
        sleepingPlaces: point.sleepingPlaces,
        website: point.website,
      ),
      coordinatePrecision: point.coordinatePrecision,
      owner: switch (point.owner) {
        final owner? => PointDetailInformation(
          label: owner.label,
          value: owner.value,
        ),
        null => null,
      },
      access: point.access,
      remarks: point.remarks,
      creatorName: point.creatorName,
      createdAt: point.createdAt,
      updatedAt: point.updatedAt,
      information: [
        for (final information in point.information)
          if (information.key != 'places')
            PointDetailInformation(
              label: information.label,
              value: information.value,
            ),
      ],
    );
  }
}
