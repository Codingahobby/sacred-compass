import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/supabase_config.dart';
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

  final repository = PlacesRepository.supabase(Supabase.instance.client);
  runApp(SacredCompassApp(loadPlaces: repository.fetchPublishedPlaces));
}
