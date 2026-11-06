import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/interaction_helpers.dart';

import 'package:sacred_compass/app/app.dart';
import 'package:sacred_compass/features/auth/data/auth_repository.dart';
import 'package:sacred_compass/features/auth/state/auth_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _user = User(
  id: 'test-user',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-11-05T00:00:00Z',
);

class _AuthRepository extends Fake implements AuthRepository {
  final changes = StreamController<AuthState>.broadcast(sync: true);
  Future<void>? wait;
  Exception? failure;
  int calls = 0;
  String? lastEmail;

  @override
  Session? currentSession;

  @override
  User? get currentUser => currentSession?.user;

  @override
  Stream<AuthState> get authChanges => changes.stream;

  @override
  Future<User> signIn({required String email, required String password}) async {
    calls++;
    lastEmail = email;
    await wait;
    final error = failure;
    if (error != null) throw error;
    currentSession = Session(accessToken: '', tokenType: 'bearer', user: _user);
    changes.add(AuthState(AuthChangeEvent.signedIn, currentSession));
    return _user;
  }
}

Future<void> _openSignIn(
  WidgetTester tester,
  _AuthRepository repository,
) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    AuthScope(
      repository: repository,
      child: SacredCompassApp(loadPlaces: () async => []),
    ),
  );
  final link = find.byKey(const Key('welcome-sign-in'));
  await revealForInteraction(tester, link);
  await tester.tap(link);
  await tester.pumpAndSettle();
  expect(find.text('Welcome back'), findsOneWidget);
  expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
  expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
}

Future<void> _enterDetails(WidgetTester tester) async {
  await revealForInteraction(tester, find.byKey(const Key('sign-in-email')));
  await tester.enterText(
    find.byKey(const Key('sign-in-email')),
    ' guest@example.com ',
  );
  await revealForInteraction(tester, find.byKey(const Key('sign-in-password')));
  await tester.enterText(
    find.byKey(const Key('sign-in-password')),
    'fixture-password',
  );
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.byKey(const Key('sign-in-submit'));
  await revealForInteraction(tester, button);
  await tester.tap(button);
}

void main() {
  late _AuthRepository repository;

  setUp(() => repository = _AuthRepository());
  tearDown(() async => repository.changes.close());

  testWidgets('validates empty and malformed fields before calling auth', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    await _submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repository.calls, 0);

    await revealForInteraction(tester, find.byKey(const Key('sign-in-email')));
    await tester.enterText(find.byKey(const Key('sign-in-email')), 'invalid');
    await _submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('successful sign-in establishes a session and opens discovery', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(repository.lastEmail, 'guest@example.com');
    expect(repository.currentSession?.user.id, _user.id);
    expect(find.text('No published places found.'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(Scaffold))).canPop(),
      isFalse,
    );
  });

  testWidgets('invalid credentials stay on the form with a safe message', (
    tester,
  ) async {
    repository.failure = const AuthFailure(
      'The email or password is incorrect.',
    );
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(repository.currentSession, isNull);
  });

  testWidgets(
    'an unexpected error is sanitized and submission can be retried',
    (tester) async {
      repository.failure = Exception('Raw response details');
      await _openSignIn(tester, repository);
      await _enterDetails(tester);
      await _submit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Could not sign in. Please try again.'), findsOneWidget);
      expect(find.text('Raw response details'), findsNothing);
      repository.failure = null;
      await _submit(tester);
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('No published places found.'), findsOneWidget);
    },
  );

  testWidgets('loading prevents duplicate submission', (tester) async {
    final pending = Completer<void>();
    repository.wait = pending.future;
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    await _submit(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('sign-in-submit')))
          .onPressed,
      isNull,
    );
    await _submit(tester);
    await tester.pump();
    expect(repository.calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('No published places found.'), findsOneWidget);
  });

  testWidgets('password visibility is controllable', (tester) async {
    await _openSignIn(tester, repository);
    final field = find.byKey(const Key('sign-in-password'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );
    await revealForInteraction(
      tester,
      find.byKey(const Key('password-visibility')),
    );
    await tester.tap(find.byKey(const Key('password-visibility')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .obscureText,
      isFalse,
    );
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('links open identified development destinations and return', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    final forgot = find.text('Forgot Password?');
    await revealForInteraction(tester, forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Temporary development screen. Password recovery is not available yet.',
      ),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    final create = find.textContaining('Create an account', findRichText: true);
    await revealForInteraction(tester, create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Temporary development screen. Registration is not available yet.',
      ),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    final heading = find.text('Welcome back');
    await revealForInteraction(tester, heading);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(find.text('Find places that move you.'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('OAuth controls are visibly pending and disabled', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    final socialButtons = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(socialButtons, hasLength(2));
    expect(socialButtons.every((button) => button.onPressed == null), isTrue);
    expect(find.text('Google and Apple sign-in are pending.'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('form remains usable with a keyboard and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    await _submit(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repository.calls, 1);
  });

  testWidgets('input survives returning from a development destination', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    final forgot = find.text('Forgot Password?');
    await revealForInteraction(tester, forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('sign-in-email')),
        matching: find.byType(TextField),
      ),
    );
    expect(email.controller!.text, ' guest@example.com ');
    expect(repository.calls, 0);
  });

  testWidgets('input survives backgrounding and layout changes', (
    tester,
  ) async {
    await _openSignIn(tester, repository);
    await _enterDetails(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    try {
      expect(tester.binding.lifecycleState, AppLifecycleState.paused);
      await tester.pump();
    } finally {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2.5;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    final email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('sign-in-email')),
        matching: find.byType(TextField),
      ),
    );
    expect(email.controller!.text, ' guest@example.com ');
    final visibility = find.byKey(const Key('password-visibility'));
    await revealForInteraction(tester, visibility);
    expect(tester.getSize(visibility).height, greaterThanOrEqualTo(44));
    await tester.tap(visibility);
    await tester.pumpAndSettle();
    expect(find.text('Hide'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(repository.calls, 0);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 2.5),
    (const Size(412, 892), 2.0),
  ]) {
    testWidgets('Sign In fits $size at text scale $scale and can submit', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openSignIn(tester, repository);

      final separator = find.text('OR CONTINUE WITH');
      await revealForInteraction(tester, separator);
      expect(separator.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _enterDetails(tester);
      await _submit(tester);
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      expect(find.text('No published places found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
