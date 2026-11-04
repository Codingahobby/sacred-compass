import 'package:flutter_test/flutter_test.dart';
import 'package:sacred_compass/features/places/data/places_repository.dart';
import 'package:sacred_compass/features/places/models/place.dart';

const listRow = {
  'id': 'test-id',
  'slug': 'example',
  'name': 'Example Place',
  'country': 'Kenya',
  'status': 'published',
};

void main() {
  test('decodes a full place, including numeric coordinates and dates', () {
    final place = Place.fromJson({
      ...listRow,
      'summary': 'Summary',
      'history': 'History',
      'visitor_guidance': 'Guidance',
      'region': 'Coast',
      'city': 'Example city',
      'address': 'Example address',
      'latitude': -3,
      'longitude': 39.5,
      'published_at': '2026-11-03T00:00:00Z',
      'created_at': '2026-11-01T00:00:00Z',
      'updated_at': '2026-11-02T00:00:00Z',
    });
    expect(place.id, 'test-id');
    expect(place.slug, 'example');
    expect(place.name, 'Example Place');
    expect(place.summary, 'Summary');
    expect(place.history, 'History');
    expect(place.visitorGuidance, 'Guidance');
    expect(place.country, 'Kenya');
    expect(place.region, 'Coast');
    expect(place.city, 'Example city');
    expect(place.address, 'Example address');
    expect(place.latitude, -3.0);
    expect(place.longitude, 39.5);
    expect(place.status, 'published');
    expect(place.publishedAt, DateTime.utc(2026, 11, 3));
    expect(place.createdAt, DateTime.utc(2026, 11, 1));
    expect(place.updatedAt, DateTime.utc(2026, 11, 2));
  });

  test('accepts null fields and fields omitted by the list query', () {
    final place = Place.fromJson({...listRow, 'summary': null, 'region': null});
    expect(place.summary, isNull);
    expect(place.region, isNull);
    expect(place.latitude, isNull);
    expect(place.publishedAt, isNull);
    expect(place.createdAt, isNull);
  });

  test('rejects invalid timestamps', () {
    expect(
      () => Place.fromJson({...listRow, 'created_at': 'invalid'}),
      throwsFormatException,
    );
  });

  test('repository maps a successful response to places', () async {
    final repository = PlacesRepository(() async => [listRow]);
    final places = await repository.fetchPublishedPlaces();
    expect(places.single.name, 'Example Place');
  });

  test('repository preserves empty results', () async {
    final repository = PlacesRepository(() async => []);
    expect(await repository.fetchPublishedPlaces(), isEmpty);
  });

  test('repository reports malformed rows', () async {
    final repository = PlacesRepository(
      () async => [
        {...listRow, 'name': null},
      ],
    );
    await expectLater(
      repository.fetchPublishedPlaces(),
      throwsA(isA<PlacesLoadException>()),
    );
  });

  test('repository reports connection failures without raw details', () async {
    final repository = PlacesRepository(() async => throw Exception('raw'));
    await expectLater(
      repository.fetchPublishedPlaces(),
      throwsA(
        isA<PlacesLoadException>().having(
          (error) => error.message,
          'message',
          'Could not load places. Check your connection and try again.',
        ),
      ),
    );
  });
}
