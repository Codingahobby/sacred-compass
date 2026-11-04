import 'package:flutter/material.dart';

import '../placeholder_home_screen.dart';

class AppRouter {
  static final routes = <String, WidgetBuilder>{
    Navigator.defaultRouteName: (_) => const PlaceholderHomeScreen(),
  };
}
