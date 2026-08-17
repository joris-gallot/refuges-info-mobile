import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/points_view_model.dart';
import 'package:refuges_info_mobile/features/points/presentation/views/points_map.dart';
import 'package:refuges_info_mobile/features/points/presentation/widgets/point_type_filter_sheet.dart';

typedef PointsMapBuilder = Widget Function(
  List<PointOfInterest> points,
  Future<void> Function(GeographicBounds bounds) onViewportChanged,
);

class PointsPage extends StatefulWidget {
  const PointsPage({super.key, this.mapBuilder});

  final PointsMapBuilder? mapBuilder;

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  var _showMap = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PointsViewModel>();
    final hasPoints = viewModel.state is PointsLoaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refuges Info Mobile'),
        actions: [
          if (hasPoints) ...[
            IconButton(
              tooltip: 'Filtrer les types de points',
              onPressed: () => _showTypeFilters(viewModel),
              icon: Badge(
                isLabelVisible: viewModel.hasActiveTypeFilter,
                child: Icon(
                  viewModel.hasActiveTypeFilter
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
              ),
            ),
            IconButton(
              tooltip: _showMap ? 'Afficher la liste' : 'Afficher la carte',
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (viewModel.state) {
          PointsInitial() ||
          PointsLoading() => const Center(child: CircularProgressIndicator()),
          PointsLoaded(
            :final points,
            :final isRefreshing,
            :final refreshFailure,
          ) =>
            _LoadedPoints(
              isRefreshing: isRefreshing,
              refreshFailure: refreshFailure,
              onRetry: viewModel.retry,
              child: _showMap
                  ? widget.mapBuilder?.call(points, viewModel.load) ??
                        PointsMap(
                          points: points,
                          onViewportChanged: viewModel.load,
                        )
                  : _PointsList(points: points, onRefresh: viewModel.retry),
            ),
          PointsEmpty() => _MessageView(
            icon: Icons.landscape_outlined,
            title: 'Aucun point trouvé',
            message: 'Aucun point d’intérêt n’est disponible dans cette zone.',
            onRetry: viewModel.retry,
          ),
          PointsOffline() => _MessageView(
            icon: Icons.cloud_off_outlined,
            title: 'Connexion indisponible',
            message: 'Vérifiez votre connexion avant de réessayer.',
            onRetry: viewModel.retry,
          ),
          PointsFailure() => _MessageView(
            icon: Icons.error_outline,
            title: 'Chargement impossible',
            message: 'Les données Refuges.info ne sont pas disponibles.',
            onRetry: viewModel.retry,
          ),
        },
      ),
    );
  }

  Future<void> _showTypeFilters(PointsViewModel viewModel) async {
    final selectedTypeIds = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.65,
        child: PointTypeFilterSheet(
          types: supportedPointTypes,
          selectedTypeIds: viewModel.selectedTypeIds,
          onApply: (selection) => Navigator.pop(sheetContext, selection),
        ),
      ),
    );
    if (!mounted || selectedTypeIds == null) {
      return;
    }
    await viewModel.setSelectedTypeIds(selectedTypeIds);
  }
}

class _LoadedPoints extends StatelessWidget {
  const _LoadedPoints({
    required this.isRefreshing,
    required this.refreshFailure,
    required this.onRetry,
    required this.child,
  });

  final bool isRefreshing;
  final PointsRefreshFailure? refreshFailure;
  final Future<void> Function() onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (isRefreshing)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
        if (refreshFailure case final failure?)
          Align(
            alignment: Alignment.topCenter,
            child: _RefreshFailureBanner(failure: failure, onRetry: onRetry),
          ),
      ],
    );
  }
}

class _RefreshFailureBanner extends StatelessWidget {
  const _RefreshFailureBanner({required this.failure, required this.onRetry});

  final PointsRefreshFailure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      PointsRefreshFailure.offline =>
        'Carte hors ligne. Points précédents conservés.',
      PointsRefreshFailure.data => 'Impossible d’actualiser les points.',
    };

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _PointsList extends StatelessWidget {
  const _PointsList({required this.points, required this.onRefresh});

  final List<PointOfInterest> points;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: points.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == points.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Données Refuges.info sous licence CC BY-SA 2.0',
                textAlign: TextAlign.center,
              ),
            );
          }

          final point = points[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            leading: const CircleAvatar(child: Icon(Icons.hiking)),
            title: Text(point.name),
            subtitle: Text(_pointDetails(point)),
          );
        },
      ),
    );
  }

  String _pointDetails(PointOfInterest point) {
    final details = <String>[point.type.name];
    if (point.altitude case final altitude?) {
      details.add('$altitude m');
    }
    if (point.sleepingPlaces case final places?) {
      details.add('$places places');
    }
    if (point.state case final state?) {
      details.add(state);
    }
    return details.join(' - ');
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
