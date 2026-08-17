class PointOfInterest {
  const PointOfInterest({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.type,
    required this.state,
    required this.sleepingPlaces,
    required this.website,
  });

  final int id;
  final String name;
  final double longitude;
  final double latitude;
  final int? altitude;
  final PointOfInterestType type;
  final String? state;
  final int? sleepingPlaces;
  final Uri website;
}

class PointOfInterestType {
  const PointOfInterestType({required this.id, required this.name});

  final int id;
  final String name;
}

const supportedPointTypes = <PointOfInterestType>[
  PointOfInterestType(id: 7, name: 'cabane non gardée'),
  PointOfInterestType(id: 10, name: 'refuge gardé'),
  PointOfInterestType(id: 9, name: 'gîte d’étape'),
  PointOfInterestType(id: 29, name: 'grotte'),
  PointOfInterestType(id: 23, name: 'point d’eau'),
  PointOfInterestType(id: 3, name: 'passage délicat'),
  PointOfInterestType(id: 28, name: 'bâtiment en montagne'),
];
