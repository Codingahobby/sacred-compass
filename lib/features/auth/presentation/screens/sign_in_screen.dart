import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/auth_repository.dart';

const _muted = Color(0x26FFFFFF);
const _orange = Color(0xFFFF9C37);
const _teal = Color(0xFF148B96);

TextStyle _body(double size, double weight, {Color color = Colors.white}) =>
    TextStyle(
      fontFamily: 'DM Sans',
      fontSize: size,
      color: color,
      fontVariations: [
        const FontVariation('opsz', 14),
        FontVariation.weight(weight),
      ],
    );

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.repository,
    required this.onSignedIn,
    required this.onCreateAccount,
    required this.onForgotPassword,
    super.key,
  });

  final AuthRepository? repository;
  final VoidCallback onSignedIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = widget.repository;
      if (repository == null) {
        throw const AuthFailure(
          'Sign-in is unavailable. Please restart the app.',
        );
      }
      final user = await repository.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (repository.currentSession?.user.id != user.id) {
        throw const AuthFailure(
          'Could not establish a session. Please try again.',
        );
      }

      _password.clear();
      TextInput.finishAutofillContext();
      widget.onSignedIn();
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted && _error != null) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF191140), Color(0xFF1D7B8C)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final formWidth = (constraints.maxWidth - 48)
                          .clamp(0.0, double.infinity)
                          .toDouble();
                      return CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    _hero(),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        12,
                                        24,
                                        24,
                                      ),
                                      child: AutofillGroup(
                                        child: Form(
                                          key: _form,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Email Address',
                                                style: _body(14, 600),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                key: const Key('sign-in-email'),
                                                controller: _email,
                                                enabled: !_submitting,
                                                style: _body(
                                                  15,
                                                  400,
                                                ).copyWith(height: 20 / 15),
                                                decoration: _decoration(
                                                  'Email address',
                                                ),
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                textInputAction:
                                                    TextInputAction.next,
                                                autofillHints: const [
                                                  AutofillHints.email,
                                                ],
                                                autocorrect: false,
                                                textCapitalization:
                                                    TextCapitalization.none,
                                                validator: (value) {
                                                  final email =
                                                      value?.trim() ?? '';
                                                  if (email.isEmpty) {
                                                    return 'Enter your email address.';
                                                  }
                                                  if (!RegExp(
                                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                                  ).hasMatch(email)) {
                                                    return 'Enter a valid email address.';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Password',
                                                      style: _body(14, 600),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    key: const Key(
                                                      'password-visibility',
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(
                                                        48,
                                                        44,
                                                      ),
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    onPressed: _submitting
                                                        ? null
                                                        : _togglePassword,
                                                    child: Text(
                                                      _obscurePassword
                                                          ? 'Show'
                                                          : 'Hide',
                                                      style: _body(
                                                        14,
                                                        600,
                                                        color: _orange,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                key: const Key(
                                                  'sign-in-password',
                                                ),
                                                controller: _password,
                                                enabled: !_submitting,
                                                obscureText: _obscurePassword,
                                                style: _body(
                                                  15,
                                                  400,
                                                ).copyWith(height: 20 / 15),
                                                decoration:
                                                    _decoration(
                                                      'Password',
                                                    ).copyWith(
                                                      suffixIcon: IconButton(
                                                        tooltip:
                                                            _obscurePassword
                                                            ? 'Show password'
                                                            : 'Hide password',
                                                        onPressed: _submitting
                                                            ? null
                                                            : _togglePassword,
                                                        icon: ClipRect(
                                                          child: SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .contain,
                                                              child:
                                                                  SvgPicture.asset(
                                                                    'assets/auth/eye.svg',
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                textInputAction:
                                                    TextInputAction.done,
                                                autofillHints: const [
                                                  AutofillHints.password,
                                                ],
                                                autocorrect: false,
                                                enableSuggestions: false,
                                                onFieldSubmitted: (_) =>
                                                    _submit(),
                                                validator: (value) =>
                                                    value == null ||
                                                        value.isEmpty
                                                    ? 'Enter your password.'
                                                    : null,
                                              ),
                                              const SizedBox(height: 12),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: _submitting
                                                      ? null
                                                      : widget.onForgotPassword,
                                                  child: Text(
                                                    'Forgot Password?',
                                                    style: _body(14, 600)
                                                        .copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationColor:
                                                              Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (_error case final error?) ...[
                                                Semantics(
                                                  liveRegion: true,
                                                  child: Text(
                                                    error,
                                                    style: _body(14, 500),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                              FilledButton(
                                                key: const Key(
                                                  'sign-in-submit',
                                                ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: _teal,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      _teal,
                                                  disabledForegroundColor:
                                                      Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 20,
                                                      ),
                                                  shape: const StadiumBorder(),
                                                ),
                                                onPressed: _submitting
                                                    ? null
                                                    : _submit,
                                                child: _submitting
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                              semanticsLabel:
                                                                  'Signing in',
                                                            ),
                                                      )
                                                    : const Text(
                                                        'Sign in',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Lexend Deca',
                                                          fontSize: 16,
                                                          height: 1.25,
                                                          fontVariations: [
                                                            FontVariation.weight(
                                                              700,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(height: 20),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: SvgPicture.asset(
                                                        'assets/auth/line.svg',
                                                      ),
                                                    ),
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            // Keep the natural label width until it needs to wrap.
                                                            maxWidth:
                                                                formWidth *
                                                                0.75,
                                                          ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                            ),
                                                        child: Text(
                                                          'OR CONTINUE WITH',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: _body(
                                                            11,
                                                            800,
                                                            color: _muted,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: SvgPicture.asset(
                                                        'assets/auth/line.svg',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  _social(
                                                    'Google',
                                                    'google_pending',
                                                  ),
                                                  const SizedBox(width: 12),
                                                  _social('Apple', 'apple'),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Google and Apple sign-in are pending.',
                                                textAlign: TextAlign.center,
                                                style: _body(
                                                  12,
                                                  400,
                                                  color: const Color(
                                                    0xB3FFFFFF,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    36,
                                  ),
                                  child: TextButton(
                                    onPressed: _submitting
                                        ? null
                                        : widget.onCreateAccount,
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'New here? ',
                                        children: [
                                          TextSpan(
                                            text: 'Create an account',
                                            style:
                                                _body(
                                                  14,
                                                  700,
                                                  color: _orange,
                                                ).copyWith(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: _orange,
                                                ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      style: _body(14, 400, color: _muted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _togglePassword() =>
      setState(() => _obscurePassword = !_obscurePassword);

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: _body(15, 400, color: const Color(0x80FFFFFF)),
    filled: true,
    fillColor: const Color(0x14FFFFFF),
    isDense: true,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0x26FFFFFF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0x26FFFFFF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _orange),
    ),
    errorStyle: _body(13, 500),
    errorMaxLines: 3,
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _orange),
    ),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Column(
      children: [
        Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x14FFFFFF),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: SvgPicture.asset('assets/auth/compass.svg'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 44),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 28,
              color: Colors.white,
              fontVariations: [FontVariation.weight(800)],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your details to sync your trips',
          textAlign: TextAlign.center,
          style: _body(14, 400, color: _muted),
        ),
      ],
    ),
  );

  Widget _social(String label, String asset) => Expanded(
    child: Tooltip(
      message: '$label sign-in is pending',
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: Colors.white,
          backgroundColor: const Color(0x14FFFFFF),
          padding: const EdgeInsets.all(14),
          side: const BorderSide(color: Color(0x26FFFFFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            SvgPicture.asset('assets/auth/$asset.svg'),
            Text(label, style: _body(14, 600)),
          ],
        ),
      ),
    ),
  );
}
