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

  @override
  bool operator ==(Object other) {
    return other is GeographicBounds &&
        other.west == west &&
        other.south == south &&
        other.east == east &&
        other.north == north;
  }

  @override
  int get hashCode => Object.hash(west, south, east, north);
}
