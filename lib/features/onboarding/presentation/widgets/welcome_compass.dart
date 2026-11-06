import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeCompass extends StatefulWidget {
  const WelcomeCompass({required this.androidLayout, super.key});

  final bool androidLayout;

  @override
  State<WelcomeCompass> createState() => _WelcomeCompassState();
}

class _WelcomeCompassState extends State<WelcomeCompass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _loop.stop();
    } else {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final android = widget.androidLayout;
    return ExcludeSemantics(
      child: SizedBox(
        height: 280,
        child: Align(
          alignment: android ? const Alignment(0, 0.5) : Alignment.center,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final isStatic = _reduceMotion ?? true;
              final ringRotation = isStatic
                  ? 0.0
                  : -math.pi *
                        (1 -
                            const Interval(
                              0.97545,
                              1,
                              curve: Curves.easeOut,
                            ).transform(_loop.value));
              final pointerRotation = isStatic
                  ? 0.0
                  : -math.pi *
                        (1 -
                            const Interval(
                              0,
                              0.25,
                              curve: Curves.easeOut,
                            ).transform(_loop.value));
              return Transform.rotate(
                angle: ringRotation,
                child: Container(
                  width: android ? 200 : 180,
                  height: android ? 200 : 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Container(
                    width: android ? 160 : 140,
                    height: android ? 160 : 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x08FFFFFF),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.rotate(
                          angle: math.pi / 12,
                          child: SvgPicture.asset(
                            'assets/welcome/north_pointer.svg',
                          ),
                        ),
                        Transform.rotate(
                          angle: -11 * math.pi / 12 + pointerRotation,
                          child: SvgPicture.asset(
                            'assets/welcome/south_pointer.svg',
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: SvgPicture.asset(
                            'assets/welcome/center_node.svg',
                          ),
                        ),
                        Positioned(
                          top: android ? 10 : 8,
                          left: 0,
                          child: const Text(
                            'N',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lexend Deca',
                              fontSize: 12,
                              fontVariations: [FontVariation.weight(800)],
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
