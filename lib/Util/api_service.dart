import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'token_service.dart';

/// Error de una petición al servidor, con su código HTTP.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  final String? token;

  ApiService({this.token});

  // Obtener el token más reciente
  Future<String?> _getCurrentToken() async {
    if (token != null) return token;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Envía la petición; si el token expiró, lo renueva y reintenta una vez.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(_headers(await _getCurrentToken()));
    if (response.statusCode == 401 && token == null) {
      final refreshed = await TokenService.instance.refreshTokenManually();
      if (!refreshed) {
        throw ApiException(401, 'Token expirado y no se pudo renovar');
      }
      response = await request(_headers(await _getCurrentToken()));
    }
    _handleResponse(response);
    return response;
  }

  Future<http.Response> get(String endpoint) {
    return _send((headers) => http.get(Uri.parse('${Config.apiUrl2}/$endpoint'), headers: headers));
  }

  Future<http.Response> getList(String endpoint) {
    return _send((headers) => http.get(Uri.parse('${Config.apiUrl}/$endpoint'), headers: headers));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) {
    return _send((headers) => http.post(
          Uri.parse('${Config.apiUrl}/$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        ));
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> data) {
    return _send((headers) => http.patch(
          Uri.parse('${Config.apiUrl}/$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        ));
  }

  Future<http.Response> delete(String endpoint) {
    return _send((headers) => http.delete(Uri.parse('${Config.apiUrl}/$endpoint'), headers: headers));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) {
    return _send((headers) => http.put(
          Uri.parse('${Config.apiUrl}/$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        ));
  }

  Map<String, String> _headers(String? currentToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (currentToken != null) 'Authorization': 'Bearer $currentToken',
    };
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw ApiException(401, 'Token expirado y no se pudo renovar');
    } else if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }
}
