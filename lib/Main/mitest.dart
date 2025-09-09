import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

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

  String _mascotaUrl(NivelEstres n) {
    switch (n) {
      case NivelEstres.leve:
        return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_like.png';
      case NivelEstres.moderado:
        return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_moderado.png';
      case NivelEstres.severo:
        return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_estresado.png';
      default:
        return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/fondoFNL.jpg';
    }
  }

  Widget _dot(bool active, Color activeColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: active ? activeColor : const Color(0xFF868686),
        shape: const OvalBorder(
          side: BorderSide(width: 1, color: Color(0xFF979797)),
        ),
      ),
    );
  }

  Widget _line() {
    return Flexible(
      fit: FlexFit.loose,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: const Color(0xFF868686),
          border: Border.all(color: const Color(0xFF979797), width: 1),
        ),
      ),
    );
  }

  Widget _stressLevelCard(BuildContext context, Size size,
      double horizontalPadding) {
    final idx = _indexNivel(nivelEstres);
    final Color activeColor = (idx == 0)
        ? const Color(0xFF2FC322)
        : (idx == 1)
        ? const Color(0xFFFFD83D)
        : const Color(0xFFE53935);

    final cardWidth = math.min(
      size.width - (horizontalPadding * 2),
      size.width < 600 ? size.width * 0.9 : 400.0,
    ).toDouble(); // Convertir a double

    final titleFontSize = size.width < 400 ? 18.0 : size.width < 600
        ? 20.0
        : 22.0;
    final messageFontSize = size.width < 400 ? 13.0 : size.width < 600
        ? 15.0
        : 16.0;
    final labelFontSize = size.width < 400 ? 10.0 : 12.0;
    final dotSize = size.width < 400 ? 11.0 : 13.0;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(size.width < 400 ? 12 : 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFEAE5F9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _tituloNivel(nivelEstres),
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mensajeNivel(nivelEstres),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: messageFontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  _dot(idx == 0, activeColor, dotSize),
                  const SizedBox(width: 8),
                  _line(),
                  const SizedBox(width: 8),
                  _dot(idx == 1, activeColor, dotSize),
                  const SizedBox(width: 8),
                  _line(),
                  const SizedBox(width: 8),
                  _dot(idx == 2, activeColor, dotSize),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leve',
                      style: GoogleFonts.inter(fontSize: labelFontSize)),
                  Text('Moderado',
                      style: GoogleFonts.inter(fontSize: labelFontSize)),
                  Text('Alto',
                      style: GoogleFonts.inter(fontSize: labelFontSize)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 16.0;

    final titleFontSize = size.width < 400
        ? 28.0
        : size.width < 600
        ? 32.0
        : 36.0;

    // Imagen mucho más grande y responsiva
    final imageSize = math.min(
      size.width < 400 ? 280.0 : size.width < 600 ? 350.0 : 400.0,
      // Tamaños más grandes
      size.height * 0.45, // Puede ocupar hasta 45% de la altura
    ).toDouble();

    final String mascotaUrl = _mascotaUrl(nivelEstres);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.05),

                // Título
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mi test',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF212121),
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // Card centrado
                _stressLevelCard(context, size, horizontalPadding),

                SizedBox(height: size.height * 0.03),

                // Mascota más grande y responsiva
                Container(
                  width: double.infinity,
                  height: math.max(imageSize + 60, size.height * 0.5),
                  // Contenedor más alto
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: Image.network(
                        mascotaUrl,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: imageSize,
                            height: imageSize,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                    null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

