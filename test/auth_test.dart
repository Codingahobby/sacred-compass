import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sacred_compass/features/auth/data/auth_repository.dart';
import 'package:sacred_compass/features/auth/state/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const user = User(
  id: 'test-user',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-11-04T00:00:00Z',
);

final session = Session(accessToken: '', tokenType: 'bearer', user: user);

class FakeAuth extends Fake implements GoTrueClient {
  final changes = StreamController<AuthState>.broadcast(sync: true);
  AuthResponse? registration;
  AuthException? loginFailure;
  String? lastEmail;

  @override
  Session? currentSession;

  @override
  User? get currentUser => currentSession?.user;

  @override
  Stream<AuthState> get onAuthStateChange => changes.stream;

  void emit(AuthChangeEvent event, Session? session) {
    currentSession = session;
    changes.add(AuthState(event, session));
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    lastEmail = email;
    final response = registration!;
    if (response.session != null) {
      emit(AuthChangeEvent.signedIn, response.session);
    }
    return response;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    lastEmail = email;
    final failure = loginFailure;
    if (failure != null) throw failure;
    emit(AuthChangeEvent.signedIn, session);
    return AuthResponse(session: session);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    emit(AuthChangeEvent.signedOut, null);
  }
}

void main() {
  late FakeAuth auth;
  late AuthRepository repository;
  late AuthController controller;
  late Future<Map<String, dynamic>?> Function(String) loadProfile;

  setUp(() {
    auth = FakeAuth();
    loadProfile = (_) async => null;
    repository = AuthRepository(auth, (id) => loadProfile(id));
    controller = AuthController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await auth.changes.close();
  });

  test('starts initializing and becomes a guest without a session', () {
    expect(controller.status, AuthStatus.initializing);
    controller.start();
    expect(controller.status, AuthStatus.guest);
    expect(repository.currentSession, isNull);
    expect(repository.currentUser, isNull);
  });

  test('restores the current session from the SDK', () {
    auth.currentSession = session;
    controller.start();
    expect(controller.status, AuthStatus.authenticated);
    expect(controller.user, same(user));
    expect(repository.currentSession, same(session));
  });

  test('registration reports an immediate session when supplied', () async {
    auth.registration = AuthResponse(session: session);
    controller.start();
    final result = await repository.register(
      email: ' guest@example.com ',
      password: 'fixture-password',
    );
    expect(result, RegistrationResult.signedIn);
    expect(auth.lastEmail, 'guest@example.com');
    expect(controller.status, AuthStatus.authenticated);
  });

  test('registration without a session requires confirmation', () async {
    auth.registration = AuthResponse(user: user);
    controller.start();
    final result = await repository.register(
      email: 'guest@example.com',
      password: 'fixture-password',
    );
    expect(result, RegistrationResult.confirmationRequired);
    expect(controller.status, AuthStatus.guest);
    expect(repository.currentUser, isNull);
  });

  test('sign-in and sign-out update session state', () async {
    controller.start();
    final signedInUser = await repository.signIn(
      email: 'guest@example.com',
      password: 'fixture-password',
    );
    expect(signedInUser, same(user));
    expect(repository.currentUser, same(user));
    expect(controller.status, AuthStatus.authenticated);

    await repository.signOut();
    expect(repository.currentSession, isNull);
    expect(controller.user, isNull);
    expect(controller.status, AuthStatus.guest);
  });

  test('failed login returns a safe message and leaves guest state', () async {
    auth.loginFailure = const AuthException(
      'Raw response details',
      code: 'invalid_credentials',
    );
    controller.start();
    await expectLater(
      repository.signIn(
        email: 'guest@example.com',
        password: 'fixture-password',
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'The email or password is incorrect.',
        ),
      ),
    );
    expect(controller.status, AuthStatus.guest);
  });

  test('handles auth stream errors and recovers on the next event', () {
    controller.start();
    auth.changes.addError(StateError('Raw refresh error'));
    expect(controller.status, AuthStatus.error);
    expect(controller.error?.message, contains('Check your connection'));

    auth.emit(AuthChangeEvent.tokenRefreshed, session);
    expect(controller.status, AuthStatus.authenticated);
    expect(controller.error, isNull);
  });

  test('loads and parses the signed-in user profile by ID', () async {
    auth.currentSession = session;
    loadProfile = (id) async {
      expect(id, user.id);
      return {
        'id': id,
        'display_name': 'Test Visitor',
        'avatar_path': null,
        'created_at': '2026-11-04T00:00:00Z',
        'updated_at': '2026-11-04T01:00:00Z',
      };
    };

    final profile = (await repository.fetchCurrentProfile())!;
    expect(profile.id, user.id);
    expect(profile.displayName, 'Test Visitor');
    expect(profile.avatarPath, isNull);
    expect(profile.createdAt, DateTime.utc(2026, 11, 4));
    expect(profile.updatedAt, DateTime.utc(2026, 11, 4, 1));
  });

  test('guests do not query profiles', () async {
    loadProfile = (_) async => fail('Guest made a profile request');
    expect(await repository.fetchCurrentProfile(), isNull);
  });

  test('discards an in-flight profile result after sign-out', () async {
    auth.currentSession = session;
    final response = Completer<Map<String, dynamic>?>();
    loadProfile = (_) => response.future;
    final pending = repository.fetchCurrentProfile();

    auth.currentSession = null;
    response.complete({'id': user.id});
    expect(await pending, isNull);
  });
}
