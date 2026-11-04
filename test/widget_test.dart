import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacred_compass/app/app.dart';
import 'package:sacred_compass/features/places/data/places_repository.dart';
import 'package:sacred_compass/features/places/models/place.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Shows empty results in ${brightness.name} mode', (
      tester,
    ) async {
      final dispatcher = tester.platformDispatcher;
      dispatcher.platformBrightnessTestValue = brightness;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
      await tester.pumpAndSettle();

      final title = find.text('Sacred Compass');
      expect(title, findsOneWidget);
      expect(Theme.of(tester.element(title)).brightness, brightness);
      expect(find.text('No published places found.'), findsOneWidget);
    });
  }

  testWidgets('Shows loading, then an error, and retries successfully', (
    tester,
  ) async {
    final firstLoad = Completer<List<Place>>();
    final retry = Completer<List<Place>>();
    var requests = 0;
    await tester.pumpWidget(
      SacredCompassApp(
        loadPlaces: () => requests++ == 0 ? firstLoad.future : retry.future,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    firstLoad.completeError(const PlacesLoadException('Connection failed.'));
    await tester.pumpAndSettle();
    expect(find.text('Connection failed.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retry.complete(const [
      Place(
        id: 'test-id',
        slug: 'example',
        name: 'Example Place',
        summary: 'Example summary',
        country: 'Kenya',
        region: 'Coast',
        status: 'published',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Example Place'), findsOneWidget);
    expect(find.text('Example summary\nKenya · Coast'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
