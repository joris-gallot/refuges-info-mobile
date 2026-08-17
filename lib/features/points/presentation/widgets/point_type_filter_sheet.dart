import 'package:flutter/material.dart';
import 'package:refuges_info_mobile/features/points/domain/models/point_of_interest.dart';

class PointTypeFilterSheet extends StatefulWidget {
  const PointTypeFilterSheet({
    super.key,
    required this.types,
    required this.selectedTypeIds,
    required this.onApply,
  });

  final List<PointOfInterestType> types;
  final Set<int> selectedTypeIds;
  final ValueChanged<Set<int>> onApply;

  @override
  State<PointTypeFilterSheet> createState() => _PointTypeFilterSheetState();
}

class _PointTypeFilterSheetState extends State<PointTypeFilterSheet> {
  late Set<int> _selectedTypeIds;

  @override
  void initState() {
    super.initState();
    _selectedTypeIds = {...widget.selectedTypeIds};
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedTypeIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Types de points',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Sélectionnez les types à afficher sur la carte.'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Tout sélectionner'),
                ),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Tout désélectionner'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in widget.types)
                    FilterChip(
                      key: ValueKey('point-type-${type.id}'),
                      label: Text(type.name),
                      selected: _selectedTypeIds.contains(type.id),
                      onSelected: (selected) => _toggle(type.id, selected),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedCount == 1
                ? '1 type sélectionné'
                : '$selectedCount types sélectionnés',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedCount == 0
                  ? null
                  : () => widget.onApply(Set.unmodifiable(_selectedTypeIds)),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedTypeIds = {for (final type in widget.types) type.id};
    });
  }

  void _clear() {
    setState(_selectedTypeIds.clear);
  }

  void _toggle(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedTypeIds.add(id);
      } else {
        _selectedTypeIds.remove(id);
      }
    });
  }
}
