import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'token_service.dart';

/// Resultado de un intento de inicio de sesión.
class LoginResult {
  const LoginResult._(this.ok, this.message);

  const LoginResult.success() : this._(true, null);
  const LoginResult.failure(String message) : this._(false, message);

  final bool ok;
  final String? message;
}

/// Inicio de sesión y guardado de la sesión en el dispositivo (compartido por
/// las pantallas de inicio de sesión y registro).
class AuthSession {
  AuthSession._();

  static Future<LoginResult> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'rememberMe': rememberMe,
        }),
      );
    } catch (_) {
      return const LoginResult.failure('No hay conexión a internet. Revísala e inténtalo de nuevo.');
    }

    if (response.statusCode == 401) {
      return const LoginResult.failure('Usuario o contraseña incorrectos.');
    }
    if (response.statusCode == 403) {
      return const LoginResult.failure(
          'Tu usuario aún no tiene un rol asignado. Contacta a tu empresa o a soporte.');
    }
    if (response.statusCode != 200) {
      return const LoginResult.failure('No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.');
    }

    try {
      final body = jsonDecode(response.body);
      if (body['success'] != true || body['data'] == null) {
        return const LoginResult.failure('No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.');
      }
      final saved = await _save(body['data']);
      if (!saved) {
        return const LoginResult.failure('No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.');
      }
    } catch (_) {
      return const LoginResult.failure('No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.');
    }

    await TokenService.instance.initializeTokenRefresh();
    return const LoginResult.success();
  }

  static Future<bool> _save(Map<String, dynamic> data) async {
    final user = data['user'];
    final token = data['token'];
    if (user == null || token == null) return false;

    final userId = user['id'];
    final email = user['email'];
    final username = user['username'];
    if (userId == null || email == null || username == null) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    final refreshToken = data['refreshToken'];
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
    } else {
      await prefs.remove('refreshToken');
    }

    await prefs.setBool('isDay21Completed', data['isDay21Completed'] ?? false);
    await prefs.setString('username', username);
    await prefs.setInt('userId', userId is int ? userId : int.parse(userId.toString()));
    await prefs.setString('email', email);

    // Permisos del flujo inicial
    await prefs.setBool('userresponsebool', data['responsebool'] ?? false);
    await prefs.setBool('testestresbool', data['testresresponsebool'] ?? false);
    await prefs.setBool('permisopoliticas', data['permisopoliticas'] ?? false);

    final companyId = user['company_id'];
    final companyIdInt = companyId is String ? int.tryParse(companyId) : companyId;
    if (companyIdInt is int) {
      await prefs.setInt('company_id', companyIdInt);
    }
    return true;
  }
}
