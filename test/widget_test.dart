import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/interaction_helpers.dart';

import 'package:sacred_compass/app/app.dart';
import 'package:sacred_compass/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:sacred_compass/features/onboarding/presentation/widgets/welcome_compass.dart';
import 'package:sacred_compass/features/places/presentation/places_screen.dart';
import 'package:sacred_compass/features/places/data/places_repository.dart';
import 'package:sacred_compass/features/places/models/place.dart';

Future<void> _openGuestDiscovery(WidgetTester tester) async {
  final explore = find.text('Begin exploring');
  await revealForInteraction(tester, explore);
  await tester.tap(explore);
  await tester.pumpAndSettle();
  expect(find.byType(PlacesScreen), findsOneWidget);
}

void _disableMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  testWidgets('renders the Welcome content with reduced motion', (
    tester,
  ) async {
    _disableMotion(tester);
    await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
    await tester.pumpAndSettle();

    expect(find.text('YOUR JOURNEY HAS A DIRECTION'), findsOneWidget);
    expect(find.text('Find places that move you.'), findsOneWidget);
    expect(
      find.text(
        'Sacred sites, hidden history and unforgettable '
        'stops—mapped around the way you travel.',
      ),
      findsOneWidget,
    );
    for (final text in ['+ SACRED', 'HIDDEN HISTORY', 'TRIP READY', 'Kenya']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the sign-in route and can return', (tester) async {
    _disableMotion(tester);
    await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
    final signIn = find.byKey(const Key('welcome-sign-in'));
    await revealForInteraction(tester, signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await revealForInteraction(tester, find.text('Welcome back'));
    await tester.tap(find.text('Welcome back'));
    await tester.pumpAndSettle();
    expect(find.text('Find places that move you.'), findsOneWidget);
  });

  testWidgets(
    'guest discovery is reachable on a short viewport with large text',
    (tester) async {
      _disableMotion(tester);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
      await _openGuestDiscovery(tester);
      expect(find.text('No published places found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('Shows empty results in ${brightness.name} mode', (
      tester,
    ) async {
      _disableMotion(tester);
      final dispatcher = tester.platformDispatcher;
      dispatcher.platformBrightnessTestValue = brightness;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
      await _openGuestDiscovery(tester);

      final title = find.text('Sacred Compass');
      expect(title, findsOneWidget);
      expect(Theme.of(tester.element(title)).brightness, brightness);
      expect(find.text('No published places found.'), findsOneWidget);
    });
  }

  testWidgets('Shows loading, then an error, and retries successfully', (
    tester,
  ) async {
    _disableMotion(tester);
    final firstLoad = Completer<List<Place>>();
    final retry = Completer<List<Place>>();
    var requests = 0;
    await tester.pumpWidget(
      SacredCompassApp(
        loadPlaces: () => requests++ == 0 ? firstLoad.future : retry.future,
      ),
    );
    final explore = find.text('Begin exploring');
    await revealForInteraction(tester, explore);
    await tester.tap(explore);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    firstLoad.completeError(const PlacesLoadException('Connection failed.'));
    await tester.pumpAndSettle();
    expect(find.text('Connection failed.'), findsOneWidget);

    await revealForInteraction(tester, find.text('Retry'));
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

  for (final (platform, size) in [
    (TargetPlatform.iOS, const Size(320, 568)),
    (TargetPlatform.iOS, const Size(390, 844)),
    (TargetPlatform.android, const Size(412, 892)),
    (TargetPlatform.android, const Size(600, 900)),
  ]) {
    testWidgets(
      'Welcome actions remain reachable on $platform at $size with large text',
      (tester) async {
        _disableMotion(tester);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        var explores = 0;
        var signIns = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            home: WelcomeScreen(
              onExplore: () => explores++,
              onSignIn: () => signIns++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final explore = find.text('Begin exploring');
        await revealForInteraction(tester, explore);
        await tester.tap(explore);
        final signIn = find.byKey(const Key('welcome-sign-in'));
        await revealForInteraction(tester, signIn);
        await tester.tap(signIn);
        expect(explores, 1);
        expect(signIns, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('switching on reduced motion stops the compass ticker', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeCompass(androidLayout: false)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery errors and retry remain usable in short landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 240);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PlacesScreen(
          loadPlaces: () async {
            calls++;
            if (calls == 1) {
              throw const PlacesLoadException(
                'Could not load places. Check your connection and try again.',
              );
            }
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.text('Retry');
    await revealForInteraction(tester, retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No published places found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'discovery keeps its scroll position across ordinary navigation',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PlacesScreen(
            loadPlaces: () async {
              calls++;
              return List.generate(
                30,
                (index) => Place(
                  id: '$index',
                  slug: 'place-$index',
                  name: 'Place $index',
                  country: 'Kenya',
                  status: 'published',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      final offset = scroll.position.pixels;
      expect(offset, greaterThan(0));

      final navigator = Navigator.of(tester.element(find.byType(PlacesScreen)));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Temporary test route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();

      expect(scroll.position.pixels, offset);
      expect(calls, 1);
    },
  );

  testWidgets(
    'Welcome sign-in is reachable by dragging while the compass loops',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(SacredCompassApp(loadPlaces: () async => []));
      await tester.pump(const Duration(milliseconds: 100));

      final link = find.byKey(const Key('welcome-sign-in'));
      expect(link, findsOneWidget);
      expect(link.hitTestable(), findsNothing);
      await tester.dragUntilVisible(
        link.hitTestable(),
        find.byType(Scrollable),
        const Offset(0, -180),
        maxIteration: 20,
      );
      await tester.pump();
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scroll.position.pixels, greaterThan(0));
      expect(link.hitTestable(), findsOneWidget);
      await tester.tap(link);
      // Advance the route transition without waiting for the looping illustration.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    },
  );
}
