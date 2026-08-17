import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/domain/models/geographic_bounds.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';
import 'package:refuges_info_mobile/features/points/presentation/view_models/points_view_model.dart';
import 'package:refuges_info_mobile/features/points/presentation/views/points_page.dart';

class RefugesInfoApp extends StatelessWidget {
  const RefugesInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refuges Info Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C4C)),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) {
          final viewModel = PointsViewModel(context.read<PointsRepository>());
          unawaited(viewModel.load(_initialBounds));
          return viewModel;
        },
        child: const PointsPage(),
      ),
    );
  }
}

final _initialBounds = GeographicBounds(
  west: 5.5,
  south: 44.8,
  east: 6.2,
  north: 45.5,
);
