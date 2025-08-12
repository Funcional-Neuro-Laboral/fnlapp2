import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Main/recuperarcontra.dart';
import '../config.dart'; // Importa el archivo de configuración
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> passwordVisible = ValueNotifier(false);
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isLoading = false;  // Variable para controlar el estado de carga
  final ValueNotifier<bool> rememberMe = ValueNotifier(false);  // Variable para el checkbox de recordar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState == null) {
        print("Form is not initialized yet");
      }
    });
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final username = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;  // Activar el indicador de carga
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      setState(() {
        isLoading = false;  // Desactivar el indicador de carga
      });

      if (response.statusCode == 200) {
        await _handleLoginResponse(context, response);
      } else if (response.statusCode == 401) {
        _showSnackBar(context, 'Credenciales Invalidas');
      } else if (response.statusCode == 403) {
        _showSnackBar(context, 'Usuario sin un rol');
      } else {
        _showSnackBar(context, 'Error desconocido: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;  // Desactivar el indicador de carga en caso de error
      });
      print(e);
      _showSnackBar(context, 'Error: Intentar nuevamente o Contactar al soporte');
    }
  }

  Future<void> _handleLoginResponse(BuildContext context, http.Response response) async {
    final responseBody = jsonDecode(response.body);
    final token = responseBody['token'];
    final username = responseBody['username'];
    final userId = responseBody['userId'];
    final email = responseBody['email'];
    final role = responseBody['role'];

    if (role == 'User') {
      if (token != null && username != null && userId != null && email != null) {
        await _saveUserData(token, username, userId, email);


        await _fetchAndSavePermissions(userId);


        _navigateBasedOnPermission(context);
      } else {
        _showSnackBar(context, 'Datos de autenticación no recibidos');
      }
    } else {
      _showSnackBar(context, 'Usuario no autorizado');
    }
  }

    Future<void> _fetchAndSavePermissions(int userId) async {
      try {
        final response = await http.get(
          Uri.parse('${Config.apiUrl}/users/getpermisos/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Verificar si la clave 'permisos' existe y no es nula
          final permisos = data['permisos'];
          
          if (permisos != null) {
            // Verificar que las claves dentro de 'permisos' no sean nulas
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('permisopoliticas', permisos['permisopoliticas'] ?? false);
            await prefs.setBool('userresponsebool', permisos['userresponsebool'] ?? false);
            await prefs.setBool('testestresbool', permisos['testestresbool'] ?? false);

            print('Permisos guardados: $permisos');
          } else {
            print('Error: No se encontraron permisos en la respuesta.');
          }
        } else {
          print('Error en la solicitud: ${response.statusCode}');
        }
      } catch (e) {
        print('Error obteniendo permisos: $e');
      }
    }

  Future<void> _saveUserData(String token, String username, int userId, String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('username', username);
    await prefs.setInt('userId', userId);
    await prefs.setString('email', email);

    print("TOKEN GUARDADO en SharedPreferences: $token");
  }

  void _navigateBasedOnPermission(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantalla completo
          Positioned.fill(
            child: Container(
              color: Color(0xFF5027D0),
              child: SvgPicture.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/wallpaper+log-in.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Contenido sobrepuesto
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Usar SizedBox en lugar de SingleChildScrollView para web
                return SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: Column(
                    children: [
                      // Espacio superior para el logo (flexible)
                      Flexible(
                        flex: 2,
                        child: Center(
                          child: Image.network(
                            'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Contenedor blanco sobrepuesto
                      Flexible(
                        flex: 5, // Más espacio para el contenido
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width > 600
                                ? 900
                                : double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir espacio uniformemente
                                  children: [
                                    // Texto bienvenida
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Bienvenido!',
                                            style: TextStyle(
                                              color: const Color(0xFF020107),
                                              fontSize: 32,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Ingresa tu usuario y contraseña',
                                            style: TextStyle(
                                              color: const Color(0xFF020107),
                                              fontSize: 18,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Campos de formulario
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Campo de Usuario
                                        Text(
                                          'Usuario',
                                          style: TextStyle(
                                            color: const Color(0xFF212121),
                                            fontSize: 16,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        _buildTextField('Nombre de Usuario', emailController),
                                        SizedBox(height: 16),

                                        // Campo de Contraseña
                                        Text(
                                          'Contraseña',
                                          style: TextStyle(
                                            color: const Color(0xFF212121),
                                            fontSize: 16,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        _buildTextField('Escriba su contraseña', passwordController, obscureText: true),
                                      ],
                                    ),

                                    // Recuérdame y olvidé mi contraseña
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        ValueListenableBuilder<bool>(
                                          valueListenable: rememberMe,
                                          builder: (context, value, child) {
                                            return Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => rememberMe.value = !value,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: const Color(0xFF52178F),
                                                        width: 1.27,
                                                      ),
                                                      borderRadius: BorderRadius.circular(2.55),
                                                      color: value ? const Color(0xFF52178F) : Colors.transparent,
                                                    ),
                                                    child: value
                                                        ? Icon(Icons.check, size: 10, color: Colors.white)
                                                        : null,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Recuérdame',
                                                  style: TextStyle(
                                                    color: const Color(0xFF333333),
                                                    fontSize: 14,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Olvidé mi contraseña',
                                            style: TextStyle(
                                              color: const Color(0xFF290B47),
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Botón de Login
                                    isLoading
                                        ? Center(child: CircularProgressIndicator())
                                        : Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _login(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6D4BD8),
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(40),
                                          ),
                                          elevation: 6,
                                          shadowColor: Color(0x26000000),
                                        ),
                                        child: Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Marca
                                    Center(
                                      child: Text(
                                        'App para estudiantes',
                                        style: TextStyle(
                                          color: const Color(0x6652178F),
                                          fontSize: 16,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller, {bool obscureText = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF7F7F7F),
          width: 1.0,
        ),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: passwordVisible,
        builder: (context, isPasswordVisible, child) {
          return TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              suffixIcon: obscureText
                  ? ValueListenableBuilder<bool>(
                valueListenable: passwordVisible,
                builder: (context, value, child) {
                  return IconButton(
                    icon: Icon(
                      value ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => passwordVisible.value = !value,
                  );
                },
              )
                  : null,
            ),
            obscureText: obscureText && !isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
