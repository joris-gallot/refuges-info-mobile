import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/point_details_view_model.dart';
import 'package:refuges_info_mobile/features/points/presentation/views/point_details_page.dart';

void main() {
  testWidgets('shows complete point details and opens Refuges.info', (
    tester,
  ) async {
    final viewModel = PointDetailsViewModel(
      _FakeRepository((_) async => _details),
      _point.id,
    );
    await viewModel.load();
    Uri? launchedWebsite;

    await tester.pumpWidget(
      _testApp(
        viewModel,
        launchWebsite: (website) async {
          launchedWebsite = website;
          return true;
        },
      ),
    );

    expect(find.text(_point.name), findsOneWidget);
    expect(find.text('cabane non gardée'), findsOneWidget);
    expect(find.text('590 m'), findsOneWidget);
    expect(find.text('Clés à récupérer'), findsOneWidget);
    expect(find.text('Remarques'), findsOneWidget);
    expect(find.text('Accès'), findsOneWidget);
    expect(find.text('Cheminée'), findsOneWidget);
    expect(
      find.text('Coordonnées pointées sur photos aériennes'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Voir sur Refuges.info'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Voir sur Refuges.info'));
    await tester.pump();

    expect(launchedWebsite, _point.website);
    expect(
      find.text('Données Refuges.info sous licence CC BY-SA 2.0'),
      findsOneWidget,
    );
  });

  testWidgets('retries after an offline failure', (tester) async {
    var requests = 0;
    final viewModel = PointDetailsViewModel(
      _FakeRepository((_) async {
        requests++;
        if (requests == 1) {
          throw const PointsConnectionException();
        }
        return _details;
      }),
      _point.id,
    );
    await viewModel.load();
    await tester.pumpWidget(
      _testApp(viewModel, launchWebsite: (_) async => true),
    );

    expect(find.text('Connexion indisponible'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(requests, 2);
    expect(find.text('Localisation'), findsOneWidget);
  });

  testWidgets('shows feedback when Refuges.info cannot be opened', (
    tester,
  ) async {
    final viewModel = PointDetailsViewModel(
      _FakeRepository((_) async => _details),
      _point.id,
    );
    await viewModel.load();
    await tester.pumpWidget(
      _testApp(viewModel, launchWebsite: (_) async => false),
    );

    await tester.scrollUntilVisible(
      find.text('Voir sur Refuges.info'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Voir sur Refuges.info'));
    await tester.pump();

    expect(find.text('Impossible d’ouvrir Refuges.info.'), findsOneWidget);
  });
}

Widget _testApp(
  PointDetailsViewModel viewModel, {
  required PointWebsiteLauncher launchWebsite,
}) {
  return ChangeNotifierProvider.value(
    value: viewModel,
    child: MaterialApp(
      home: PointDetailsPage(summary: _point, launchWebsite: launchWebsite),
    ),
  );
}

final _point = PointOfInterest(
  id: 6041,
  name: 'Abri de la chapelle de N.D. de Trédos',
  longitude: 2.8497,
  latitude: 43.5076,
  altitude: 590,
  type: const PointOfInterestType(id: 7, name: 'cabane non gardée'),
  state: 'Clés à récupérer',
  sleepingPlaces: 0,
  website: Uri.parse('https://www.refuges.info/point/6041/'),
);

final _details = PointDetails(
  point: _point,
  coordinatePrecision: 'Coordonnées pointées sur photos aériennes',
  owner: const PointDetailInformation(
    label: 'Auprès de qui se renseigner',
    value: 'Mairie',
  ),
  access: 'Accès par le GR 77.',
  remarks: 'Abri ouvert toute l’année.',
  creatorName: 'Lauze',
  createdAt: DateTime.utc(2017, 12, 29, 12),
  updatedAt: DateTime.utc(2025, 1, 25, 12),
  information: const [
    PointDetailInformation(label: 'Cheminée', value: 'Oui'),
    PointDetailInformation(label: 'Latrines', value: 'Non'),
  ],
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
