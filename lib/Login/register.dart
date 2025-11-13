import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Util/token_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController namesController = TextEditingController();
  final TextEditingController lastnamesController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> passwordVisible = ValueNotifier(false);
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState == null) {
        print("Form is not initialized yet");
      }
    });
  }

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final names = namesController.text.trim();
    final lastnames = lastnamesController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/register'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'names': names,
          'lastnames': lastnames,
          'email': email,
          'company_id': '8',
          'role_id': '1',
        }),
      );

      setState(() {
        isLoading = false;
      });

      print('Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Hacer login automático después del registro exitoso
        await _autoLogin(context, username, password);
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 
                            responseBody['error'] ?? 
                            'Error al registrar usuario';
        _showSnackBar(context, errorMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      _showSnackBar(context, 'Error: Intentar nuevamente o Contactar al soporte');
    }
  }

  Future<void> _autoLogin(BuildContext context, String username, String password) async {
    try {
      final loginResponse = await http.post(
        Uri.parse('${Config.apiUrl2}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'rememberMe': false,
        }),
      );

      print('Login response body: ${loginResponse.body}');
      if (loginResponse.statusCode == 200) {
        await _handleLoginResponse(context, loginResponse);
      } else {
        _showSnackBar(context, 'Registro exitoso. Por favor inicia sesión manualmente.', isSuccess: true);
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } catch (e) {
      print('Error en auto-login: $e');
      _showSnackBar(context, 'Registro exitoso. Por favor inicia sesión manualmente.', isSuccess: true);
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _handleLoginResponse(BuildContext context, http.Response response) async {
    final responseBody = jsonDecode(response.body);

    if (responseBody['success'] == true && responseBody['data'] != null) {
      final data = responseBody['data'];
      final user = data['user'];
      final token = data['token'];
      final refreshToken = data['refreshToken'];

      final userId = user['id'];
      final email = user['email'];
      final username = user['username']; 
      final isDay21Completed = data['isDay21Completed'] ?? false;

      // Extraer permisos directamente de la respuesta del login
      final responsebool = data['responsebool'] ?? false;
      final testresresponsebool = data['testresresponsebool'] ?? false;
      final permisopoliticas = data['permisopoliticas'] ?? false;

      if (token != null && username != null && userId != null && email != null) {
        await _saveUserData(token, username, userId, email, refreshToken, isDay21Completed);
        await _savePermissions(responsebool, testresresponsebool, permisopoliticas);

        // Inicializar el servicio de renovación de tokens
        await TokenService.instance.initializeTokenRefresh();

        _showSnackBar(context, 'Registro exitoso. Sesión iniciada.', isSuccess: true);
        _navigateBasedOnPermission(context);
      } else {
        _showSnackBar(context, 'Datos de autenticación no recibidos');
      }
    } else {
      _showSnackBar(context, 'Error en la respuesta del servidor');
    }
  }

  Future<void> _savePermissions(bool responsebool, bool testresresponsebool, bool permisopoliticas) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Guardar permisos usando los nombres que ya tienes en tu app
      await prefs.setBool('userresponsebool', responsebool);
      await prefs.setBool('testestresbool', testresresponsebool);
      await prefs.setBool('permisopoliticas', permisopoliticas);

      print('Permisos guardados desde registro:');
      print('  - userresponsebool: $responsebool');
      print('  - testestresbool: $testresresponsebool');
      print('  - permisopoliticas: $permisopoliticas');
    } catch (e) {
      print('Error guardando permisos: $e');
    }
  }

  Future<void> _saveUserData(String token, String username, int userId, String email, String? refreshToken, bool? isDay21Completed) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);

    // Solo guardar refreshToken si no es null
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
    } else {
      await prefs.remove('refreshToken');
    }

    if (isDay21Completed != null) {
      await prefs.setBool('isDay21Completed', isDay21Completed);
    } else {
      await prefs.remove('isDay21Completed'); 
    } 

    await prefs.setString('username', username);
    await prefs.setInt('userId', userId);
    await prefs.setString('email', email);

    print("TOKEN GUARDADO en SharedPreferences: $token");
  }

  void _navigateBasedOnPermission(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
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
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Espacio superior para el logo
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
                            flex: 5,
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Texto de registro
                                      Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              'Registrarse',
                                              style: TextStyle(
                                                color: const Color(0xFF020107),
                                                fontSize: 32,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Es rápido y fácil',
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
                                      SizedBox(height: 24),

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
                                          _buildTextField('Nombre de usuario', usernameController),
                                          SizedBox(height: 16),

                                          // Campo de Nombre
                                          Text(
                                            'Nombre',
                                            style: TextStyle(
                                              color: const Color(0xFF212121),
                                              fontSize: 16,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          _buildTextField('Nombre y apellido', namesController),
                                          SizedBox(height: 16),

                                          // Campo de Apellidos
                                          Text(
                                            'Apellidos',
                                            style: TextStyle(
                                              color: const Color(0xFF212121),
                                              fontSize: 16,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          _buildTextField('Apellidos', lastnamesController),
                                          SizedBox(height: 16),

                                          // Campo de Correo
                                          Text(
                                            'Correo',
                                            style: TextStyle(
                                              color: const Color(0xFF212121),
                                              fontSize: 16,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          _buildTextField('Tu correo', emailController, keyboardType: TextInputType.emailAddress),
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
                                          _buildTextField('Nueva contraseña', passwordController, obscureText: true),
                                        ],
                                      ),
                                      SizedBox(height: 24),

                                      // Botón de Registro
                                      isLoading
                                          ? Center(child: CircularProgressIndicator())
                                          : Container(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _register(context),
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
                                            'Crear cuenta',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),

                                      // Enlace para ir a login
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacementNamed(context, '/login');
                                          },
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: const Color(0xFF333333),
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                              ),
                                              children: [
                                                TextSpan(text: '¿Ya tienes cuenta? '),
                                                TextSpan(
                                                  text: 'Inicia sesión',
                                                  style: TextStyle(
                                                    color: const Color(0xFF290B47),
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
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
            keyboardType: keyboardType,
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
              if (keyboardType == TextInputType.emailAddress) {
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Ingresa un correo válido';
                }
              }
              if (obscureText && value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

