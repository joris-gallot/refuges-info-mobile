import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/presentation/maps/points_map_style.dart';

void main() {
  test('configures the GeoJSON source attribution', () {
    final source = pointsSource(const {
      'type': 'FeatureCollection',
      'features': [],
    });

    expect(source.cluster, isFalse);
    expect(source.attribution, contains('Refuges.info'));
    expect(source.data, isA<Map<String, dynamic>>());
  });

  test('separates cluster and individual point layers', () {
    expect(clusterFilter, ['has', 'point_count']);
    expect(individualPointFilter, [
      '!',
      ['has', 'point_count'],
    ]);
    expect(clusterCountStyle.textField, ['get', 'point_count_abbreviated']);
    expect(clusterCountStyle.textAllowOverlap, isTrue);
    expect(clusterCountStyle.textFont, ['Noto Sans Bold']);
    expect(individualPointStyle.circleRadius, 7);
  });
}
