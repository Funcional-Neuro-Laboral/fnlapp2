import 'package:flutter/material.dart';

class IndexSummaryScreen extends StatelessWidget {
  final VoidCallback onFinalize;
  final VoidCallback onBack; // Agregar callback para retroceder

  const IndexSummaryScreen({
    Key? key,
    required this.onFinalize,
    required this.onBack, // Requerir el callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Tamaños de fuente basados en porcentaje del ancho de pantalla
        final bodyFontSize = screenWidth * 0.050;
        final buttonFontSize = screenWidth * 0.05;

        // Padding basado en porcentaje
        final horizontalPadding = screenWidth * 0.06;
        final verticalPadding = screenHeight * 0.05;

        // Tamaño de imagen basado en porcentaje
        final imageSize = screenWidth * 0.65;

        // Espaciado entre elementos
        final spacing = screenHeight * 0.04;

        // Ancho del botón
        final buttonWidth = screenWidth * 0.7;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F6),
          body: SafeArea(
            child: Column(
              children: [
                // Barra superior con botón de retroceso
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: screenHeight * 0.05, // Mismo padding que en index.dart
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: onBack,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: screenWidth * 0.06,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenido principal
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texto principal alineado a la izquierda
                            RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: bodyFontSize.clamp(14.0, 28.0),
                                  color: Colors.black,
                                  fontFamily: 'Inter',
                                  height: 1.6,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'El equilibrio entre tu trabajo y tu bienestar empieza por conocerte.\n',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: 'Tu cargo y responsabilidades ',
                                  ),
                                  TextSpan(
                                    text: 'no te definen, ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: 'pero sí nos ayudan a crear un plan más humano y real para ti.',
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: spacing),

                            // Imagen centrada horizontalmente
                            Center(
                              child: Image.network(
                                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_espejo.png',
                                width: imageSize.clamp(150.0, 400.0),
                                height: imageSize.clamp(150.0, 400.0),
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: imageSize.clamp(150.0, 400.0),
                                    height: imageSize.clamp(150.0, 400.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: imageSize.clamp(150.0, 400.0),
                                    height: imageSize.clamp(150.0, 400.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: imageSize.clamp(150.0, 400.0) * 0.4,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: spacing),

                            // Botón Finalizar centrado horizontalmente
                            Center(
                              child: GestureDetector(
                                onTap: onFinalize,
                                child: Container(
                                  width: buttonWidth.clamp(280.0, 500.0),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.08,
                                    vertical: screenHeight * 0.02,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF5027D0),
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
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Finalizar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: buttonFontSize.clamp(16.0, 30.0),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
