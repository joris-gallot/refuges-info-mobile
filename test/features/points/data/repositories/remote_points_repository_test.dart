import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:refuges_info_mobile/features/points/data/models/bbox_response.dart';
import 'package:refuges_info_mobile/features/points/data/models/point_details_response.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/data/repositories/remote_points_repository.dart';
import 'package:refuges_info_mobile/features/points/data/services/refuges_info_api_client.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

void main() {
  group('RemotePointsRepository', () {
    test('maps API points to immutable domain models', () async {
      final api = _FakeApi(response: await _loadBboxFixture());
      final repository = RemotePointsRepository(api);

      final points = await repository.getPointsInBounds(_bounds);

      expect(points, hasLength(2));
      expect(points.first.id, 2240);
      expect(points.first.name, 'Baraque Pagnot');
      expect(points.first.type.id, 7);
      expect(points.first.type.name, 'cabane non gardée');
      expect(points.first.state, isNull);
      expect(points.first.sleepingPlaces, 6);
      expect(() => points.add(points.first), throwsUnsupportedError);
    });

    test('forwards selected point types to the API', () async {
      final api = _FakeApi(response: await _loadBboxFixture());
      final repository = RemotePointsRepository(api);

      await repository.getPointsInBounds(_bounds, typeIds: {7, 10});

      expect(api.requestedTypeIds, {7, 10});
    });

    test('maps complete API details to the domain model', () async {
      final api = _FakeApi(detailsResponse: await _loadDetailsFixture());
      final repository = RemotePointsRepository(api);

      final details = await repository.getPointDetails(6041);

      expect(details.point.id, 6041);
      expect(details.point.type.name, 'cabane non gardée');
      expect(details.coordinatePrecision, contains('photos aériennes'));
      expect(details.access, contains('GR 77'));
      expect(
        details.information.any((item) => item.label == 'Cheminée'),
        isTrue,
      );
      expect(
        details.information.any(
          (item) => item.label == 'Places prévues pour dormir',
        ),
        isFalse,
      );
      expect(
        () => details.information.add(
          const PointDetailInformation(label: 'Test', value: 'Oui'),
        ),
        throwsUnsupportedError,
      );
    });

    test('maps client failures to a connection exception', () async {
      final repository = RemotePointsRepository(
        _FakeApi(error: http.ClientException('Offline')),
      );

      await expectLater(
        repository.getPointsInBounds(_bounds),
        throwsA(isA<PointsConnectionException>()),
      );
    });

    test('maps timeouts to a connection exception', () async {
      final repository = RemotePointsRepository(
        _FakeApi(error: TimeoutException('Timed out')),
      );

      await expectLater(
        repository.getPointsInBounds(_bounds),
        throwsA(isA<PointsConnectionException>()),
      );
    });

    test('maps invalid API responses to a data exception', () async {
      final repository = RemotePointsRepository(
        _FakeApi(error: const FormatException('Invalid')),
      );

      await expectLater(
        repository.getPointsInBounds(_bounds),
        throwsA(isA<PointsDataException>()),
      );
    });
  });
}

final _bounds = GeographicBounds(
  west: 5.6,
  south: 44.9,
  east: 5.9,
  north: 45.2,
);

class _FakeApi implements RefugesInfoApi {
  _FakeApi({this.response, this.detailsResponse, this.error});

  final BboxResponse? response;
  final PointDetailsResponse? detailsResponse;
  final Object? error;
  Set<int>? requestedTypeIds;

  @override
  Future<BboxResponse> fetchPointsInBounds({
    required GeographicBounds bounds,
    Set<int> typeIds = const {},
    int limit = 250,
  }) async {
    requestedTypeIds = typeIds;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return response!;
  }

  @override
  Future<PointDetailsResponse> fetchPointDetails(int id) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return detailsResponse!;
  }
}

Future<BboxResponse> _loadBboxFixture() async {
  final source = await File('test/fixtures/bbox_simple.json').readAsString();
  return BboxResponse.fromJson(jsonDecode(source) as Map<String, Object?>);
}

Future<PointDetailsResponse> _loadDetailsFixture() async {
  final source = await File('test/fixtures/point_complete_cabin.json')
      .readAsString();
  return PointDetailsResponse.fromJson(
    jsonDecode(source) as Map<String, Object?>,
  );
}
