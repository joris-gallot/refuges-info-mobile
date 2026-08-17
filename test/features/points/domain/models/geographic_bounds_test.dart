import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';

void main() {
  group('GeographicBounds', () {
    test('serializes bounds in the API order', () {
      final bounds = GeographicBounds(
        west: 5.6,
        south: 44.9,
        east: 5.9,
        north: 45.2,
      );

      expect(bounds.toApiValue(), '5.6,44.9,5.9,45.2');
    });

    test('rejects reversed longitude bounds', () {
      expect(
        () => GeographicBounds(west: 6, south: 44, east: 5, north: 45),
        throwsArgumentError,
      );
    });

    test('rejects latitude outside geographic limits', () {
      expect(
        () => GeographicBounds(west: 5, south: -91, east: 6, north: 45),
        throwsArgumentError,
      );
    });
  });
}
