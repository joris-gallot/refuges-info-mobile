import 'package:flutter/foundation.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class PointDetailsViewModel extends ChangeNotifier {
  PointDetailsViewModel(this._repository, this.pointId);

  final PointsRepository _repository;
  final int pointId;

  PointDetailsState _state = const PointDetailsInitial();
  PointDetailsState get state => _state;

  var _isDisposed = false;

  Future<void> load() async {
    _setState(const PointDetailsLoading());
    try {
      final details = await _repository.getPointDetails(pointId);
      _setState(PointDetailsLoaded(details));
    } on PointsConnectionException catch (_) {
      _setState(const PointDetailsOffline());
    } on PointsDataException catch (_) {
      _setState(const PointDetailsFailure());
    }
  }

  void _setState(PointDetailsState value) {
    if (_isDisposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

sealed class PointDetailsState {
  const PointDetailsState();
}

class PointDetailsInitial extends PointDetailsState {
  const PointDetailsInitial();
}

class PointDetailsLoading extends PointDetailsState {
  const PointDetailsLoading();
}

class PointDetailsLoaded extends PointDetailsState {
  const PointDetailsLoaded(this.details);

  final PointDetails details;
}

class PointDetailsOffline extends PointDetailsState {
  const PointDetailsOffline();
}

class PointDetailsFailure extends PointDetailsState {
  const PointDetailsFailure();
}
