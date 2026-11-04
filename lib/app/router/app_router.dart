import 'package:flutter/material.dart';

import '../../features/places/models/place.dart';
import '../../features/places/presentation/places_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes(
    Future<List<Place>> Function() loadPlaces,
  ) => {
    Navigator.defaultRouteName: (_) => PlacesScreen(loadPlaces: loadPlaces),
  };
}
