import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/points_view_model.dart';

void main() {
  group('PointsViewModel', () {
    test('moves from loading to loaded', () async {
      final completer = Completer<List<PointOfInterest>>();
      final viewModel = PointsViewModel(
        _FakeRepository((_) => completer.future),
      );

      final loading = viewModel.load(_bounds);
      expect(viewModel.state, isA<PointsLoading>());

      completer.complete([_point]);
      await loading;

      final state = viewModel.state;
      expect(state, isA<PointsLoaded>());
      expect((state as PointsLoaded).points.single, same(_point));
    });

    test('exposes an empty state when no point is returned', () async {
      final viewModel = PointsViewModel(_FakeRepository((_) async => []));

      await viewModel.load(_bounds);

      expect(viewModel.state, isA<PointsEmpty>());
    });

    test('exposes an offline state for connection failures', () async {
      final viewModel = PointsViewModel(
        _FakeRepository((_) async => throw const PointsConnectionException()),
      );

      await viewModel.load(_bounds);

      expect(viewModel.state, isA<PointsOffline>());
    });

    test('exposes a failure state for invalid data', () async {
      final viewModel = PointsViewModel(
        _FakeRepository((_) async => throw const PointsDataException()),
      );

      await viewModel.load(_bounds);

      expect(viewModel.state, isA<PointsFailure>());
    });

    test('keeps current points visible while refreshing', () async {
      final refreshResponse = Completer<List<PointOfInterest>>();
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) {
          requests++;
          return requests == 1
              ? Future.value([_point])
              : refreshResponse.future;
        }),
      );
      await viewModel.load(_bounds);

      final refresh = viewModel.load(_otherBounds);

      final refreshingState = viewModel.state as PointsLoaded;
      expect(refreshingState.points.single, same(_point));
      expect(refreshingState.isRefreshing, isTrue);

      refreshResponse.complete([]);
      await refresh;

      final refreshedState = viewModel.state as PointsLoaded;
      expect(refreshedState.points, isEmpty);
      expect(refreshedState.isRefreshing, isFalse);
    });

    test('keeps current points when a viewport refresh fails', () async {
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) async {
          requests++;
          if (requests == 1) {
            return [_point];
          }
          throw const PointsConnectionException();
        }),
      );
      await viewModel.load(_bounds);

      await viewModel.load(_otherBounds);

      final state = viewModel.state as PointsLoaded;
      expect(state.points.single, same(_point));
      expect(state.isRefreshing, isFalse);
      expect(state.refreshFailure, PointsRefreshFailure.offline);
    });

    test('does not reload unchanged bounds', () async {
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) async {
          requests++;
          return [_point];
        }),
      );

      await viewModel.load(_bounds);
      await viewModel.load(
        GeographicBounds(west: 5.6, south: 44.9, east: 5.9, north: 45.2),
      );

      expect(requests, 1);
    });

    test('ignores a stale response from an older request', () async {
      final firstResponse = Completer<List<PointOfInterest>>();
      final secondResponse = Completer<List<PointOfInterest>>();
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) {
          requests++;
          return requests == 1 ? firstResponse.future : secondResponse.future;
        }),
      );

      final firstLoad = viewModel.load(_bounds);
      final secondLoad = viewModel.load(_otherBounds);
      secondResponse.complete([_point]);
      await secondLoad;
      firstResponse.complete([]);
      await firstLoad;

      final state = viewModel.state;
      expect(state, isA<PointsLoaded>());
      expect((state as PointsLoaded).points.single, same(_point));
    });

    test('reloads current bounds with selected point types', () async {
      final filterResponse = Completer<List<PointOfInterest>>();
      Set<int> requestedTypeIds = {};
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) {
          requests++;
          return requests == 1
              ? Future.value([_point, _waterPoint])
              : filterResponse.future;
        }, onTypeIds: (typeIds) => requestedTypeIds = {...typeIds}),
      );
      await viewModel.load(_bounds);

      final filtering = viewModel.setSelectedTypeIds({7});

      final filteringState = viewModel.state as PointsLoaded;
      expect(filteringState.points, [_point]);
      expect(filteringState.isRefreshing, isTrue);
      expect(requestedTypeIds, {7});
      expect(viewModel.hasActiveTypeFilter, isTrue);

      filterResponse.complete([_point]);
      await filtering;

      final filteredState = viewModel.state as PointsLoaded;
      expect(filteredState.points, [_point]);
      expect(filteredState.isRefreshing, isFalse);

      await viewModel.setSelectedTypeIds({
        for (final type in supportedPointTypes) type.id,
      });

      expect(requestedTypeIds, isEmpty);
      expect(viewModel.hasActiveTypeFilter, isFalse);
    });

    test('does not reload when point type selection is unchanged', () async {
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((_) async {
          requests++;
          return [_point];
        }),
      );
      await viewModel.load(_bounds);

      await viewModel.setSelectedTypeIds(viewModel.selectedTypeIds);

      expect(requests, 1);
    });

    test('retries the last requested bounds', () async {
      var requests = 0;
      final viewModel = PointsViewModel(
        _FakeRepository((bounds) async {
          requests++;
          expect(bounds, same(_bounds));
          if (requests == 1) {
            throw const PointsConnectionException();
          }
          return [_point];
        }),
      );

      await viewModel.load(_bounds);
      await viewModel.retry();

      expect(requests, 2);
      expect(viewModel.state, isA<PointsLoaded>());
    });
  });
}

final _bounds = GeographicBounds(
  west: 5.6,
  south: 44.9,
  east: 5.9,
  north: 45.2,
);

final _otherBounds = GeographicBounds(west: 6, south: 45, east: 7, north: 46);

final _point = PointOfInterest(
  id: 2240,
  name: 'Baraque Pagnot',
  longitude: 5.82853,
  latitude: 45.08439,
  altitude: 1390,
  type: const PointOfInterestType(id: 7, name: 'cabane non gardée'),
  state: null,
  sleepingPlaces: 6,
  website: Uri.parse(
    'https://www.refuges.info/point/2240/'
    'cabane-non-gardee/baraque-Pagnot/',
  ),
);

final _waterPoint = PointOfInterest(
  id: 9999,
  name: 'Source des tests',
  longitude: 5.83,
  latitude: 45.09,
  altitude: 1400,
  type: const PointOfInterestType(id: 23, name: 'point d’eau'),
  state: null,
  sleepingPlaces: null,
  website: Uri.parse('https://www.refuges.info/point/9999/'),
);

class _FakeRepository implements PointsRepository {
  const _FakeRepository(this._getPoints, {this.onTypeIds});

  final Future<List<PointOfInterest>> Function(GeographicBounds) _getPoints;
  final void Function(Set<int>)? onTypeIds;

  @override
  Future<PointDetails> getPointDetails(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds, {
    Set<int> typeIds = const {},
  }) {
    onTypeIds?.call(typeIds);
    return _getPoints(bounds);
  }
}
