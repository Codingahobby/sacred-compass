import 'package:flutter/widgets.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';

class AuthScope extends StatefulWidget {
  const AuthScope({required this.repository, required this.child, super.key});

  final AuthRepository repository;
  final Widget child;

  static AuthController of(BuildContext context) => maybeOf(context)!;

  static AuthController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AuthState>()?.notifier;

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> {
  late AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(widget.repository)..start();
  }

  @override
  void didUpdateWidget(AuthScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _controller.dispose();
      _controller = AuthController(widget.repository)..start();
    }
  }

  @override
  Widget build(BuildContext context) =>
      _AuthState(notifier: _controller, child: widget.child);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AuthState extends InheritedNotifier<AuthController> {
  const _AuthState({required super.notifier, required super.child});
}
