import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

enum RegistrationResult { signedIn, confirmationRequired }

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

class AuthRepository {
  AuthRepository(this._auth, this._loadProfile);

  factory AuthRepository.supabase(SupabaseClient client) => AuthRepository(
    client.auth,
    (id) async => await client
        .schema('public')
        .from('profiles')
        .select('id, display_name, avatar_path, created_at, updated_at')
        .eq('id', id)
        .maybeSingle(),
  );

  final GoTrueClient _auth;
  final Future<Map<String, dynamic>?> Function(String id) _loadProfile;

  User? get currentUser => _auth.currentUser;
  Session? get currentSession => _auth.currentSession;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<RegistrationResult> register({
    required String email,
    required String password,
  }) async {
    const failure = AuthFailure(
      'Could not register. Check your details and try again.',
    );
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) return RegistrationResult.signedIn;
      if (response.user != null) return RegistrationResult.confirmationRequired;
    } on Exception {
      throw failure;
    }
    throw failure;
  }

  Future<User> signIn({required String email, required String password}) async {
    const failure = AuthFailure('Could not sign in. Please try again.');
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = response.session;
      if (session != null) return session.user;
    } on AuthException catch (error) {
      throw switch (error.code) {
        'invalid_credentials' => const AuthFailure(
          'The email or password is incorrect.',
        ),
        'email_not_confirmed' => const AuthFailure(
          'Confirm your email before signing in.',
        ),
        _ => failure,
      };
    } on Exception {
      throw failure;
    }
    throw failure;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Exception {
      throw const AuthFailure('Could not complete sign-out. Please try again.');
    }
  }

  Future<Profile?> fetchCurrentProfile() async {
    final id = currentSession?.user.id;
    if (id == null) return null;

    try {
      final row = await _loadProfile(id);
      if (row == null || currentSession?.user.id != id) return null;

      final profile = Profile.fromJson(row);
      if (profile.id == id) return profile;
    } on TypeError {
      throw const AuthFailure('The server returned invalid profile data.');
    } on FormatException {
      throw const AuthFailure('The server returned invalid profile data.');
    } on Exception {
      throw const AuthFailure('Could not load your profile. Please try again.');
    }
    throw const AuthFailure('The server returned invalid profile data.');
  }
}
