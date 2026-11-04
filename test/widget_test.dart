import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacred_compass/main.dart' as app;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Launches the home screen in ${brightness.name} mode', (
      tester,
    ) async {
      final dispatcher = tester.platformDispatcher;
      dispatcher.platformBrightnessTestValue = brightness;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);

      app.main();
      await tester.pumpAndSettle();

      final homeTitle = find.text('Sacred Compass');
      expect(homeTitle, findsOneWidget);
      expect(Theme.of(tester.element(homeTitle)).brightness, brightness);
    });
  }
}
