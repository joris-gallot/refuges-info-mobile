class GeographicBounds {
  GeographicBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  }) {
    if (west < -180 || east > 180 || west >= east) {
      throw ArgumentError('Invalid longitude bounds.');
    }
    if (south < -90 || north > 90 || south >= north) {
      throw ArgumentError('Invalid latitude bounds.');
    }
  }

  final double west;
  final double south;
  final double east;
  final double north;

  String toApiValue() => '$west,$south,$east,$north';
}
