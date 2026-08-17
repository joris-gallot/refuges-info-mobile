import 'package:flutter_test/flutter_test.dart';
import 'package:refuges_info_mobile/app/app.dart';

void main() {
  testWidgets('affiche la présentation et les mentions du projet', (
    tester,
  ) async {
    await tester.pumpWidget(const RefugesInfoApp());

    expect(find.text('Refuges Info Mobile'), findsOneWidget);
    expect(find.text('Préparez vos sorties en montagne'), findsOneWidget);
    expect(
      find.text('Application communautaire non officielle'),
      findsOneWidget,
    );
    expect(
      find.text('Données Refuges.info sous licence CC BY-SA 2.0'),
      findsOneWidget,
    );
  });
}
