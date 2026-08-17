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
