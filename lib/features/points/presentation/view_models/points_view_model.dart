import 'package:flutter/foundation.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class PointsViewModel extends ChangeNotifier {
  PointsViewModel(this._repository);

  final PointsRepository _repository;

  PointsState _state = const PointsInitial();
  PointsState get state => _state;

  GeographicBounds? _lastBounds;
  var _requestId = 0;
  var _isDisposed = false;

  Future<void> load(GeographicBounds bounds) async {
    _lastBounds = bounds;
    final requestId = ++_requestId;
    _setState(const PointsLoading());

    try {
      final points = await _repository.getPointsInBounds(bounds);
      if (_isCurrent(requestId)) {
        _setState(
          points.isEmpty ? const PointsEmpty() : PointsLoaded(points: points),
        );
      }
    } on PointsConnectionException catch (_) {
      if (_isCurrent(requestId)) {
        _setState(const PointsOffline());
      }
    } on PointsDataException catch (_) {
      if (_isCurrent(requestId)) {
        _setState(const PointsFailure());
      }
    }
  }

  Future<void> retry() async {
    final bounds = _lastBounds;
    if (bounds != null) {
      await load(bounds);
    }
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
  PointsLoaded({required List<PointOfInterest> points})
    : points = List.unmodifiable(points);

  final List<PointOfInterest> points;
}

class PointsEmpty extends PointsState {
  const PointsEmpty();
}

class PointsOffline extends PointsState {
  const PointsOffline();
}

class PointsFailure extends PointsState {
  const PointsFailure();
}
