import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

enum AuthStatus { initializing, guest, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController(this.repository);

  final AuthRepository repository;
  StreamSubscription<AuthState>? _subscription;
  AuthStatus _status = AuthStatus.initializing;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;
  AuthFailure? get error => _status == AuthStatus.error
      ? const AuthFailure(
          'Could not refresh authentication. Check your connection.',
        )
      : null;

  void start() {
    if (_subscription != null) return;
    _subscription = repository.authChanges.listen(
      (change) => _updateUser(change.session?.user),
      onError: (Object _, StackTrace _) {
        _status = AuthStatus.error;
        notifyListeners();
      },
    );

    // Supabase.initialize has already restored the persisted session, if any.
    if (_status == AuthStatus.initializing) {
      _updateUser(repository.currentSession?.user);
    }
  }

  void _updateUser(User? user) {
    _user = user;
    _status = user == null ? AuthStatus.guest : AuthStatus.authenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
