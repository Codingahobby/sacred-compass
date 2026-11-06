import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/state/auth_scope.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/places/models/place.dart';
import '../../features/places/presentation/places_screen.dart';

class AppRouter {
  static const discovery = '/discover';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const forgotPassword = '/forgot-password';

  static Map<String, WidgetBuilder> routes(
    Future<List<Place>> Function() loadPlaces,
  ) => {
    Navigator.defaultRouteName: (context) {
      if (AuthScope.maybeOf(context)?.user != null) {
        return PlacesScreen(loadPlaces: loadPlaces);
      }
      return WelcomeScreen(
        onExplore: () => Navigator.of(context).pushNamed(discovery),
        onSignIn: () => Navigator.of(context).pushNamed(signIn),
      );
    },
    discovery: (_) => PlacesScreen(loadPlaces: loadPlaces),
    signIn: (context) => SignInScreen(
      repository: AuthScope.maybeOf(context)?.repository,
      onSignedIn: () =>
          Navigator.of(context)
              .pushNamedAndRemoveUntil(discovery, (_) => false),
      onCreateAccount: () => Navigator.of(context).pushNamed(createAccount),
      onForgotPassword: () => Navigator.of(context).pushNamed(forgotPassword),
    ),
    createAccount: (_) => const _PendingAuthScreen(
      title: 'Create Account',
      message:
          'Temporary development screen. Registration is not available yet.',
    ),
    forgotPassword: (_) => const _PendingAuthScreen(
      title: 'Forgot Password',
      message: 'Temporary development screen. Password recovery is not available yet.',
    ),
  };
}

class _PendingAuthScreen extends StatelessWidget {
  const _PendingAuthScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
