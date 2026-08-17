import 'package:flutter/foundation.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class PointsViewModel extends ChangeNotifier {
  PointsViewModel(this._repository);

  final PointsRepository _repository;

  static final Set<int> _allTypeIds = Set.unmodifiable(
    supportedPointTypes.map((type) => type.id),
  );

  PointsState _state = const PointsInitial();
  PointsState get state => _state;

  Set<int> _selectedTypeIds = _allTypeIds;
  Set<int> get selectedTypeIds => _selectedTypeIds;
  bool get hasActiveTypeFilter => !setEquals(_selectedTypeIds, _allTypeIds);

  GeographicBounds? _lastBounds;
  var _requestId = 0;
  var _isDisposed = false;

  Future<void> load(GeographicBounds bounds, {bool force = false}) async {
    if (!force && bounds == _lastBounds) {
      return;
    }

    _lastBounds = bounds;
    final requestId = ++_requestId;
    final previousPoints = switch (_state) {
      PointsLoaded(:final points) => points,
      _ => null,
    };

    _setState(
      previousPoints == null
          ? const PointsLoading()
          : PointsLoaded(points: previousPoints, isRefreshing: true),
    );

    try {
      final points = await _repository.getPointsInBounds(
        bounds,
        typeIds: hasActiveTypeFilter ? _selectedTypeIds : const {},
      );
      if (_isCurrent(requestId)) {
        _setState(
          points.isEmpty && previousPoints == null
              ? const PointsEmpty()
              : PointsLoaded(points: points),
        );
      }
    } on PointsConnectionException catch (_) {
      if (_isCurrent(requestId)) {
        _setLoadFailure(
          previousPoints,
          refreshFailure: PointsRefreshFailure.offline,
          initialFailure: const PointsOffline(),
        );
      }
    } on PointsDataException catch (_) {
      if (_isCurrent(requestId)) {
        _setLoadFailure(
          previousPoints,
          refreshFailure: PointsRefreshFailure.data,
          initialFailure: const PointsFailure(),
        );
      }
    }
  }

  Future<void> setSelectedTypeIds(Set<int> typeIds) async {
    if (typeIds.isEmpty || !_allTypeIds.containsAll(typeIds)) {
      throw ArgumentError.value(typeIds, 'typeIds');
    }
    if (setEquals(typeIds, _selectedTypeIds)) {
      return;
    }

    _selectedTypeIds = Set.unmodifiable(typeIds);
    final currentPoints = switch (_state) {
      PointsLoaded(:final points) => points,
      _ => null,
    };
    if (currentPoints != null) {
      _setState(
        PointsLoaded(
          points: currentPoints
              .where((point) => _selectedTypeIds.contains(point.type.id))
              .toList(),
          isRefreshing: _lastBounds != null,
        ),
      );
    }

    final bounds = _lastBounds;
    if (bounds != null) {
      await load(bounds, force: true);
    }
  }

  Future<void> retry() async {
    final bounds = _lastBounds;
    if (bounds != null) {
      await load(bounds, force: true);
    }
  }

  void _setLoadFailure(
    List<PointOfInterest>? previousPoints, {
    required PointsRefreshFailure refreshFailure,
    required PointsState initialFailure,
  }) {
    _setState(
      previousPoints == null
          ? initialFailure
          : PointsLoaded(
              points: previousPoints,
              refreshFailure: refreshFailure,
            ),
    );
  }

  bool _isCurrent(int requestId) {
    return !_isDisposed && requestId == _requestId;
  }

  void _setState(PointsState value) {
    if (_isDisposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestId++;
    super.dispose();
  }
}

sealed class PointsState {
  const PointsState();
}

class PointsInitial extends PointsState {
  const PointsInitial();
}

class PointsLoading extends PointsState {
  const PointsLoading();
}

class PointsLoaded extends PointsState {
  PointsLoaded({
    required List<PointOfInterest> points,
    this.isRefreshing = false,
    this.refreshFailure,
  }) : points = List.unmodifiable(points);

  final List<PointOfInterest> points;
  final bool isRefreshing;
  final PointsRefreshFailure? refreshFailure;
}

enum PointsRefreshFailure { offline, data }

class PointsEmpty extends PointsState {
  const PointsEmpty();
}

class PointsOffline extends PointsState {
  const PointsOffline();
}

class PointsFailure extends PointsState {
  const PointsFailure();
}
