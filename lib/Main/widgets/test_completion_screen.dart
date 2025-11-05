import 'package:flutter/material.dart';

class TestCompletionScreen extends StatefulWidget {
  final Future<void> Function() onFinalize;

  const TestCompletionScreen({
    Key? key,
    required this.onFinalize,
  }) : super(key: key);

  @override
  State<TestCompletionScreen> createState() => _TestCompletionScreenState();
}

class _TestCompletionScreenState extends State<TestCompletionScreen> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = screenWidth > 600;

          final horizontalPadding = screenWidth * (isTablet ? 0.08 : 0.06);
          final titleFontSize = (screenWidth * (isTablet ? 0.045 : 0.065)).clamp(18.0, 32.0);
          final bodyFontSize = (screenWidth * (isTablet ? 0.028 : 0.042)).clamp(13.0, 20.0);
          final finalTextFontSize = (screenWidth * (isTablet ? 0.030 : 0.045)).clamp(14.0, 22.0);
          final buttonFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(16.0, 24.0);
          final iconSize = (screenWidth * (isTablet ? 0.05 : 0.08)).clamp(20.0, 45.0);
          final maxContentWidth = isTablet ? 800.0 : double.infinity;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: screenHeight - (screenHeight * (isTablet ? 0.15 : 0.18)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: screenHeight * 0.03),

                                Text(
                                  'Has completado tu recorrido',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF5027D0),
                                    fontSize: titleFontSize,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),

                                SizedBox(height: screenHeight * (isTablet ? 0.035 : 0.025)),

                                _buildMessageWithIcon(
                                  icon: Icons.favorite_rounded,
                                  message: 'Cada respuesta que diste no fue solo una elección, fue una forma de conocerte mejor.\nReconocer cómo te sientes frente a tu entorno laboral ya es un paso enorme hacia el cambio.',
                                  iconSize: iconSize,
                                  fontSize: bodyFontSize,
                                  screenWidth: screenWidth,
                                  isTablet: isTablet,
                                ),

                                SizedBox(height: screenHeight * (isTablet ? 0.035 : 0.03)),

                                _buildMessageWithIcon(
                                  icon: Icons.psychology_rounded,
                                  message: 'El estrés, la presión o la falta de apoyo no son señales de debilidad.\nSon indicadores de que estás comprometido, de que te importa hacer las cosas bien, y de que necesitas espacios más humanos para crecer.',
                                  iconSize: iconSize,
                                  fontSize: bodyFontSize,
                                  screenWidth: screenWidth,
                                  isTablet: isTablet,
                                ),

                                SizedBox(height: screenHeight * (isTablet ? 0.035 : 0.025)),

                                Container(
                                  padding: EdgeInsets.all(screenWidth * (isTablet ? 0.04 : 0.045)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Gracias por dedicar este momento a ti. Estamos preparando tu perfil personalizado para que encuentres equilibrio, propósito y calma.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF4320AD),
                                      fontSize: finalTextFontSize,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.03),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(
                          bottom: screenHeight * (isTablet ? 0.025 : 0.03),
                          top: screenHeight * 0.015,
                        ),
                        child: GestureDetector(
                          onTap: isProcessing ? null : () async {
                            setState(() {
                              isProcessing = true;
                            });

                            try {
                              await widget.onFinalize();
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isProcessing = false;
                                });
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * (isTablet ? 0.02 : 0.016),
                            ),
                            decoration: ShapeDecoration(
                              color: isProcessing ? const Color(0xFFD7D7D7) : const Color(0xFF5027D0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              shadows: isProcessing ? const [] : const [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: isProcessing
                                  ? SizedBox(
                                width: buttonFontSize,
                                height: buttonFontSize,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'Finalizar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: buttonFontSize,
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
          );
        },
      ),
    );
  }

  Widget _buildMessageWithIcon({
    required IconData icon,
    required String message,
    required double iconSize,
    required double fontSize,
    required double screenWidth,
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * (isTablet ? 0.02 : 0.022)),
          decoration: BoxDecoration(
            color: const Color(0xFF5027D0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5027D0),
            size: iconSize,
          ),
        ),
        SizedBox(width: screenWidth * (isTablet ? 0.03 : 0.035)),
        Expanded(
          child: Text(
            message,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: fontSize,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}