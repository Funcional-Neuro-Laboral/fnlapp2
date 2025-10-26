import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      await prefs.remove('token');
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    final permisopoliticas = prefs.getBool('permisopoliticas') ?? false;
    final userresponsebool = prefs.getBool('userresponsebool') ?? false;
    final testestresbool = prefs.getBool('testestresbool') ?? false;

    if (permisopoliticas && userresponsebool && testestresbool) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/index');
    }
  }

  // --- FUNCIÓN CORREGIDA ---
  // Esta versión es más robusta y maneja diferentes tipos de números.
  bool _isTokenValid(String token) {
    try {
      final jwt = JWT.decode(token);
      final payload = jwt.payload;

      // 1. Verificamos que la clave 'exp' exista y que sea un número.
      if (payload['exp'] is num) {
        // 2. Si es un número, lo obtenemos de forma segura.
        final num exp = payload['exp'];
        // 3. Lo convertimos a entero y luego a una fecha.
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
        // 4. Comparamos con la fecha y hora actual.
        return DateTime.now().isBefore(expirationTime);
      }
      // Si 'exp' no existe o no es un número, el token es inválido.
      return false;
    } catch (e) {
      print('Error al validar el token: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/inicio_splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          // child: Image.asset('assets/logo.png', width: 200),
        ),
      ),
    );
  }
}