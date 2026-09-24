import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fnlapp/config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fnlapp/Funcy/screens/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'dart:math' as math;
import '../../Funcy/screens/chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:fnlapp/SplashScreen/welcome_screen.dart' show FuncyColors;

class ChatWidget extends StatelessWidget {
  final int userId;
  final String username;
  final Function(bool) onChatToggle;

  ChatWidget(
      {required this.userId,
      required this.username,
      required this.onChatToggle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final imageSize = math.min(
      size.width < 400 ? 220.0 : size.width < 600 ? 270.0 : 320.0,
      size.height * 0.3,
    ).toDouble();
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          // Mismo lenguaje visual del login y de "Mi test": degradado de
          // marca con capas suaves de profundidad, sin fotografías de por
          // medio.
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
            top: 160,
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.09),

                    // Etiqueta editorial + título, en vez del contorno
                    // manual sobre fondo blanco.
                    Text(
                      'ASISTENTE VIRTUAL',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Conversa con Funcy!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: size.width < 400 ? 30 : size.width < 600 ? 36 : 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Tu consejero virtual',
                      style: GoogleFonts.inter(
                        fontSize: size.width < 400 ? 16 : size.width < 600 ? 18 : 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    SizedBox(height: size.height * 0.04),

                    // Mascota con halo, igual criterio visual que en el
                    // resto de la app.
                    SizedBox(
                      width: double.infinity,
                      height: imageSize + 40,
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
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: imageSize * 0.02,
                              left: imageSize * 0.279,
                              child: Container(
                                width: imageSize * 0.42,
                                height: imageSize * 0.055,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.black.withOpacity(0.14),
                                ),
                              ),
                            ),
                            Image.network(
                              'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/enthusiastic.png',
                              height: imageSize,
                              width: imageSize,
                              fit: BoxFit.contain,
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

                    SizedBox(height: size.height * 0.03),

                    // Botón con relleno de marca en vez del contorno sobre
                    // fondo blanco; ahora compacto y centrado en lugar de
                    // ocupar todo el ancho.
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: FuncyColors.primaryDark.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: OutlinedButton(
                          onPressed: () async {
                            await _startChat(context);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Empezar',
                                style: GoogleFonts.inter(
                                  fontSize: size.width < 400 ? 18 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: FuncyColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: FuncyColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.04),
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

  Future<void> _startChat(BuildContext context) async {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: userId,
              username: username,
            )
        ),
      );
    } else {
      print("Error: userId no definido");
    }
  }
}