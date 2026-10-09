import 'package:flutter/material.dart';
import 'package:fnlapp/Main/testestres_form.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _tePrimary = Color(0xFF6D4BD8);
const Color _tePrimaryDark = Color(0xFF4A2FB8);
const Color _teTextDark = Color(0xFF0F0A2E);
const Color _teBackground = Color(0xFFFCFBFF);

const String _teMascotUrl =
    'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

class TestEstresScreen extends StatelessWidget {
  const TestEstresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final anchosPantalla = MediaQuery.of(context).size.width;
    final altoPantalla = MediaQuery.of(context).size.height;
    final esTablet = anchosPantalla > 600;
    final esEscritorio = anchosPantalla > 1024;

    return Scaffold(
      backgroundColor: _teBackground,
      body: Stack(
        children: [

          Positioned(
            top: -60,
            right: -60,
            child: _decorativeBlob(220, _tePrimary.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _decorativeBlob(260, _tePrimary.withOpacity(0.08)),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: altoPantalla -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
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
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF24306B),
                          fontSize: _obtenerTamanoTitulo(anchosPantalla),
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),

                    SizedBox(height: _obtenerEspaciado(anchosPantalla, 40)),

                    Flexible(
                      flex: 3,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: esEscritorio
                              ? 400
                              : (esTablet ? 350 : anchosPantalla * 0.8),
                          maxHeight: esEscritorio
                              ? 300
                              : (esTablet ? 280 : altoPantalla * 0.25),
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              FractionallySizedBox(
                                widthFactor: 0.85,
                                heightFactor: 0.85,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _tePrimary.withOpacity(0.12),
                                        _tePrimary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Image.network(
                                _teMascotUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }

                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: _tePrimary,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.psychology_alt_rounded,
                                    size: 72,
                                    color: _tePrimary,
                                  );
                                },
                              ),
                            ],
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
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          fontSize: _obtenerTamanoCuerpo(anchosPantalla),
                          fontWeight: FontWeight.w400,
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            colors: [_tePrimary, _tePrimaryDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _tePrimary.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
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
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: esTablet ? 16 : 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Comenzar Test',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: _obtenerTamanoBoton(anchosPantalla),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 20),
                                ],
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
        ],
      ),
    );
  }

  Widget _decorativeBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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