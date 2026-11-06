import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/welcome_compass.dart';

const _orange = Color(0xFFFF9C37);
const _teal = Color(0xFF148B96);
const _secondary = Color(0x80FFFFFF);

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

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onExplore,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onExplore;
  final VoidCallback onSignIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Selection stays local until there is an approved set of regions.
  final String _homeRegion = 'Kenya';

  @override
  Widget build(BuildContext context) {
    final android = Theme.of(context).platform == TargetPlatform.android;
    final gutter = android ? 32.0 : 30.0;
    final gap = android ? 28.0 : 24.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          WelcomeCompass(androidLayout: android),
                          Padding(
                            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'YOUR JOURNEY HAS A DIRECTION',
                                  style: _body(12, 700, color: _orange),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Find places that move you.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Lexend Deca',
                                    fontSize: 36,
                                    height: (android ? 40 : 42) / 36,
                                    fontVariations: const [
                                      FontVariation.weight(800),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sacred sites, hidden history and unforgettable '
                                  'stops—mapped around the way you travel.',
                                  style: _body(
                                    14,
                                    400,
                                    color: const Color(0xB3FFFFFF),
                                  ).copyWith(height: 22 / 14),
                                ),
                                SizedBox(height: gap),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _chip('+ SACRED', _orange, android),
                                    _chip(
                                      'HIDDEN HISTORY',
                                      const Color(0x14FFFFFF),
                                      android,
                                    ),
                                    _chip('TRIP READY', _teal, android),
                                  ],
                                ),
                                SizedBox(height: gap),
                                Text(
                                  'Your home region',
                                  style: _body(
                                    android ? 13 : 12,
                                    600,
                                    color: _secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0x12FFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/welcome/map_pin.svg',
                                        ),
                                        SizedBox(width: android ? 12 : 10),
                                        Expanded(
                                          child: Text(
                                            _homeRegion,
                                            style: _body(
                                              android ? 16 : 15,
                                              600,
                                            ),
                                          ),
                                        ),
                                        SvgPicture.asset(
                                          'assets/welcome/chevron_down.svg',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: gap),
                                _ExploreButton(
                                  showArrow: !android,
                                  onPressed: widget.onExplore,
                                ),
                                const SizedBox(height: 3),
                                Center(
                                  child: TextButton(
                                    key: const Key('welcome-sign-in'),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 44),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: widget.onSignIn,
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'Already have an account? ',
                                        children: [
                                          TextSpan(
                                            text: 'Sign In',
                                            style: _body(android ? 14 : 13, 700)
                                                .copyWith(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: Colors.white,
                                                ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      style: _body(
                                        android ? 14 : 13,
                                        500,
                                        color: _secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, bool android) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: android ? 16 : 14,
        vertical: android ? 8 : 6,
      ),
      child: Text(label, style: _body(android ? 12 : 11, 700)),
    ),
  );
}

class _ExploreButton extends StatelessWidget {
  const _ExploreButton({required this.showArrow, required this.onPressed});

  final bool showArrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(100));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFF8F33)],
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Begin exploring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Lexend Deca',
                      fontSize: 16,
                      height: 1.25,
                      fontVariations: [FontVariation.weight(700)],
                    ),
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  SvgPicture.asset('assets/welcome/arrow_right.svg'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
