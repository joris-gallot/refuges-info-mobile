import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_details.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/point_details_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

typedef PointWebsiteLauncher = Future<bool> Function(Uri website);

class PointDetailsPage extends StatelessWidget {
  const PointDetailsPage({
    super.key,
    required this.summary,
    this.launchWebsite = _launchWebsite,
  });

  final PointOfInterest summary;
  final PointWebsiteLauncher launchWebsite;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PointDetailsViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(summary.name)),
      body: SafeArea(
        child: switch (viewModel.state) {
          PointDetailsInitial() || PointDetailsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PointDetailsLoaded(:final details) => _PointDetailsContent(
            details: details,
            launchWebsite: launchWebsite,
          ),
          PointDetailsOffline() => _DetailsMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Connexion indisponible',
            message: 'La fiche détaillée n’est pas disponible hors ligne.',
            onRetry: viewModel.load,
          ),
          PointDetailsFailure() => _DetailsMessage(
            icon: Icons.error_outline,
            title: 'Fiche indisponible',
            message: 'Les détails de ce point n’ont pas pu être chargés.',
            onRetry: viewModel.load,
          ),
        },
      ),
    );
  }
}

class _PointDetailsContent extends StatelessWidget {
  const _PointDetailsContent({
    required this.details,
    required this.launchWebsite,
  });

  final PointDetails details;
  final PointWebsiteLauncher launchWebsite;

  @override
  Widget build(BuildContext context) {
    final point = details.point;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(point.type.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _facts(point)),
        const SizedBox(height: 24),
        if (details.remarks case final remarks?) ...[
          _DetailsSection(
            icon: Icons.info_outline,
            title: 'Remarques',
            child: Text(remarks),
          ),
          const SizedBox(height: 24),
        ],
        if (details.access case final access?) ...[
          _DetailsSection(
            icon: Icons.directions_walk_outlined,
            title: 'Accès',
            child: Text(access),
          ),
          const SizedBox(height: 24),
        ],
        if (details.owner case final owner?) ...[
          _DetailsSection(
            icon: Icons.contact_page_outlined,
            title: owner.label,
            child: Text(owner.value),
          ),
          const SizedBox(height: 24),
        ],
        if (details.information.isNotEmpty) ...[
          _DetailsSection(
            icon: Icons.checklist_outlined,
            title: 'Équipements et services',
            child: Column(
              children: [
                for (final information in details.information)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(information.label),
                    trailing: Text(
                      information.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        _DetailsSection(
          icon: Icons.location_on_outlined,
          title: 'Localisation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${point.latitude.toStringAsFixed(5)}, '
                '${point.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 4),
              Text(details.coordinatePrecision),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DetailsSection(
          icon: Icons.history_outlined,
          title: 'Contribution',
          child: Text(
            'Ajouté par ${details.creatorName} le '
            '${_formatDate(details.createdAt)}. '
            'Dernière mise à jour le ${_formatDate(details.updatedAt)}.',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _openWebsite(context),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Voir sur Refuges.info'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Données Refuges.info sous licence CC BY-SA 2.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _facts(PointOfInterest point) {
    return [
      if (point.altitude case final altitude?)
        Chip(
          avatar: const Icon(Icons.terrain, size: 18),
          label: Text('$altitude m'),
        ),
      if (point.sleepingPlaces case final places?)
        Chip(
          avatar: const Icon(Icons.bed_outlined, size: 18),
          label: Text(places == 1 ? '1 place' : '$places places'),
        ),
      if (point.state case final state?)
        Chip(
          avatar: const Icon(Icons.info_outline, size: 18),
          label: Text(state),
        ),
    ];
  }

  Future<void> _openWebsite(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchWebsite(details.point.website);
    } on Exception catch (_) {}
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir Refuges.info.')),
      );
    }
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({
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

Future<bool> _launchWebsite(Uri website) {
  return launchUrl(website, mode: LaunchMode.externalApplication);
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}
