import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../theme/app_colors.dart';
import '../Util/token_service.dart';
import '../widgets/brand_background.dart';

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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      await prefs.remove('token');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // Si el token venció, se intenta renovar antes de entrar.
    if (!_isTokenValid(token)) {
      final refreshed = await TokenService.instance.refreshTokenManually(notify: false);
      if (!refreshed) {
        final stillHasToken = prefs.getString('token') != null;
        if (!mounted) return;
        if (!stillHasToken) {
          // El servidor rechazó la sesión: volver a iniciar sesión.
          Navigator.pushReplacementNamed(context, '/login', arguments: LoginArgs.sessionExpired);
          return;
        }
        // Sin conexión: se continúa y la app mostrará el estado sin conexión.
      }
    }

    await TokenService.instance.initializeTokenRefresh();

    final permisopoliticas = prefs.getBool('permisopoliticas') ?? false;
    final userresponsebool = prefs.getBool('userresponsebool') ?? false;
    final testestresbool = prefs.getBool('testestresbool') ?? false;

    if (!mounted) return;
    if (permisopoliticas && userresponsebool && testestresbool) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/index');
    }
  }

  bool _isTokenValid(String token) {
    try {
      final payload = JWT.decode(token).payload;
      if (payload is Map && payload['exp'] is num) {
        final num exp = payload['exp'];
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
        return DateTime.now().isBefore(expirationTime);
      }
      // Sin fecha de expiración: se considera válido y el servidor decide.
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BrandBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FnlLogo(width: 200),
              SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Argumentos opcionales al abrir la pantalla de inicio de sesión.
enum LoginArgs { sessionExpired }
