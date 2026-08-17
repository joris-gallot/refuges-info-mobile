import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/map_bounds.dart';

void main() {
  group('geographicBoundsFromMap', () {
    test('converts MapLibre bounds to API bounds', () {
      final bounds = geographicBoundsFromMap(
        LatLngBounds(
          southwest: const LatLng(44.9, 5.6),
          northeast: const LatLng(45.2, 5.9),
        ),
      );

      expect(bounds?.toApiValue(), '5.6,44.9,5.9,45.2');
    });

    test('ignores a viewport crossing the antimeridian', () {
      final bounds = geographicBoundsFromMap(
        LatLngBounds(
          southwest: const LatLng(-10, 170),
          northeast: const LatLng(10, -170),
        ),
      );

      expect(bounds, isNull);
    });
  });
}
