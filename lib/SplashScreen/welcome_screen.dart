import 'package:flutter/material.dart';

/// Paleta de marca centralizada (sin cambios de valores): login, "Mi test",
/// el chat, el plan y el perfil siguen importando esta clase tal cual, así
/// que se conserva intacta aunque esta pantalla ahora use su propio set de
/// tokens más abajo.
class FuncyColors {
  static const primary = Color(0xFF6D4BD8);
  static const primaryDark = Color(0xFF4320AD);
  static const primaryLight = Color(0xFF9B7EF0);
  static const background = Color(0xFFFDFCFF);
  static const accent = Color(0xFFFFD166);
}

/// Sistema de diseño para esta pantalla: tipografía Poppins + tokens de
/// color entregados (azul FNL para identidad/jerarquía, violeta para
/// interacción, blanco como fondo predominante). Solo se usa aquí para no
/// afectar el resto de pantallas, que ya tienen su propia paleta.
class _Tokens {
  static const fontFamily = 'Poppins';

  // Colores
  static const navy = Color(0xFF0B1457); // identidad / jerarquía
  static const violet = Color(0xFF6428E8); // interacción
  static const violet2 = Color(0xFF814CF4);
  static const lavender = Color(0xFFF4F1FF);
  static const grayText = Color(0xFF70779C);
  static const grayLabel = Color(0xFF5F668B);

  // Tipografía
  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: navy,
    height: 1.15,
  );
  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: navy,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: grayText,
    height: 1.45,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: grayLabel,
    letterSpacing: 2.4,
  );
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Espaciado base de 8px.
  static const s1 = 8.0;
  static const s2 = 16.0;
  static const s3 = 24.0;
  static const s4 = 32.0;
  static const s5 = 40.0;
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _floatingController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _mascotBounce;
  late final Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _mascotBounce = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Solo un ligero flotado vertical continuo para la mascota; ya no hay
    // nubes ni estrellas girando (look más profesional y menos cargado).
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isWeb = _isWeb(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo blanco predominante con formas suaves en las esquinas,
          // mismo criterio que el login (nada de degradado morado).
          Positioned(
            top: -70,
            right: -60,
            child: _decorativeBlob(220, _Tokens.lavender),
          ),
          Positioned(
            bottom: -90,
            left: -80,
            child: _decorativeBlob(240, _Tokens.lavender),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 460 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 40 : screenWidth * 0.1,
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

                          // Wordmark: dos tonos planos (navy + violeta), sin
                          // shader ni degradado sobre el texto. Peso extra
                          // bold y kerning ligeramente cerrado, igual que
                          // en la imagen de referencia.
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: _Tokens.fontFamily,
                                fontSize: isWeb ? 48 : screenWidth * 0.115,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                              children: const [
                                TextSpan(
                                    text: 'Fun', style: TextStyle(color: _Tokens.navy)),
                                TextSpan(
                                    text: 'cy', style: TextStyle(color: _Tokens.violet)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'TU BIENESTAR CUENTA',
                            style: _Tokens.label,
                          ),

                          SizedBox(height: _Tokens.s5),

                          // Titular en dos líneas: primera en navy
                          // (identidad/jerarquía), segunda en violeta (el
                          // gancho emocional del mensaje). Extra bold,
                          // interlineado ajustado y kerning cerrado para
                          // que las dos líneas queden compactas, igual que
                          // en la imagen.
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Un momento\n',
                                  style: _Tokens.h1.copyWith(
                                    fontSize: isWeb ? 38 : screenWidth * 0.098,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.08,
                                  ),
                                ),
                                TextSpan(
                                  text: 'para ti',
                                  style: _Tokens.h1.copyWith(
                                    color: _Tokens.violet,
                                    fontSize: isWeb ? 38 : screenWidth * 0.098,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.08,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: _Tokens.s2),

                          Text(
                            'Tu compañero para entender, cuidar y equilibrar tus emociones.',
                            textAlign: TextAlign.center,
                            style: _Tokens.body,
                          ),

                          SizedBox(height: _Tokens.s4),

                          // Mascota con flotado sutil y sombra de apoyo, sin
                          // halo de luz (innecesario sobre fondo blanco).
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_floatingController, _controller]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatingAnimation.value),
                                child: Transform.scale(
                                  scale: _mascotBounce.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: isWeb ? 130 : screenWidth * 0.32,
                                  height: isWeb ? 20 : screenWidth * 0.05,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: _Tokens.navy.withOpacity(0.08),
                                  ),
                                ),
                                Image.network(
                                  'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy.png',
                                  width: isWeb ? 220 : screenWidth * 0.5,
                                  height: isWeb ? 260 : screenHeight * 0.3,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.emoji_emotions_rounded,
                                      size: isWeb ? 180 : screenWidth * 0.4,
                                      color: _Tokens.violet,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Botón "Empezar": altura 56, radio 18, degradado
                          // violeta, tipografía Button (17/600/blanco).
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [_Tokens.violet, _Tokens.violet2],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _Tokens.violet.withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Empezar', style: _Tokens.button),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: _Tokens.s3),

                          // Acento subrayado, mismo detalle que el login.
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _Tokens.violet,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          SizedBox(height: _Tokens.s2),
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

  Widget _decorativeBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}