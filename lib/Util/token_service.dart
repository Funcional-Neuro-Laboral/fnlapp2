import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class TokenService {
  static TokenService? _instance;
  static TokenService get instance => _instance ??= TokenService._();

  TokenService._();

  Timer? _refreshTimer;

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
      print('No hay refresh token disponible');
      return;
    }

    // Programar renovación cada 1 hora y 50 minutos (110 minutos)
    const refreshInterval = Duration(minutes: 110);

    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      await _refreshAccessToken();
    });

    print('Timer de renovación de token programado cada ${refreshInterval.inMinutes} minutos');
  }

  // Renovar el access token
  Future<bool> _refreshAccessToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refreshToken');

      if (refreshToken == null) {
        print('No hay refresh token para renovar');
        await _handleTokenRefreshFailure();
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
          final data = responseBody['data'];
          final newToken = data['token'];

          if (newToken != null) {
            // Guardar el nuevo token
            await prefs.setString('token', newToken);
            print('Token renovado exitosamente');
            return true;
          }
        }
      } else {
        print('Error renovando token: ${response.statusCode}');
        await _handleTokenRefreshFailure();
      }
    } catch (e) {
      print('Error en renovación de token: $e');
      await _handleTokenRefreshFailure();
    }

    return false;
  }

  // Manejar fallo en renovación de token
  Future<void> _handleTokenRefreshFailure() async {
    print('Fallo en renovación de token - cerrando sesión');
    await logout();
  }

  // Metodo público para renovar token manualmente
  Future<bool> refreshTokenManually() async {
    return await _refreshAccessToken();
  }

  Future<bool> logoutFromServer({bool logoutAll = false}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refreshToken');
      String? accessToken = prefs.getString('token'); // Obtener el access token

      if (refreshToken == null) {
        print('No hay refresh token para logout');
        return false;
      }

      if (accessToken == null) {
        print('No hay access token para logout');
        return false;
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Agregar el access token
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
          'logoutAll': logoutAll,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true) {
          print('Logout exitoso: ${responseBody['message']}');
          return true;
        }
      } else {
        print('Error en logout: ${response.statusCode}');
        // Imprimir más detalles del error
        try {
          final errorBody = jsonDecode(response.body);
          print('Detalles del error: ${errorBody['message']}');
        } catch (e) {
          print('Error parseando respuesta de error');
        }
      }
    } catch (e) {
      print('Error en logout del servidor: $e');
    }

    return false;
  }

  // Limpiar recursos y cerrar sesión
  Future<void> logout({bool logoutAll = false}) async {
    // Primero intentar logout en el servidor
    await logoutFromServer(logoutAll: logoutAll);

    // Limpiar datos locales independientemente del resultado
    _refreshTimer?.cancel();
    _refreshTimer = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print('Sesión cerrada - tokens eliminados');
  }

  // Detener el servicio
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}