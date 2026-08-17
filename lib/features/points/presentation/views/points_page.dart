import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/points_view_model.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PointsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Refuges Info Mobile')),
      body: SafeArea(
        child: switch (viewModel.state) {
          PointsInitial() ||
          PointsLoading() => const Center(child: CircularProgressIndicator()),
          PointsLoaded(:final points) => _PointsList(
            points: points,
            onRefresh: viewModel.retry,
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
