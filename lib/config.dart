import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  //static const String apiUrl = 'https://funcy.duckdns.org/api';
  //static const String imagenesUrl = 'https://funcy.duckdns.org/api';

  //static const String apiUrl = 'http://localhost:3000/api';
  //static const String apiUrl2 = 'http://localhost:8000/api';
  //static const String imagenesUrl = 'http://localhost:3000/api';
  //static const String wsUrl = 'ws://127.0.0.1:8000/ws';

  static String get apiUrl => dotenv.env['API_URL'] ?? _throwMissingEnv('API_URL');
  static String get apiUrl2 => dotenv.env['API_URL2'] ?? _throwMissingEnv('API_URL2');
  static String get imagenesUrl => dotenv.env['IMAGENES_URL'] ?? _throwMissingEnv('IMAGENES_URL');
  static String get wsUrl => dotenv.env['WS_URL'] ?? _throwMissingEnv('WS_URL');

  static String _throwMissingEnv(String key) {
    throw Exception('Variable de entorno $key no encontrada');
  }
}