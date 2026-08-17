import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';

class PointDetails {
  PointDetails({
    required this.point,
    required this.coordinatePrecision,
    required this.owner,
    required this.access,
    required this.remarks,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    required List<PointDetailInformation> information,
  }) : information = List.unmodifiable(information);

  final PointOfInterest point;
  final String coordinatePrecision;
  final PointDetailInformation? owner;
  final String? access;
  final String? remarks;
  final String creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PointDetailInformation> information;
}

class PointDetailInformation {
  const PointDetailInformation({required this.label, required this.value});

  final String label;
  final String value;
}
