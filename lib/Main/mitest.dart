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
  bool _imagesPrecached = false;

  // ---- helpers de mapeo (solo UI, no cambian tu lógica) ----
  String _tituloLead(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
      case NivelEstres.moderado:
      case NivelEstres.severo:
        return 'Tu nivel de estrés es ';
      default:
        return 'Tu nivel de estrés';
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
        return '¡Todo en calma! Sigue cuidando tu bienestar';
      case NivelEstres.moderado:
        return 'Tómate un respiro, Funcy está aquí para ayudarte.';
      case NivelEstres.severo:
        return 'Es momento de priorizarte y buscar apoyo.';
      default:
        return '';
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

  // ---------------------------------------------------------------------
  // Indicador de nivel: barra segmentada de 3 pasos con etiquetas
  // ---------------------------------------------------------------------
  Widget _progressTrack(int idx) {
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

    Widget label(String text, int step) {
      final bool active = step == idx;
      return Expanded(
        child: Text(
          text,
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

    return Column(
      children: [
        Row(children: [segment(0), segment(1), segment(2)]),
        const SizedBox(height: _FnlSpace.xs),
        Row(
          children: [
            label('Leve', 0),
            label('Moderado', 1),
            label('Alto', 2),
          ],
        ),
      ],
    );
  }

  Widget _stressLevelCard(bool isTablet) {
    final n = widget.nivelEstres;
    final idx = _indexNivel(n);
    final titleSize = isTablet ? 26.0 : 22.0;
    final accent = _tituloAccent(n);
    final mensaje = _mensajeNivel(n);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: double.infinity,
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
              children: [
                Text(
                  'RESULTADO DEL TEST',
                  style: _FnlText.label(
                    size: 12,
                    color: _FnlColors.body,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
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
                if (mensaje.isNotEmpty) ...[
                  const SizedBox(height: _FnlSpace.xs),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: _FnlText.body(size: isTablet ? 17 : 15),
                  ),
                ],
                const SizedBox(height: _FnlSpace.md),
                _progressTrack(idx),
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: _FnlColors.white,
                border: Border(
                  top: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                  left: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascot(double imageSize) {
    return SizedBox(
      height: imageSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: imageSize * 0.8,
            height: imageSize * 0.8,
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
            height: imageSize,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: imageSize,
                width: imageSize,
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
            errorBuilder: (_, __, ___) =>
                SizedBox(height: imageSize, width: imageSize),
          ),
        ],
      ),
    );
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
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final titleSize = constraints.maxWidth < 400 ? 28.0 : 34.0;
                final imageSize = math.min(
                  isTablet ? 240.0 : 200.0,
                  constraints.maxHeight * 0.28,
                ).clamp(120.0, 260.0).toDouble();

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 560 : 480),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          hPad, _FnlSpace.md, hPad, 110),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Encabezado: etiqueta + título
                            Text(
                              'FUNCY · BIENESTAR EMOCIONAL',
                              style: _FnlText.label(
                                size: 12,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Mi test', style: _FnlText.h1(titleSize)),
                            const SizedBox(height: _FnlSpace.md),
                            _buildMascot(imageSize),
                            const SizedBox(height: _FnlSpace.xs),
                            _stressLevelCard(isTablet),
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