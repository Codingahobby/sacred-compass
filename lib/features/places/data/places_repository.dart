import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlacesRepository {
  PlacesRepository(this._fetchRows);

  factory PlacesRepository.supabase(SupabaseClient client) {
    return PlacesRepository(
      () async => await client
          .schema('public')
          .from('places')
          .select('id, slug, name, summary, country, region, status')
          .eq('status', 'published')
          .order('name')
          .order('id'),
    );
  }

  final Future<List<Map<String, dynamic>>> Function() _fetchRows;

  Future<List<Place>> fetchPublishedPlaces() async {
    try {
      final rows = await _fetchRows().timeout(const Duration(seconds: 15));
      return rows.map(Place.fromJson).toList(growable: false);
    } on FormatException {
      throw const PlacesLoadException(
        'The server returned invalid place data.',
      );
    } on TypeError {
      throw const PlacesLoadException(
        'The server returned invalid place data.',
      );
    } on Exception {
      throw const PlacesLoadException(
        'Could not load places. Check your connection and try again.',
      );
    }
  }
}

class PlacesLoadException implements Exception {
  const PlacesLoadException(this.message);

  final String message;
}
