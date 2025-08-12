import 'package:flutter/material.dart';
import 'package:fnlapp/Main/testestres_form.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TestEstresScreen extends StatelessWidget {
  const TestEstresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final anchosPantalla = MediaQuery.of(context).size.width;
    final altoPantalla = MediaQuery.of(context).size.height;
    final esTablet = anchosPantalla > 600;
    final esEscritorio = anchosPantalla > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: altoPantalla - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: esEscritorio ? 64.0 : (esTablet ? 32.0 : 16.0),
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Spacer superior flexible
                const Spacer(flex: 1),

                // Título - Bienvenido al Test de Estrés
                Container(
                  constraints: BoxConstraints(
                    maxWidth: esEscritorio ? 600 : (esTablet ? 500 : double.infinity),
                  ),
                  child: Text(
                    'Bienvenido al Test de Estrés',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF4320AD),
                      fontSize: _obtenerTamanoTitulo(anchosPantalla),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),

                SizedBox(height: _obtenerEspaciado(anchosPantalla, 40)),

                // Imagen
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: esEscritorio ? 400 : (esTablet ? 350 : anchosPantalla * 0.8),
                      maxHeight: esEscritorio ? 300 : (esTablet ? 280 : altoPantalla * 0.25),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: SvgPicture.network(
                        'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/caras_funcy_prev_test.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: _obtenerEspaciado(anchosPantalla, 30)),

                // Texto descriptivo
                Container(
                  constraints: BoxConstraints(
                    maxWidth: esEscritorio ? 500 : (esTablet ? 450 : double.infinity),
                  ),
                  child: Text(
                    'Este test te ayudará a evaluar tu nivel de estrés. A continuación, responde las siguientes preguntas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF212121),
                      fontSize: _obtenerTamanoCuerpo(anchosPantalla),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),

                // Spacer medio
                SizedBox(height: _obtenerEspaciado(anchosPantalla, 20)),

                // Botón para comenzar el test
                Container(
                  constraints: BoxConstraints(
                    minWidth: 200,
                    maxWidth: esEscritorio ? 350 : (esTablet ? 300 : anchosPantalla * 0.8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TestEstresQuestionScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: esTablet ? 16 : 12,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF6D4BD8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Color(0x4C000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Comenzar Test',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _obtenerTamanoBoton(anchosPantalla),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacer inferior
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares para responsividad
  double _obtenerTamanoTitulo(double anchoPantalla) {
    if (anchoPantalla > 1024) return 42; // Escritorio
    if (anchoPantalla > 600) return 40;  // Tablet
    return 32; // Móvil
  }

  double _obtenerTamanoCuerpo(double anchoPantalla) {
    if (anchoPantalla > 1024) return 22; // Escritorio
    if (anchoPantalla > 600) return 20;  // Tablet
    return 18; // Móvil
  }

  double _obtenerTamanoBoton(double anchoPantalla) {
    if (anchoPantalla > 1024) return 24; // Escritorio
    if (anchoPantalla > 600) return 24;  // Tablet
    return 22; // Móvil
  }

  double _obtenerEspaciado(double anchoPantalla, double espaciadoBase) {
    if (anchoPantalla > 1024) return espaciadoBase * 1.5; // Escritorio
    if (anchoPantalla > 600) return espaciadoBase * 1.2;  // Tablet
    return espaciadoBase; // Móvil
  }
}
