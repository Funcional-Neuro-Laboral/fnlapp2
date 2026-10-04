import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class TokenService {
  static TokenService? _instance;
  static TokenService get instance => _instance ??= TokenService._();

  TokenService._();

  Timer? _refreshTimer;

  /// Se llama cuando la sesión ya no se puede renovar (el servidor rechazó
  /// el refresh token). La app lo usa para avisar al usuario.
  VoidCallback? onSessionExpired;

  /// Preferencias del usuario que se conservan al cerrar sesión.
  static const _preservedKeys = ['stepTextSize'];

  // Inicializar el servicio de renovación de tokens
  Future<void> initializeTokenRefresh() async {
    await _scheduleTokenRefresh();
  }

  // Programar la renovación de tokens
  Future<void> _scheduleTokenRefresh() async {
    _refreshTimer?.cancel(); // Cancelar timer anterior si existe

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      debugPrint('No hay refresh token disponible');
      return;
    }

    // Programar renovación cada 1 hora y 50 minutos (110 minutos)
    const refreshInterval = Duration(minutes: 110);

    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      await _refreshAccessToken();
    });
  }

  // Renovar el access token
  Future<bool> _refreshAccessToken({bool notify = true}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refreshToken');

      if (refreshToken == null) {
        await _handleTokenRefreshFailure(notify: notify);
        return false;
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true && responseBody['data'] != null) {
          final newToken = responseBody['data']['token'];
          if (newToken != null) {
            await prefs.setString('token', newToken);
            return true;
          }
        }
      } else if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        // El servidor rechazó el refresh token: la sesión expiró.
        await _handleTokenRefreshFailure(notify: notify);
      } else {
        debugPrint('Error renovando token: ${response.statusCode}');
      }
    } catch (e) {
      // Error de red: no se cierra la sesión, se reintentará más tarde.
      debugPrint('Error de red al renovar token: $e');
    }

    return false;
  }

  // Manejar fallo en renovación de token
  Future<void> _handleTokenRefreshFailure({bool notify = true}) async {
    await clearLocalSession();
    if (notify) onSessionExpired?.call();
  }

  /// Renueva el token ahora. Con [notify] en falso no se muestra el aviso de
  /// sesión expirada (útil al abrir la app, que ya va al inicio de sesión).
  Future<bool> refreshTokenManually({bool notify = true}) async {
    return await _refreshAccessToken(notify: notify);
  }

  Future<bool> logoutFromServer({bool logoutAll = false}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refreshToken');
      String? accessToken = prefs.getString('token');

      if (refreshToken == null || accessToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
          'logoutAll': logoutAll,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['success'] == true;
      }
      debugPrint('Error en logout: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en logout del servidor: $e');
    }

    return false;
  }

  /// Borra los datos de sesión del dispositivo, conservando las preferencias
  /// del usuario (por ejemplo, el tamaño de texto).
  Future<void> clearLocalSession() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final prefs = await SharedPreferences.getInstance();
    final preserved = <String, Object?>{
      for (final key in _preservedKeys) key: prefs.get(key),
    };
    await prefs.clear();
    for (final entry in preserved.entries) {
      final value = entry.value;
      if (value is double) await prefs.setDouble(entry.key, value);
      if (value is int) await prefs.setInt(entry.key, value);
      if (value is String) await prefs.setString(entry.key, value);
      if (value is bool) await prefs.setBool(entry.key, value);
    }
  }

  // Limpiar recursos y cerrar sesión
  Future<void> logout({bool logoutAll = false}) async {
    // Primero intentar logout en el servidor
    await logoutFromServer(logoutAll: logoutAll);
    // Limpiar datos locales independientemente del resultado
    await clearLocalSession();
  }

  // Detener el servicio
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
