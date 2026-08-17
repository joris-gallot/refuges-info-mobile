class PointDetailsResponse {
  const PointDetailsResponse({
    required this.generator,
    required this.copyright,
    required this.timestamp,
    required this.point,
  });

  factory PointDetailsResponse.fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'type': 'FeatureCollection',
        'generator': String generator,
        'copyright': String copyright,
        'timestamp': String timestamp,
        'size': 1,
        'features': [Map<String, Object?> feature],
      } =>
        PointDetailsResponse(
          generator: generator,
          copyright: copyright,
          timestamp: _parseDate(timestamp, field: 'timestamp'),
          point: RefugesInfoPointDetails.fromJson(feature),
        ),
      _ => throw const FormatException('Invalid point details response.'),
    };
  }

  final String generator;
  final String copyright;
  final DateTime timestamp;
  final RefugesInfoPointDetails point;
}

class RefugesInfoPointDetails {
  RefugesInfoPointDetails({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.typeId,
    required this.typeName,
    required this.state,
    required this.sleepingPlaces,
    required this.website,
    required this.coordinatePrecision,
    required this.owner,
    required this.access,
    required this.remarks,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    required List<RefugesInfoPointInformation> information,
  }) : information = List.unmodifiable(information);

  factory RefugesInfoPointDetails.fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'type': 'Feature',
        'id': int id,
        'geometry': {
          'type': 'Point',
          'coordinates': [num longitude, num latitude],
        },
        'properties': Map<String, Object?> properties,
      } =>
        _fromProperties(
          id: id,
          longitude: longitude,
          latitude: latitude,
          properties: properties,
        ),
      _ => throw const FormatException('Invalid point details feature.'),
    };
  }

  final int id;
  final String name;
  final double longitude;
  final double latitude;
  final int? altitude;
  final int typeId;
  final String typeName;
  final String? state;
  final int? sleepingPlaces;
  final Uri website;
  final String coordinatePrecision;
  final RefugesInfoPointInformation? owner;
  final String? access;
  final String? remarks;
  final String creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RefugesInfoPointInformation> information;

  static RefugesInfoPointDetails _fromProperties({
    required int id,
    required num longitude,
    required num latitude,
    required Map<String, Object?> properties,
  }) {
    return switch (properties) {
      {
        'nom': String name,
        'type': {'id': int typeId, 'valeur': String typeName},
        'id': int propertyId,
        'coord': {
          'alt': Object? altitude,
          'precision': {'nom': String coordinatePrecision},
        },
        'etat': {'valeur': Object? state},
        'places': {
          'nom': String sleepingPlacesLabel,
          'valeur': Object? sleepingPlaces,
        },
        'lien': String website,
        'date': {'creation': String creation, 'derniere_modif': String updated},
        'createur': {'nom': String creatorName},
        'proprio': {'nom': String ownerLabel, 'valeur': Object? ownerValue},
        'acces': {'valeur': Object? access},
        'remarque': {'valeur': Object? remarks},
      }
          when propertyId == id =>
        RefugesInfoPointDetails(
          id: id,
          name: name,
          longitude: longitude.toDouble(),
          latitude: latitude.toDouble(),
          altitude: _nullableInt(altitude, field: 'altitude'),
          typeId: typeId,
          typeName: typeName,
          state: _nullableText(state, field: 'state'),
          sleepingPlaces: sleepingPlacesLabel.trim().isEmpty
              ? null
              : _nullableInt(sleepingPlaces, field: 'sleeping places'),
          website: _parseWebsite(website),
          coordinatePrecision: coordinatePrecision,
          owner: _parseLabeledValue(ownerLabel, ownerValue),
          access: _nullableText(access, field: 'access'),
          remarks: _nullableText(remarks, field: 'remarks'),
          creatorName: creatorName,
          createdAt: _parseDate(creation, field: 'creation date'),
          updatedAt: _parseDate(updated, field: 'update date'),
          information: _parseInformation(properties['info_comp']),
        ),
      _ => throw const FormatException('Invalid point details properties.'),
    };
  }
}

class RefugesInfoPointInformation {
  const RefugesInfoPointInformation({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;
}

List<RefugesInfoPointInformation> _parseInformation(Object? json) {
  if (json == null) {
    return const [];
  }
  if (json is! Map<String, Object?>) {
    throw const FormatException('Invalid point additional information.');
  }

  final information = <RefugesInfoPointInformation>[];
  for (final entry in json.entries) {
    final (label, value) = switch (entry.value) {
      {'nom': String label, 'valeur': Object? value} => (label, value),
      _ => throw const FormatException('Invalid point information.'),
    };
    final displayValue = _displayValue(value);
    if (label.trim().isNotEmpty && displayValue != null) {
      information.add(
        RefugesInfoPointInformation(
          key: entry.key,
          label: label.trim(),
          value: displayValue,
        ),
      );
    }
  }
  return List.unmodifiable(information);
}

RefugesInfoPointInformation? _parseLabeledValue(String label, Object? value) {
  final displayValue = _nullableText(value, field: 'labeled value');
  if (label.trim().isEmpty || displayValue == null) {
    return null;
  }
  return RefugesInfoPointInformation(
    key: 'owner',
    label: label.trim(),
    value: displayValue,
  );
}

String? _displayValue(Object? value) {
  return switch (value) {
    null => null,
    String text => text.trim().isEmpty ? null : text.trim(),
    num number => '$number',
    bool boolean => boolean ? 'Oui' : 'Non',
    _ => throw const FormatException('Invalid point information value.'),
  };
}

String? _nullableText(Object? value, {required String field}) {
  return switch (value) {
    null => null,
    String text => text.trim().isEmpty ? null : text.trim(),
    _ => throw FormatException('Invalid point $field.'),
  };
}

int? _nullableInt(Object? value, {required String field}) {
  return switch (value) {
    null => null,
    int number => number,
    _ => throw FormatException('Invalid point $field.'),
  };
}

Uri _parseWebsite(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
    throw const FormatException('Invalid point website.');
  }
  return uri;
}

DateTime _parseDate(String value, {required String field}) {
  return DateTime.tryParse(value) ??
      (throw FormatException('Invalid point $field.'));
}
