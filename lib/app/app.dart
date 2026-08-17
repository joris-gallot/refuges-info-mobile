import 'package:flutter/material.dart';
import 'package:refuges_info_mobile/features/home/presentation/home_page.dart';

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
      home: const HomePage(),
    );
  }
}
