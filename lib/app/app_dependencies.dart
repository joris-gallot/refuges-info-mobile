import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:refuges_info_mobile/features/points/data/repositories/remote_points_repository.dart';
import 'package:refuges_info_mobile/features/points/data/services/refuges_info_api_client.dart';
import 'package:refuges_info_mobile/features/points/domain/repositories/points_repository.dart';

class AppDependencies extends StatelessWidget {
  const AppDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider<RefugesInfoApi>(
          create: (context) => RefugesInfoApiClient(context.read()),
        ),
        Provider<PointsRepository>(
          create: (context) => RemotePointsRepository(context.read()),
        ),
      ],
      child: child,
    );
  }
}
