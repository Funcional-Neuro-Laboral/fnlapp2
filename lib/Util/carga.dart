import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

// ─────────────────────────────────────────────────────────────
// Design tokens FNL
// ─────────────────────────────────────────────────────────────
class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const gradientStart = Color(0xFF5425E8);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
}

class _FnlText {
  static TextStyle h2(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.25,
      );

  static TextStyle percent(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.violet,
        height: 1.1,
      );
}

class LoadingScreen extends StatefulWidget {
  final Function onLoadingComplete;

  LoadingScreen({required this.onLoadingComplete});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  double progress = 0;
  Timer? _timer;
  bool _completed = false;
  bool _imagesPrecached = false;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _startLoading();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_funcyUrl), context);
      _imagesPrecached = true;
    }
  }

  void _startLoading() {
    int step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      setState(() {
        progress = step / 100;
      });
      if (step >= 100) {
        timer.cancel();
        if (!_completed) {
          _completed = true;
          widget.onLoadingComplete();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -70,
            child: IgnorePointer(child: _DecorCircle(size: 220)),
          ),
          const Positioned(
            bottom: -90,
            left: -90,
            child: IgnorePointer(child: _DecorCircle(size: 240)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final isSmallHeight = constraints.maxHeight < 700;
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final maxContentWidth = isTablet ? 720.0 : double.infinity;
                final mascotSize = isTablet
                    ? 240.0
                    : isSmallHeight
                        ? 140.0
                        : 190.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: hPad, vertical: _FnlSpace.md),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 16),
                            child: child,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMascot(mascotSize),
                            const SizedBox(height: _FnlSpace.lg),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'Personalizando tu ',
                                  style: _FnlText.h2(isTablet ? 32 : 28),
                                ),
                                TextSpan(
                                  text: 'experiencia...',
                                  style: _FnlText.h2(isTablet ? 32 : 28)
                                      .copyWith(color: _FnlColors.violet),
                                ),
                              ]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: _FnlSpace.md),
                            _buildProgressCard(isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(double size) {
    return SizedBox(
      height: size + 12,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final dy = Curves.easeInOut.transform(_floatController.value) * -12;
          return Transform.translate(offset: Offset(0, dy + 6), child: child);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _FnlColors.violetSecondary.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Image.network(
              _funcyUrl,
              height: size,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: size,
                  width: size,
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _FnlColors.violetSecondary,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => SizedBox(height: size, width: size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(bool isTablet) {
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(_FnlSpace.md),
      decoration: BoxDecoration(
        color: _FnlColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _FnlColors.bubbleBorder,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$percent%', style: _FnlText.percent(isTablet ? 48 : 40)),
          const SizedBox(height: _FnlSpace.sm),
          Container(
            height: 14,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _FnlColors.lavenderDeep,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _FnlColors.gradientStart,
                        _FnlColors.violetSecondary,
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  const _DecorCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _FnlColors.lavenderDeep,
        shape: BoxShape.circle,
      ),
    );
  }
}