import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:refuges_info_mobile/features/points/data/models/bbox_response.dart';
import 'package:refuges_info_mobile/features/points/data/models/point_details_response.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';

abstract interface class RefugesInfoApi {
  Future<BboxResponse> fetchPointsInBounds({
    required GeographicBounds bounds,
    Set<int> typeIds = const {},
    int limit = 250,
  });

  Future<PointDetailsResponse> fetchPointDetails(int id);
}

class RefugesInfoApiClient implements RefugesInfoApi {
  RefugesInfoApiClient(
    this._httpClient, {
    Uri? baseUri,
    this.requestTimeout = const Duration(seconds: 15),
  }) : baseUri = baseUri ?? Uri.https('www.refuges.info', '/api/');

  final http.Client _httpClient;
  final Uri baseUri;
  final Duration requestTimeout;

  @override
  Future<BboxResponse> fetchPointsInBounds({
    required GeographicBounds bounds,
    Set<int> typeIds = const {},
    int limit = 250,
  }) async {
    if (limit < 1 || limit > 250) {
      throw RangeError.range(limit, 1, 250, 'limit');
    }

    final sortedTypeIds = typeIds.toList()..sort();
    final uri = baseUri
        .resolve('bbox')
        .replace(
          queryParameters: {
            'bbox': bounds.toApiValue(),
            if (sortedTypeIds.isNotEmpty)
              'type_points': sortedTypeIds.join(','),
            'nb_points': '$limit',
            'detail': 'simple',
            'format': 'geojson',
            'format_texte': 'texte',
          },
        );
    return BboxResponse.fromJson(await _getJson(uri));
  }

  @override
  Future<PointDetailsResponse> fetchPointDetails(int id) async {
    if (id < 1) {
      throw RangeError.range(id, 1, null, 'id');
    }

    final uri = baseUri
        .resolve('point')
        .replace(
          queryParameters: {
            'id': '$id',
            'detail': 'complet',
            'format': 'geojson',
            'format_texte': 'texte',
          },
        );
    return PointDetailsResponse.fromJson(await _getJson(uri));
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final response = await _httpClient
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw RefugesInfoApiException(statusCode: response.statusCode);
    }

    final body = utf8.decode(response.bodyBytes);
    final json = jsonDecode(body);
    if (json is! Map<String, Object?>) {
      throw const FormatException('Invalid API response.');
    }
    return json;
  }
}

class RefugesInfoApiException implements Exception {
  const RefugesInfoApiException({required this.statusCode});

  final int statusCode;

  @override
  String toString() => 'Refuges.info API request failed ($statusCode).';
}
