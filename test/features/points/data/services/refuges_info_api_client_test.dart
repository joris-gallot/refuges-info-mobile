import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuges_info_mobile/features/points/data/services/refuges_info_api_client.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';

void main() {
  group('RefugesInfoApiClient.fetchPointsInBounds', () {
    test('requests and parses simple GeoJSON points', () async {
      final fixture = await File('test/fixtures/bbox_simple.json')
          .readAsString();
      late http.Request capturedRequest;
      final client = RefugesInfoApiClient(
        MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            fixture,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final bounds = GeographicBounds(
        west: 5.6,
        south: 44.9,
        east: 5.9,
        north: 45.2,
      );

      final response = await client.fetchPointsInBounds(
        bounds: bounds,
        limit: 25,
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.path, '/api/bbox');
      expect(capturedRequest.url.queryParameters, {
        'bbox': '5.6,44.9,5.9,45.2',
        'nb_points': '25',
        'detail': 'simple',
        'format': 'geojson',
        'format_texte': 'texte',
      });
      expect(capturedRequest.headers['Accept'], 'application/json');
      expect(response.points, hasLength(2));
      expect(response.points.last.name, 'Cabane privée de Brondelière');
    });

    test('throws an API exception for a non-success status', () async {
      final client = RefugesInfoApiClient(
        MockClient((_) async => http.Response('Unavailable', 503)),
      );

      final future = client.fetchPointsInBounds(bounds: _bounds());

      await expectLater(
        future,
        throwsA(
          isA<RefugesInfoApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('throws a format exception for invalid JSON', () async {
      final client = RefugesInfoApiClient(
        MockClient((_) async => http.Response('not-json', 200)),
      );

      final future = client.fetchPointsInBounds(bounds: _bounds());

      await expectLater(future, throwsA(isA<FormatException>()));
    });

    test('rejects limits above the API-safe maximum', () async {
      var requested = false;
      final client = RefugesInfoApiClient(
        MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      final future = client.fetchPointsInBounds(bounds: _bounds(), limit: 251);

      await expectLater(future, throwsRangeError);
      expect(requested, isFalse);
    });
  });
}

GeographicBounds _bounds() {
  return GeographicBounds(west: 5.6, south: 44.9, east: 5.9, north: 45.2);
}
