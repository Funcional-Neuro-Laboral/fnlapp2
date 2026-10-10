import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
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
}

class _FnlText {
  static TextStyle h1(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.2,
      );

  static TextStyle h2(double size, {Color color = _FnlColors.blue}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
      );

  static TextStyle body({double size = 16, Color color = _FnlColors.body}) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle label({
    double size = 14,
    Color color = _FnlColors.violet,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class MiTestScreen extends StatefulWidget {
  final NivelEstres nivelEstres;

  const MiTestScreen({Key? key, required this.nivelEstres}) : super(key: key);

  @override
  State<MiTestScreen> createState() => _MiTestScreenState();
}

class _MiTestScreenState extends State<MiTestScreen> {
  static const double _bottomNavSpace = 120.0;

  bool _imagesPrecached = false;

  String _tituloLead(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
      case NivelEstres.moderado:
      case NivelEstres.severo:
        return 'Tu nivel de estrés es ';
      default:
        return 'Aún no tienes un resultado';
    }
  }

  String _tituloAccent(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return 'leve';
      case NivelEstres.moderado:
        return 'moderado';
      case NivelEstres.severo:
        return 'alto';
      default:
        return '';
    }
  }

  String _mensajeNivel(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return '¡Todo en calma! Sigue cuidando tu bienestar.';
      case NivelEstres.moderado:
        return 'Tómate un respiro, Funcy está aquí para ayudarte.';
      case NivelEstres.severo:
        return 'Es momento de priorizarte y buscar apoyo.';
      default:
        return 'Completa el test para conocer tu nivel de estrés.';
    }
  }

  int _indexNivel(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return 0;
      case NivelEstres.moderado:
        return 1;
      case NivelEstres.severo:
        return 2;
      default:
        return -1;
    }
  }

  String _mascotaUrl(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/enthusiastic.png';
      case NivelEstres.moderado:
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/confused.png';
      case NivelEstres.severo:
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/sad.png';
      default:
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(NetworkImage(_mascotaUrl(widget.nivelEstres)), context);
      _imagesPrecached = true;
    }
  }

  Widget _progressTrack(int idx) {
    const names = ['Leve', 'Moderado', 'Alto'];

    Widget segment(int step) {
      final bool filled = step <= idx;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(right: step == 2 ? 0 : 6),
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: filled ? _FnlColors.violet : _FnlColors.lavenderDeep,
          ),
        ),
      );
    }

    Widget label(int step) {
      final bool active = step == idx;
      return Expanded(
        child: Text(
          names[step],
          textAlign: step == 0
              ? TextAlign.left
              : step == 2
                  ? TextAlign.right
                  : TextAlign.center,
          style: _FnlText.label(
            size: 13,
            color: active ? _FnlColors.violet : _FnlColors.body,
            weight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }

    return Semantics(
      label: idx < 0
          ? 'Nivel de estrés sin resultado'
          : 'Nivel de estrés: ${names[idx].toLowerCase()}, ${idx + 1} de 3',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(children: [segment(0), segment(1), segment(2)]),
          const SizedBox(height: _FnlSpace.xs),
          Row(children: [label(0), label(1), label(2)]),
        ],
      ),
    );
  }


  Widget _buildResultCard(double mascotSize, bool isTablet) {
    final n = widget.nivelEstres;
    final idx = _indexNivel(n);
    final accent = _tituloAccent(n);
    final titleSize = isTablet ? 26.0 : 22.0;
    final overlap = mascotSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: overlap),
          padding: EdgeInsets.fromLTRB(
            _FnlSpace.md,
            overlap + _FnlSpace.sm,
            _FnlSpace.md,
            _FnlSpace.md,
          ),
          decoration: BoxDecoration(
            color: _FnlColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: _FnlColors.bubbleBorder,
                offset: Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'RESULTADO DEL TEST',
                textAlign: TextAlign.center,
                style: _FnlText.label(
                  size: 12,
                  color: _FnlColors.body,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: _tituloLead(n),
                      style: _FnlText.h2(titleSize),
                    ),
                    if (accent.isNotEmpty)
                      TextSpan(
                        text: accent,
                        style: _FnlText.h2(titleSize, color: _FnlColors.violet),
                      ),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: _FnlSpace.xs),
              Text(
                _mensajeNivel(n),
                textAlign: TextAlign.center,
                style: _FnlText.body(size: isTablet ? 17 : 15),
              ),
              if (idx >= 0) ...[
                const SizedBox(height: _FnlSpace.md),
                _progressTrack(idx),
              ],
            ],
          ),
        ),
        _FloatingMascot(child: _buildMascot(mascotSize)),
      ],
    );
  }

  Widget _buildMascot(double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.7,
            height: size * 0.7,
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
            _mascotaUrl(widget.nivelEstres),
            height: size,
            width: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
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
    );
  }

  Widget _buildHeader(double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNCY · BIENESTAR EMOCIONAL',
          style: _FnlText.label(size: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text('Mi test', style: _FnlText.h1(titleSize)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
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
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;

                  final isTablet = width > 600;
                  final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                  final maxContentWidth = isTablet ? 520.0 : 480.0;
                  final titleSize = width < 400 ? 28.0 : 34.0;

                  final mascotSize = math
                      .min(170.0, (height - _bottomNavSpace) * 0.22)
                      .clamp(100.0, 180.0)
                      .toDouble();

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 16),
                            child: child,
                          ),
                        ),
                        child: CustomScrollView(
                          physics: const ClampingScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  hPad,
                                  _FnlSpace.md,
                                  hPad,
                                  _bottomNavSpace,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(titleSize),
                                    Expanded(
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: _FnlSpace.sm),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildResultCard(
                                                  mascotSize, isTablet),
                                              const SizedBox(
                                                  height: _FnlSpace.sm),
                                              const _DisclaimerNote(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
          ],
        ),
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

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _FnlSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: _FnlColors.body,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Este resultado es orientativo y no sustituye una evaluación profesional.',
              textAlign: TextAlign.center,
              style: _FnlText.body(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMascot extends StatefulWidget {
  final Widget child;
  const _FloatingMascot({required this.child});

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * _curve.value),
        child: child,
      ),
    );
  }
}