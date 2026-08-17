import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/points_view_model.dart';
import 'package:refuges_info_mobile/features/points/presentation/views/points_page.dart';

void main() {
  testWidgets('shows loaded points and data attribution', (tester) async {
    final viewModel = PointsViewModel(_FakeRepository((_) async => [_point]));
    await viewModel.load(_bounds);

    await tester.pumpWidget(_testApp(viewModel));

    expect(find.text('Baraque Pagnot'), findsOneWidget);
    expect(find.text('cabane non gardée - 1390 m - 6 places'), findsOneWidget);
    expect(
      find.text('Données Refuges.info sous licence CC BY-SA 2.0'),
      findsOneWidget,
    );
  });

  testWidgets('shows loading progress', (tester) async {
    final viewModel = PointsViewModel(_FakeRepository((_) async => []));

    await tester.pumpWidget(_testApp(viewModel));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('retries after an offline failure', (tester) async {
    var requests = 0;
    final viewModel = PointsViewModel(
      _FakeRepository((_) async {
        requests++;
        if (requests == 1) {
          throw const PointsConnectionException();
        }
        return [_point];
      }),
    );
    await viewModel.load(_bounds);
    await tester.pumpWidget(_testApp(viewModel));

    expect(find.text('Connexion indisponible'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(requests, 2);
    expect(find.text('Baraque Pagnot'), findsOneWidget);
  });
}

Widget _testApp(PointsViewModel viewModel) {
  return ChangeNotifierProvider.value(
    value: viewModel,
    child: const MaterialApp(home: PointsPage()),
  );
}

final _bounds = GeographicBounds(
  west: 5.6,
  south: 44.9,
  east: 5.9,
  north: 45.2,
);

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

class _FakeRepository implements PointsRepository {
  const _FakeRepository(this._getPoints);

  final Future<List<PointOfInterest>> Function(GeographicBounds) _getPoints;

  @override
  Future<List<PointOfInterest>> getPointsInBounds(GeographicBounds bounds) {
    return _getPoints(bounds);
  }
}
