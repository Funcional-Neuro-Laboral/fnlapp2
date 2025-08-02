import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart'; 

class ApiService {
  final String? token;

  ApiService({this.token});

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(Uri.parse('${Config.apiUrl}/$endpoint'), headers: _headers());
    _handleResponse(response);
    return response;
  }

  Future<http.Response> getList(String endpoint) async {
    final response = await http.get(Uri.parse('${Config.apiUrl}/$endpoint'), headers: _headers());
    _handleResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/$endpoint'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('${Config.apiUrl}/$endpoint'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('${Config.apiUrl}/$endpoint'), headers: _headers());
    _handleResponse(response);
    return response;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }
}
