import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'token_service.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  // Obtener el token más reciente
  Future<String?> _getCurrentToken() async {
    if (token != null) return token;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<http.Response> get(String endpoint) async {
    final currentToken = await _getCurrentToken();
    final response = await http.get(
        Uri.parse('${Config.apiUrl2}/$endpoint'),
        headers: await _headers(currentToken)
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> getList(String endpoint) async {
    final currentToken = await _getCurrentToken();
    final response = await http.get(
        Uri.parse('${Config.apiUrl}/$endpoint'),
        headers: await _headers(currentToken)
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final currentToken = await _getCurrentToken();
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/$endpoint'),
      headers: await _headers(currentToken),
      body: jsonEncode(data),
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final currentToken = await _getCurrentToken();
    final response = await http.patch(
      Uri.parse('${Config.apiUrl}/$endpoint'),
      headers: await _headers(currentToken),
      body: jsonEncode(data),
    );
    await _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final currentToken = await _getCurrentToken();
    final response = await http.delete(
        Uri.parse('${Config.apiUrl}/$endpoint'),
        headers: await _headers(currentToken)
    );
    await _handleResponse(response);
    return response;
  }

  Future<Map<String, String>> _headers(String? currentToken) async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (currentToken != null) 'Authorization': 'Bearer $currentToken',
    };
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Token expirado, intentar renovar
      bool refreshed = await TokenService.instance.refreshTokenManually();
      if (!refreshed) {
        throw Exception('Token expirado y no se pudo renovar');
      }
    } else if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }
}