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
      size.width < 400 ? 140.0 : size.width < 600 ? 200.0 : 240.0,
      size.height * 0.25, // Máximo 25% de la altura
    );
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para toda la pantalla
      body: Stack(
        children: [
          // Título "Chat" arriba a la izquierda
          Positioned(
            top: math.max(60, MediaQuery.of(context).padding.top + 15),
            left: horizontalPadding,
            child: Text(
              'Chat',
              style: GoogleFonts.inter(
                fontSize: size.width < 400
                    ? 32
                    : size.width < 600
                    ? 38
                    : 42,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
            ),
          ),

          // Resto del contenido centrado
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),

                  // Título "¡Conoce a Funcy!" con contorno
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '¡Conoce a Funcy!',
                        style: GoogleFonts.inter(
                          fontSize: size.width < 400
                              ? 32
                              : size.width < 600
                              ? 38
                              : 42,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 8
                            ..color = const Color(0xFF5027D0),
                        ),
                      ),
                      Text(
                        '¡Conoce a Funcy!',
                        style: GoogleFonts.inter(
                          fontSize: size.width < 400
                              ? 32
                              : size.width < 600
                              ? 38
                              : 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Subtítulo "Tu consejero virtual"
                  Text(
                    'Tu consejero virtual',
                    style: GoogleFonts.inter(
                      fontSize: size.width < 400
                          ? 24
                          : size.width < 600
                          ? 28
                          : 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Imagen SVG
                  /*SvgPicture.network(
                    'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_saludando_chat.svg',
                    fit: BoxFit.contain,
                  ),*/
                  Image.network(
                    'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_saludando_chat.png',
                    height: imageSize,
                    width: imageSize,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  // Botón
                  OutlinedButton(
                    onPressed: () async {
                      await _startChat(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF6D4BD8),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text(
                      'Conversa con Funcy',
                      style: GoogleFonts.inter(
                        fontSize: size.width < 400 ? 16 : 22,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6D4BD8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
