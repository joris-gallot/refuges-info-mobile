class BboxResponse {
  const BboxResponse({
    required this.generator,
    required this.copyright,
    required this.timestamp,
    required this.points,
  });

  factory BboxResponse.fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'type': 'FeatureCollection',
        'generator': String generator,
        'copyright': String copyright,
        'timestamp': String timestamp,
        'size': int size,
        'features': List<Object?> features,
      } =>
        BboxResponse(
          generator: generator,
          copyright: copyright,
          timestamp: _parseTimestamp(timestamp),
          points: _parsePoints(features, expectedSize: size),
        ),
      _ => throw const FormatException('Invalid bbox response.'),
    };
  }

  final String generator;
  final String copyright;
  final DateTime timestamp;
  final List<RefugesInfoPoint> points;

  static DateTime _parseTimestamp(String value) {
    return DateTime.tryParse(value) ??
        (throw const FormatException('Invalid bbox timestamp.'));
  }

  static List<RefugesInfoPoint> _parsePoints(
    List<Object?> features, {
    required int expectedSize,
  }) {
    if (features.length != expectedSize) {
      throw const FormatException('Invalid bbox feature count.');
    }

    return List.unmodifiable(
      features.map(
        (feature) => switch (feature) {
          Map<String, Object?> json => RefugesInfoPoint.fromJson(json),
          _ => throw const FormatException('Invalid bbox feature.'),
        },
      ),
    );
  }
}

class RefugesInfoPoint {
  const RefugesInfoPoint({
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

  factory RefugesInfoPoint.fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'type': 'Feature',
        'id': int id,
        'geometry': {
          'type': 'Point',
          'coordinates': [num longitude, num latitude],
        },
        'properties': {
          'nom': String name,
          'type': {
            'id': int typeId,
            'valeur': String typeName,
            'icone': String icon,
          },
          'coord': {'alt': Object? altitude},
          'etat': {'valeur': String state},
          'places': {'valeur': Object? sleepingPlaces},
          'lien': String website,
        },
      } =>
        RefugesInfoPoint(
          id: id,
          name: name,
          longitude: longitude.toDouble(),
          latitude: latitude.toDouble(),
          altitude: _nullableInt(altitude, field: 'altitude'),
          type: RefugesInfoPointType(id: typeId, name: typeName, icon: icon),
          state: state,
          sleepingPlaces: _nullableInt(
            sleepingPlaces,
            field: 'sleeping places',
          ),
          website: _parseWebsite(website),
        ),
      _ => throw const FormatException('Invalid bbox point.'),
    };
  }

  final int id;
  final String name;
  final double longitude;
  final double latitude;
  final int? altitude;
  final RefugesInfoPointType type;
  final String state;
  final int? sleepingPlaces;
  final Uri website;

  static int? _nullableInt(Object? value, {required String field}) {
    return switch (value) {
      null => null,
      int number => number,
      _ => throw FormatException('Invalid point $field.'),
    };
  }

  static Uri _parseWebsite(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('Invalid point website.');
    }
    return uri;
  }
}

class RefugesInfoPointType {
  const RefugesInfoPointType({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final String icon;
}
