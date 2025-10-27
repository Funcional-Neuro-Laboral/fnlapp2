import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para contenido principal
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Controlador para formas decorativas (movimiento flotante continuo)
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  bool _isWeb(double width) => width > 900;
  bool _isTablet(double width) => width > 600 && width <= 900;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = _isWeb(screenWidth);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.50, -0.00),
                end: Alignment(0.50, 1.00),
                colors: [
                  Color(0xC24320AD),
                  Color(0xFFFDFCFF),
                ],
              ),
            ),
          ),

          // Elementos decorativos
          ..._buildDecorativeElements(screenHeight, screenWidth, isWeb),

          // Contenido principal
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 500 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 40 : screenWidth * 0.08,
                    vertical: screenHeight * 0.02,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // Título "Funcy"
                          Text(
                            'Funcy',
                            style: TextStyle(
                              fontSize: isWeb ? 48 : screenWidth * 0.09,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.01),

                          // Subtítulo
                          Text(
                            'Un momento para ti',
                            style: TextStyle(
                              fontSize: isWeb ? 28 : screenWidth * 0.06,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Imagen centrada
                          Image.network(
                            'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_bienvenida.png',
                            width: isWeb ? 250 : screenWidth * 0.5,
                            height: isWeb ? 300 : screenHeight * 0.4,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                size: isWeb ? 250 : screenWidth * 0.5,
                                color: Colors.white,
                              );
                            },
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Texto descriptivo
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 20 : screenWidth * 0.02,
                            ),
                            child: Stack(
                              children: [
                                // Contorno
                                Text(
                                  'Tu compañero para entender, cuidar y equilibrar tus emociones.',
                                  style: TextStyle(
                                    fontSize: isWeb ? 24 : screenWidth * 0.06,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Inter',
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 3
                                      ..color = const Color(0xFF6D4BD8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Relleno
                                Text(
                                  'Tu compañero para entender, cuidar y equilibrar tus emociones.',
                                  style: TextStyle(
                                    fontSize: isWeb ? 24 : screenWidth * 0.06,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Botón "Empezar"
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D4BD8),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isWeb ? 18 : screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Empezar',
                                style: TextStyle(
                                  fontSize: isWeb ? 20 : screenWidth * 0.05,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeElements(double screenHeight, double screenWidth, bool isWeb) {
    if (isWeb) {
      // En web, elementos decorativos más sutiles
      return [
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
              top: screenHeight * 0.05 + _floatingAnimation.value,
              left: screenWidth * 0.05,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: SvgPicture.network(
                  'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/nube.svg',
                  width: 150,
                  height: 100,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
              top: screenHeight * 0.1 - _floatingAnimation.value,
              right: screenWidth * 0.05,
              child: Transform.rotate(
                angle: -_rotationAnimation.value,
                child: SvgPicture.network(
                  'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/nube.svg',
                  width: 130,
                  height: 90,
                ),
              ),
            );
          },
        ),
      ];
    }

    // Elementos decorativos para móvil/tablet (código original)
    return [
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: screenHeight * 0.01 + _floatingAnimation.value,
            left: -screenWidth * 0.08,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: SvgPicture.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/nube.svg',
                width: screenWidth * 0.5,
                height: screenHeight * 0.15,
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: screenHeight * 0.08 - _floatingAnimation.value,
            right: -screenWidth * 0.1,
            child: Transform.rotate(
              angle: -_rotationAnimation.value,
              child: SvgPicture.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/nube.svg',
                width: screenWidth * 0.45,
                height: screenHeight * 0.13,
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: screenHeight * 0.05 + (_floatingAnimation.value * 0.5),
            left: -screenWidth * 0.001,
            child: Opacity(
              opacity: 0.8 + (_floatingAnimation.value / 100),
              child: SvgPicture.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/rectangulo.svg',
                width: screenWidth * 1,
                height: screenHeight * 0.30,
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            bottom: screenHeight * 0.90 + _floatingAnimation.value,
            right: -screenWidth * 0.12,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2,
              child: SvgPicture.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/estrella.svg',
                width: screenWidth * 1,
                height: screenWidth * 0.4,
              ),
            ),
          );
        },
      ),
    ];
  }
}
