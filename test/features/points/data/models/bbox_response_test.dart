import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/data/models/bbox_response.dart';

void main() {
  group('BboxResponse.fromJson', () {
    test('parses a real simple GeoJSON response', () async {
      final response = BboxResponse.fromJson(await _loadFixture());

      expect(response.generator, 'Refuges.info API');
      expect(response.copyright, contains('CC By-Sa 2.0'));
      expect(response.timestamp, DateTime.parse('2026-08-17T17:36:28+02:00'));
      expect(response.points, hasLength(2));

      final point = response.points.first;
      expect(point.id, 2240);
      expect(point.name, 'Baraque Pagnot');
      expect(point.longitude, 5.82853);
      expect(point.latitude, 45.08439);
      expect(point.altitude, 1390);
      expect(point.type.id, 7);
      expect(point.type.name, 'cabane non gardée');
      expect(point.type.icon, 'cabane');
      expect(point.state, isEmpty);
      expect(point.sleepingPlaces, 6);
      expect(
        point.website,
        Uri.parse(
          'https://www.refuges.info/point/2240/'
          'cabane-non-gardee/baraque-Pagnot/',
        ),
      );
    });

    test('accepts a null sleeping place count from the API', () async {
      final response = BboxResponse.fromJson(await _loadFixture());

      expect(response.points.last.sleepingPlaces, isNull);
      expect(response.points.last.state, 'Fermée');
    });

    test(
      'ignores sleeping places when the type has no capacity field',
      () async {
        final json = await _loadFixture();
        final feature =
            (json['features'] as List<Object?>).first as Map<String, Object?>;
        final properties = feature['properties'] as Map<String, Object?>;
        final places = properties['places'] as Map<String, Object?>;
        places['nom'] = '';
        places['valeur'] = 0;

        final response = BboxResponse.fromJson(json);

        expect(response.points.first.sleepingPlaces, isNull);
      },
    );

    test('rejects a feature count inconsistent with size', () async {
      final json = await _loadFixture();
      json['size'] = 3;

      expect(
        () => BboxResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unexpected response shape', () {
      expect(
        () => BboxResponse.fromJson(const {'type': 'FeatureCollection'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Future<Map<String, Object?>> _loadFixture() async {
  final source = await File('test/fixtures/bbox_simple.json').readAsString();
  return jsonDecode(source) as Map<String, Object?>;
}
