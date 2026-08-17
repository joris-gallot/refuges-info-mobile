import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/rendered_map_feature.dart';

void main() {
  group('RenderedMapFeature.fromJson', () {
    test('identifies a cluster', () {
      final feature = RenderedMapFeature.fromJson({
        'properties': {'point_count': 12, 'cluster_id': 42.0},
      });

      expect(feature, isA<RenderedCluster>());
      expect((feature as RenderedCluster).id, 42);
    });

    test('extracts a Refuges.info point id', () {
      final feature = RenderedMapFeature.fromJson({
        'properties': {'id': 2240.0, 'name': 'Baraque Pagnot'},
      });

      expect(feature, isA<RenderedPoint>());
      expect((feature as RenderedPoint).id, 2240);
    });

    test('ignores unsupported map features', () {
      final feature = RenderedMapFeature.fromJson({
        'properties': {'name': 'Road'},
      });

      expect(feature, isA<UnsupportedMapFeature>());
    });
  });
}
