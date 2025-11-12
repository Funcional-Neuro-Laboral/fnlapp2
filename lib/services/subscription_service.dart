import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class SubscriptionService {
  static Future<Map<String, dynamic>> checkFeatureAccess(String feature) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('${Config.apiUrl2}/subscriptions/check-access/$feature'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al verificar acceso: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en checkFeatureAccess: $e');
      rethrow;
    }
  }

  static Future<bool> hasAccessToPrograms() async {
    try {
      final result = await checkFeatureAccess('access_programs');
      return result['data']['hasAccess'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasAccessToChatPro() async {
    try {
      final result = await checkFeatureAccess('access_chat_pro');
      return result['data']['hasAccess'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasAccessToActivities() async {
    try {
      final result = await checkFeatureAccess('access_activities');
      return result['data']['hasAccess'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
