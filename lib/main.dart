import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/supabase_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/state/auth_scope.dart';
import 'features/places/data/places_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnvironment();

  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
    );
  } on Exception {
    throw StateError('Could not initialize Supabase. Check config.json.');
  }

  final client = Supabase.instance.client;
  final places = PlacesRepository.supabase(client);
  runApp(
    AuthScope(
      repository: AuthRepository.supabase(client),
      child: SacredCompassApp(loadPlaces: places.fetchPublishedPlaces),
    ),
  );
}
