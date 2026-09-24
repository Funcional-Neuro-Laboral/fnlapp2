import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:fnlapp/SplashScreen/welcome_screen.dart' show FuncyColors;

class MiTestScreen extends StatelessWidget {
  final NivelEstres nivelEstres;

  const MiTestScreen({Key? key, required this.nivelEstres}) : super(key: key);

  // ---- helpers de mapeo (solo UI, no cambian tu lógica) ----
  String _tituloNivel(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return 'Tu nivel de estrés es leve';
      case NivelEstres.moderado:
        return 'Tu nivel de estrés es moderado';
      case NivelEstres.severo:
        return 'Tu nivel de estrés es alto';
      default:
        return 'Tu nivel de estrés';
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

  // Color de acento por nivel; se usa en la barra de progreso y en el
  // halo detrás de la mascota, para que la paleta responda al estado.
  Color _colorNivel(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return const Color(0xFF2FC322);
      case NivelEstres.moderado:
        return const Color(0xFFF5A623);
      case NivelEstres.severo:
        return const Color(0xFFE5484D);
      default:
        return FuncyColors.primary;
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
        return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/fondoFNL.jpg';
    }
  }

  // ---------------------------------------------------------------------
  // Indicador de progreso: barra segmentada en vez de puntos sueltos,
  // se lee de un vistazo y transmite más pulcritud.
  // ---------------------------------------------------------------------
  Widget _progressTrack(int idx, Color activeColor, double labelFontSize) {
    Widget segment(int step) {
      final bool filled = step <= idx;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(right: step == 2 ? 0 : 6),
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: filled ? activeColor : const Color(0xFFE7E3F5),
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
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? activeColor : Colors.grey[500],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [segment(0), segment(1), segment(2)]),
        const SizedBox(height: 8),
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

  Widget _stressLevelCard(
      BuildContext context, Size size, double horizontalPadding) {
    final idx = _indexNivel(nivelEstres);
    final Color activeColor = _colorNivel(nivelEstres);

    final cardWidth = math.min(
      size.width - (horizontalPadding * 2),
      size.width < 600 ? size.width * 0.9 : 440.0,
    ).toDouble();

    final titleFontSize =
        size.width < 400 ? 18.0 : size.width < 600 ? 20.0 : 22.0;
    final messageFontSize =
        size.width < 400 ? 13.0 : size.width < 600 ? 14.5 : 15.5;
    final labelFontSize = size.width < 400 ? 11.0 : 12.5;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FuncyColors.primaryDark.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width < 400 ? 18 : 24,
              vertical: size.width < 400 ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'RESULTADO DEL TEST',
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _tituloNivel(nivelEstres),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A1A),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mensajeNivel(nivelEstres),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: messageFontSize,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _progressTrack(idx, activeColor, labelFontSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 20.0;

    final titleFontSize =
        size.width < 400 ? 26.0 : size.width < 600 ? 30.0 : 34.0;

    final imageSize = math.min(
      size.width < 400 ? 230.0 : size.width < 600 ? 280.0 : 320.0,
      size.height * 0.36,
    ).toDouble();

    final String mascotaUrl = _mascotaUrl(nivelEstres);
    final Color accent = _colorNivel(nivelEstres);

    return Scaffold(
      body: Stack(
        children: [
          // Mismo lenguaje visual del login: degradado de marca con capas
          // suaves de profundidad, sin fotografías de por medio.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FuncyColors.primaryDark,
                  FuncyColors.primary,
                  FuncyColors.primaryLight,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _decorativeCircle(240, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 140,
            left: -80,
            child: _decorativeCircle(170, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -110,
            right: -50,
            child: _decorativeCircle(280, Colors.black.withOpacity(0.06)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.035),

                    // Encabezado: eyebrow + título, jerarquía más editorial.
                    Text(
                      'FUNCY · BIENESTAR EMOCIONAL',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mi test',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),

                    SizedBox(height: size.height * 0.035),

                    // Card de resultado.
                    Center(
                      child: _stressLevelCard(context, size, horizontalPadding),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Mascota con halo y sombra de apoyo: mismo carácter
                    // caricaturesco de la ilustración, presentado con más
                    // cuidado (profundidad, contacto con el suelo).
                    SizedBox(
                      width: double.infinity,
                      height: math.max(imageSize + 50, size.height * 0.36),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: imageSize * 1.05,
                              height: imageSize * 1.05,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.16),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: imageSize * 0.55,
                              height: imageSize * 0.55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.16),
                              ),
                            ),
                            Positioned(
                              bottom: imageSize * 0.04,
                              child: Container(
                                width: imageSize * 0.5,
                                height: imageSize * 0.09,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.black.withOpacity(0.16),
                                ),
                              ),
                            ),
                            Image.network(
                              mascotaUrl,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  width: imageSize,
                                  height: imageSize,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      value: loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.emoji_emotions_rounded,
                                  size: imageSize * 0.6,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ],
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
    );
  }

  Widget _decorativeCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}