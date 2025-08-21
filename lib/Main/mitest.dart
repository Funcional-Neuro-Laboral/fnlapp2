import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';

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

  // Mascota por nivel
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

  // Puntito del “slider”
  Widget _dot(bool active, Color activeColor) {
    return Container(
      width: 13,
      height: 12,
      decoration: ShapeDecoration(
        color: active ? activeColor : const Color(0xFF868686),
        shape: const OvalBorder(
          side: BorderSide(width: 1, color: Color(0xFF979797)),
        ),
      ),
    );
  }

  // Línea entre puntitos
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


  // Tarjeta del resultado (título, mensaje, slider)
  Widget _stressLevelCard(BuildContext context) {
    final idx = _indexNivel(nivelEstres);
    final Color activeColor = (idx == 0)
        ? const Color(0xFF2FC322) // leve (verde)
        : (idx == 1)
        ? const Color(0xFFFFD83D) // moderado (amarillo)
        : const Color(0xFFE53935); // alto (rojo)

    return Container(
      width: 319,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tituloNivel(nivelEstres),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mensajeNivel(nivelEstres),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  _dot(idx == 0, activeColor),
                  const SizedBox(width: 8),
                  _line(),
                  const SizedBox(width: 8),
                  _dot(idx == 1, activeColor),
                  const SizedBox(width: 8),
                  _line(),
                  const SizedBox(width: 8),
                  _dot(idx == 2, activeColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Leve', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                  Text('Moderado', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                  Text('Alto', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
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
    final String mascotaUrl = _mascotaUrl(nivelEstres);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Título
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mi test',
                  style: TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Card centrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: _stressLevelCard(context),
            ),

            const SizedBox(height: 24),

            // Mascota centrada
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -30), // mueve la imagen 20px hacia arriba
                  child: Image.network(
                    mascotaUrl,
                    width: 205,
                    height: 238,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),



            // “pill” inferior (el handle visual)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                width: 134,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
