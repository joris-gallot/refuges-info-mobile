import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/point_details_view_model.dart';

void main() {
  group('PointDetailsViewModel', () {
    test('moves from loading to loaded', () async {
      final response = Completer<PointDetails>();
      final viewModel = PointDetailsViewModel(
        _FakeRepository((_) => response.future),
        6041,
      );

      final loading = viewModel.load();
      expect(viewModel.state, isA<PointDetailsLoading>());

      response.complete(_details);
      await loading;

      final state = viewModel.state as PointDetailsLoaded;
      expect(state.details, same(_details));
    });

    test('exposes an offline state for connection failures', () async {
      final viewModel = PointDetailsViewModel(
        _FakeRepository((_) async => throw const PointsConnectionException()),
        6041,
      );

      await viewModel.load();

      expect(viewModel.state, isA<PointDetailsOffline>());
    });

    test('retries the same point after a failure', () async {
      var requests = 0;
      final viewModel = PointDetailsViewModel(
        _FakeRepository((id) async {
          requests++;
          expect(id, 6041);
          if (requests == 1) {
            throw const PointsDataException();
          }
          return _details;
        }),
        6041,
      );

      await viewModel.load();
      await viewModel.load();

      expect(requests, 2);
      expect(viewModel.state, isA<PointDetailsLoaded>());
    });
  });
}

final _details = PointDetails(
  point: PointOfInterest(
    id: 6041,
    name: 'Abri de la chapelle de N.D. de Trédos',
    longitude: 2.8497,
    latitude: 43.5076,
    altitude: 590,
    type: const PointOfInterestType(id: 7, name: 'cabane non gardée'),
    state: 'Clés à récupérer',
    sleepingPlaces: 0,
    website: Uri.parse('https://www.refuges.info/point/6041/'),
  ),
  coordinatePrecision: 'Coordonnées pointées sur photos aériennes',
  owner: null,
  access: 'Accès par le GR 77.',
  remarks: null,
  creatorName: 'Lauze',
  createdAt: DateTime.utc(2017, 12, 29),
  updatedAt: DateTime.utc(2025, 1, 25),
  information: const [PointDetailInformation(label: 'Cheminée', value: 'Oui')],
);

class _FakeRepository implements PointsRepository {
  const _FakeRepository(this._getDetails);

  final Future<PointDetails> Function(int) _getDetails;

  @override
  Future<PointDetails> getPointDetails(int id) => _getDetails(id);

  @override
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds, {
    Set<int> typeIds = const {},
  }) {
    throw UnimplementedError();
  }
}
