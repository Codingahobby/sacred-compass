import 'package:flutter/material.dart';

import '../features/places/models/place.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SacredCompassApp extends StatelessWidget {
  const SacredCompassApp({required this.loadPlaces, super.key});

  final Future<List<Place>> Function() loadPlaces;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sacred Compass',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routes: AppRouter.routes(loadPlaces),
    );
  }
}
