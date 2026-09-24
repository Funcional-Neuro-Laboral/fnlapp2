import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Util/token_service.dart';
import 'login.dart' show FnlColors;

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

  // ---------------------------------------------------------------------
  // Lógica de negocio (sin cambios funcionales respecto a la versión original)
  // ---------------------------------------------------------------------

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate())
      return;

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
      _showSnackBar(
          context, 'Error: Intentar nuevamente o Contactar al soporte');
    }
  }

  Future<void> _autoLogin(
      BuildContext context, String username, String password) async {
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
        _showSnackBar(
            context, 'Registro exitoso. Por favor inicia sesión manualmente.',
            isSuccess: true);
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } catch (e) {
      print('Error en auto-login: $e');
      _showSnackBar(
          context, 'Registro exitoso. Por favor inicia sesión manualmente.',
          isSuccess: true);
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _handleLoginResponse(
      BuildContext context, http.Response response) async {
    final responseBody = jsonDecode(response.body);

    if (responseBody['success'] == true && responseBody['data'] != null) {
      final data = responseBody['data'];
      final user = data['user'];
      final token = data['token'];
      final refreshToken = data['refreshToken'];

      final userId = user['id'];
      final email = user['email'];
      final username = user['username'];
      final companyId = user['company_id']; // Puede ser string o int
      final isDay21Completed = data['isDay21Completed'] ?? false;

      // Extraer permisos directamente de la respuesta del login
      final responsebool = data['responsebool'] ?? false;
      final testresresponsebool = data['testresresponsebool'] ?? false;
      final permisopoliticas = data['permisopoliticas'] ?? false;

      if (token != null &&
          username != null &&
          userId != null &&
          email != null) {
        await _saveUserData(
            token, username, userId, email, refreshToken, isDay21Completed);
        await _savePermissions(
            responsebool, testresresponsebool, permisopoliticas);

        // Guardar company_id si está disponible
        if (companyId != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int? companyIdInt =
              companyId is String ? int.tryParse(companyId) : companyId;
          if (companyIdInt != null) {
            await prefs.setInt('company_id', companyIdInt);
            print('company_id guardado en SharedPreferences: $companyIdInt');
          }
        }

        // Inicializar el servicio de renovación de tokens
        await TokenService.instance.initializeTokenRefresh();

        _showSnackBar(context, 'Registro exitoso. Sesión iniciada.',
            isSuccess: true);
        _navigateBasedOnPermission(context);
      } else {
        _showSnackBar(context, 'Datos de autenticación no recibidos');
      }
    } else {
      _showSnackBar(context, 'Error en la respuesta del servidor');
    }
  }

  Future<void> _savePermissions(bool responsebool, bool testresresponsebool,
      bool permisopoliticas) async {
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

  Future<void> _saveUserData(String token, String username, int userId,
      String email, String? refreshToken, bool? isDay21Completed) async {
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

  void _showSnackBar(BuildContext context, String message,
      {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: FnlColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isWeb = screenWidth > 900;
          final isTablet = screenWidth > 600 && screenWidth <= 900;
          final isWide = screenWidth > 600;

          final fieldSpacing = isWeb ? 18.0 : 16.0;
          final contentMaxWidth = isWeb ? 640.0 : (isTablet ? 560.0 : 420.0);

          return Stack(
            children: [
              // Mismo fondo del login: claro, con formas suaves en las
              // esquinas, en vez del wallpaper morado a pantalla completa.
              Positioned(
                top: -60,
                right: -60,
                child: _decorativeBlob(220, FnlColors.primary.withOpacity(0.10)),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: _decorativeBlob(260, FnlColors.primary.withOpacity(0.08)),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo de marca, mismo activo ya usado en la app.
                            Image.network(
                              'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/fnl/f24c3b81-229f-4fd8-9e07-99074e44cc88.png',
                              height: 88,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.psychology_alt_rounded,
                                  size: 64,
                                  color: FnlColors.primary,
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Registrarse',
                              style: TextStyle(
                                color: FnlColors.textDark,
                                fontSize: 30,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Es rápido y fácil',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15.5,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 28),

                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isWide) ...[
                                    // Layout en dos columnas para tablet/web.
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildFieldColumn([
                                            _buildLabeledField(
                                              'Usuario',
                                              'Nombre de usuario',
                                              usernameController,
                                              icon: Icons.person_outline_rounded,
                                              spacing: fieldSpacing,
                                            ),
                                            _buildLabeledField(
                                              'Nombre',
                                              'Nombre completo',
                                              namesController,
                                              icon: Icons.badge_outlined,
                                              spacing: fieldSpacing,
                                            ),
                                            _buildLabeledField(
                                              'Correo',
                                              'Tu correo',
                                              emailController,
                                              icon: Icons.email_outlined,
                                              spacing: fieldSpacing,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                          ]),
                                        ),
                                        SizedBox(width: fieldSpacing * 1.5),
                                        Expanded(
                                          child: _buildFieldColumn([
                                            _buildLabeledField(
                                              'Apellidos',
                                              'Apellidos',
                                              lastnamesController,
                                              icon: Icons.badge_outlined,
                                              spacing: fieldSpacing,
                                            ),
                                            _buildLabeledField(
                                              'Contraseña',
                                              'Nueva contraseña',
                                              passwordController,
                                              icon: Icons.lock_outline_rounded,
                                              spacing: fieldSpacing,
                                              obscureText: true,
                                            ),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // Layout vertical para móvil.
                                    _buildLabeledField(
                                      'Usuario',
                                      'Nombre de usuario',
                                      usernameController,
                                      icon: Icons.person_outline_rounded,
                                      spacing: fieldSpacing,
                                    ),
                                    _buildLabeledField(
                                      'Nombre',
                                      'Nombre completo',
                                      namesController,
                                      icon: Icons.badge_outlined,
                                      spacing: fieldSpacing,
                                    ),
                                    _buildLabeledField(
                                      'Apellidos',
                                      'Apellidos',
                                      lastnamesController,
                                      icon: Icons.badge_outlined,
                                      spacing: fieldSpacing,
                                    ),
                                    _buildLabeledField(
                                      'Correo',
                                      'Tu correo',
                                      emailController,
                                      icon: Icons.email_outlined,
                                      spacing: fieldSpacing,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    _buildLabeledField(
                                      'Contraseña',
                                      'Nueva contraseña',
                                      passwordController,
                                      icon: Icons.lock_outline_rounded,
                                      spacing: fieldSpacing,
                                      obscureText: true,
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // Botón "Crear cuenta": mismo relleno
                                  // degradado y flecha que "Iniciar sesión"
                                  // en el login.
                                  SizedBox(
                                    width: double.infinity,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40),
                                        gradient: const LinearGradient(
                                          colors: [
                                            FnlColors.primary,
                                            FnlColors.primaryDark,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: FnlColors.primary
                                                .withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            isLoading ? null : () => _register(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Crear cuenta',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 20),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Enlace para ir a login.
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(
                                            context, '/login');
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                          ),
                                          children: const [
                                            TextSpan(text: '¿Ya tienes cuenta? '),
                                            TextSpan(
                                              text: 'Inicia sesión',
                                              style: TextStyle(
                                                color: FnlColors.primary,
                                                fontWeight: FontWeight.w700,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _decorativeBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildFieldColumn(List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }

  Widget _buildLabeledField(
    String label,
    String hint,
    TextEditingController controller, {
    required IconData icon,
    required double spacing,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF212121),
              fontSize: 14.5,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField(
            hint,
            controller,
            icon: icon,
            obscureText: obscureText,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hintText,
    TextEditingController controller, {
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E1F2), width: 1.2),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: passwordVisible,
        builder: (context, isPasswordVisible, child) {
          return TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 21),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.5),
              suffixIcon: obscureText
                  ? ValueListenableBuilder<bool>(
                      valueListenable: passwordVisible,
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            value
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.grey[600],
                            size: 20,
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