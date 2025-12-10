import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class GooglePlayVerificationService {
  /// Verifica una compra de Google Play con el backend
  ///
  /// [purchaseToken] - Token de compra recibido de Google Play
  /// [productId] - ID del producto de suscripción (ej: "fnl_monthly_vip")
  ///
  /// Retorna un Map con:
  /// - success: bool
  /// - message: String
  /// - data: { planType: String, expiresAt: DateTime? }
  static Future<Map<String, dynamic>> verifyPurchase({
    required String purchaseToken,
    required String productId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      // 🧪 DEBUG: Log de datos enviados al backend
      print('════════════════════════════════════════');
      print('🧪 VERIFICACIÓN DE COMPRA - DEBUG');
      print('════════════════════════════════════════');
      print('📦 productId: $productId');
      print(
          '🎫 purchaseToken (primeros 80 chars): ${purchaseToken.length > 80 ? purchaseToken.substring(0, 80) : purchaseToken}...');
      print('🔗 Endpoint: ${Config.apiUrl2}/subscriptions/verify');
      print('════════════════════════════════════════');

      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/subscriptions/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'purchaseToken': purchaseToken,
          'productId': productId,
        }),
      );

      // 🧪 DEBUG: Log de respuesta del backend
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');
      print('════════════════════════════════════════');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': result['success'] ?? false,
          'message': result['message'] ?? '',
          'data': result['data'] ?? {},
        };
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Error al verificar compra: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en verifyPurchase: $e');
      rethrow;
    }
  }
}
