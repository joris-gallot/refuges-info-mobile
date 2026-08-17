import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/data/models/point_details_response.dart';

void main() {
  group('PointDetailsResponse.fromJson', () {
    test('parses complete shelter details from a real response', () async {
      final response = PointDetailsResponse.fromJson(
        await _loadFixture('point_complete_cabin.json'),
      );

      expect(response.generator, 'Refuges.info API');
      expect(response.point.id, 6041);
      expect(response.point.name, 'Abri de la chapelle de N.D. de Trédos');
      expect(response.point.altitude, 590);
      expect(response.point.typeName, 'cabane non gardée');
      expect(response.point.state, 'Clés à récupérer');
      expect(response.point.sleepingPlaces, 0);
      expect(response.point.coordinatePrecision, contains('photos aériennes'));
      expect(response.point.owner, isNull);
      expect(response.point.access, contains('GR 77'));
      expect(response.point.remarks, isNull);
      expect(response.point.creatorName, 'Lauze');
      expect(response.point.createdAt.year, 2017);
      expect(response.point.updatedAt.year, 2025);
      expect(
        response.point.information.any(
          (information) =>
              information.key == 'cheminee' && information.value == 'Oui',
        ),
        isTrue,
      );
      expect(
        response.point.information.any(
          (information) =>
              information.key == 'places' && information.value == '0',
        ),
        isTrue,
      );
    });

    test('accepts optional fields absent from a real water point', () async {
      final response = PointDetailsResponse.fromJson(
        await _loadFixture('point_complete_water.json'),
      );

      expect(response.point.typeId, 23);
      expect(response.point.state, isNull);
      expect(response.point.sleepingPlaces, isNull);
      expect(response.point.owner, isNull);
      expect(response.point.remarks, isNull);
      expect(response.point.information, isEmpty);
      expect(response.point.access, contains('carrefour de sentiers'));
    });

    test('rejects a property id inconsistent with the feature', () async {
      final json = await _loadFixture('point_complete_cabin.json');
      final feature =
          (json['features'] as List<Object?>).single as Map<String, Object?>;
      final properties = feature['properties'] as Map<String, Object?>;
      properties['id'] = 999;

      expect(
        () => PointDetailsResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Future<Map<String, Object?>> _loadFixture(String name) async {
  final source = await File('test/fixtures/$name').readAsString();
  return jsonDecode(source) as Map<String, Object?>;
}
