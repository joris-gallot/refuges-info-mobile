import 'dart:async';

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

    expect(find.byKey(const Key('map')), findsOneWidget);

    await tester.tap(find.byTooltip('Afficher la liste'));
    await tester.pump();

    expect(find.text('Baraque Pagnot'), findsOneWidget);
    expect(find.text('cabane non gardée - 1390 m - 6 places'), findsOneWidget);
    expect(
      find.text('Données Refuges.info sous licence CC BY-SA 2.0'),
      findsOneWidget,
    );
  });

  testWidgets('filters map and list points by selected types', (tester) async {
    Set<int> requestedTypeIds = {};
    final viewModel = PointsViewModel(
      _FakeRepository(
        (_) async =>
            requestedTypeIds.isEmpty ? [_point, _waterPoint] : [_point],
        onTypeIds: (typeIds) => requestedTypeIds = {...typeIds},
      ),
    );
    await viewModel.load(_bounds);
    await tester.pumpWidget(_testApp(viewModel));

    await tester.tap(find.byTooltip('Filtrer les types de points'));
    await tester.pumpAndSettle();

    expect(find.text('Types de points'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(supportedPointTypes.length));

    await tester.tap(find.text('Tout désélectionner'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Appliquer'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('point-type-7')));
    await tester.pump();
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(requestedTypeIds, {7});
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);

    await tester.tap(find.byTooltip('Afficher la liste'));
    await tester.pump();

    expect(find.text('Baraque Pagnot'), findsOneWidget);
    expect(find.text('Source des tests'), findsNothing);
  });

  testWidgets('keeps the map visible while refreshing', (tester) async {
    final refreshResponse = Completer<List<PointOfInterest>>();
    var requests = 0;
    final viewModel = PointsViewModel(
      _FakeRepository((_) {
        requests++;
        return requests == 1 ? Future.value([_point]) : refreshResponse.future;
      }),
    );
    await viewModel.load(_bounds);
    await tester.pumpWidget(_testApp(viewModel));

    final refresh = viewModel.load(_otherBounds);
    await tester.pump();

    expect(find.byKey(const Key('map')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    refreshResponse.complete([_point]);
    await refresh;
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows a non-blocking error after a refresh failure', (
    tester,
  ) async {
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

    await tester.pumpWidget(_testApp(viewModel));

    expect(find.byKey(const Key('map')), findsOneWidget);
    expect(
      find.text('Carte hors ligne. Points précédents conservés.'),
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
    expect(find.byKey(const Key('map')), findsOneWidget);
  });
}

Widget _testApp(PointsViewModel viewModel) {
  return ChangeNotifierProvider.value(
    value: viewModel,
    child: MaterialApp(
      home: PointsPage(mapBuilder: (_, _) => const SizedBox(key: Key('map'))),
    ),
  );
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
  Future<List<PointOfInterest>> getPointsInBounds(
    GeographicBounds bounds, {
    Set<int> typeIds = const {},
  }) {
    onTypeIds?.call(typeIds);
    return _getPoints(bounds);
  }
}
