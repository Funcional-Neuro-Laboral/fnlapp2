import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Main/recuperarcontra.dart';
import '../Util/token_service.dart';
import '../config.dart'; // Importa el archivo de configuración
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Paleta usada en el mockup: violeta/índigo sobre fondo claro, en vez del
/// degradado morado a pantalla completa de la versión anterior.
class FnlColors {
  static const primary = Color(0xFF6D4BD8);
  static const primaryDark = Color(0xFF4A2FB8);
  static const textDark = Color(0xFF0F0A2E);
  static const background = Color(0xFFFCFBFF);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> passwordVisible = ValueNotifier(false);
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isLoading = false;
  final ValueNotifier<bool> rememberMe = ValueNotifier(false);

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

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'rememberMe': rememberMe.value,
        }),
      );

      setState(() => isLoading = false);

      print('Response body: ${response.body}');
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
      setState(() => isLoading = false);
      print(e);
      _showSnackBar(context, 'Error: Intentar nuevamente o Contactar al soporte');
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
      final companyId = user['company_id'];
      final isDay21Completed = data['isDay21Completed'] ?? false;

      final responsebool = data['responsebool'] ?? false;
      final testresresponsebool = data['testresresponsebool'] ?? false;
      final permisopoliticas = data['permisopoliticas'] ?? false;

      if (token != null && username != null && userId != null && email != null) {
        await _saveUserData(token, username, userId, email, refreshToken, isDay21Completed);
        await _savePermissions(responsebool, testresresponsebool, permisopoliticas);

        if (companyId != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int? companyIdInt = companyId is String ? int.tryParse(companyId) : companyId;
          if (companyIdInt != null) {
            await prefs.setInt('company_id', companyIdInt);
            print('company_id guardado en SharedPreferences: $companyIdInt');
          }
        }

        await TokenService.instance.initializeTokenRefresh();

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
      await prefs.setBool('userresponsebool', responsebool);
      await prefs.setBool('testestresbool', testresresponsebool);
      await prefs.setBool('permisopoliticas', permisopoliticas);

      print('Permisos guardados desde login:');
      print('  - userresponsebool: $responsebool');
      print('  - testestresbool: $testresresponsebool');
      print('  - permisopoliticas: $permisopoliticas');
    } catch (e) {
      print('Error guardando permisos: $e');
    }
  }

  Future<void> _saveUserData(String token, String username, int userId, String email,
      String? refreshToken, bool? isDay21Completed) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);

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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // Autenticación social: ganchos listos para conectar el SDK real de cada
  // proveedor (google_sign_in / sign_in_with_apple). Por ahora solo avisan
  // que falta esa integración, sin tocar el flujo de login por
  // usuario/contraseña de arriba.
  // ---------------------------------------------------------------------

  Future<void> _loginWithGoogle(BuildContext context) async {
    // TODO: integrar el paquete google_sign_in y enviar el token resultante
    // al mismo endpoint (o a uno equivalente) que usa _handleLoginResponse.
    _showSnackBar(context, 'Inicio de sesión con Google próximamente');
  }

  Future<void> _loginWithApple(BuildContext context) async {
    // TODO: integrar el paquete sign_in_with_apple y enviar la credencial
    // resultante al backend, igual que con Google.
    _showSnackBar(context, 'Inicio de sesión con Apple próximamente');
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: FnlColors.background,
      body: Stack(
        children: [
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWide ? 460 : 420),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo de marca
                                Image.network(
                                  'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/fnl/f24c3b81-229f-4fd8-9e07-99074e44cc88.png',
                                  height: 96,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.psychology_alt_rounded,
                                      size: 72,
                                      color: FnlColors.primary,
                                    );
                                  },
                                ),

                                const SizedBox(height: 28),

                                const Text(
                                  'Bienvenido',
                                  style: TextStyle(
                                    color: FnlColors.textDark,
                                    fontSize: 34,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inicia sesión para continuar\ncon tu bienestar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 15.5,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Usuario'),
                                      const SizedBox(height: 6),
                                      _buildTextField(
                                        'Nombre de usuario',
                                        usernameController,
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      const SizedBox(height: 18),

                                      _fieldLabel('Contraseña'),
                                      const SizedBox(height: 6),
                                      _buildTextField(
                                        'Escribe tu contraseña',
                                        passwordController,
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: true,
                                      ),
                                      const SizedBox(height: 14),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ValueListenableBuilder<bool>(
                                            valueListenable: rememberMe,
                                            builder: (context, value, child) {
                                              return GestureDetector(
                                                onTap: () => rememberMe.value = !value,
                                                behavior: HitTestBehavior.opaque,
                                                child: Row(
                                                  children: [
                                                    AnimatedContainer(
                                                      duration: const Duration(milliseconds: 150),
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: FnlColors.primary,
                                                          width: 1.4,
                                                        ),
                                                        borderRadius: BorderRadius.circular(5),
                                                        color: value
                                                            ? FnlColors.primary
                                                            : Colors.transparent,
                                                      ),
                                                      child: value
                                                          ? const Icon(Icons.check,
                                                              size: 13, color: Colors.white)
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Recuérdame',
                                                      style: TextStyle(
                                                        color: Color(0xFF333333),
                                                        fontSize: 13.5,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                                            child: const Text(
                                              'Olvidé mi contraseña',
                                              style: TextStyle(
                                                color: FnlColors.primary,
                                                fontSize: 13.5,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 26),

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
                                                color: FnlColors.primary.withOpacity(0.35),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : () => _login(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(40),
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
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Iniciar sesión',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(Icons.arrow_forward_rounded,
                                                          color: Colors.white, size: 20),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      Row(
                                        children: [
                                          Expanded(
                                              child: Divider(
                                                  color: Colors.grey[300], thickness: 1)),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.symmetric(horizontal: 14),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey[400]!, width: 1.4),
                                            ),
                                          ),
                                          Expanded(
                                              child: Divider(
                                                  color: Colors.grey[300], thickness: 1)),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(context, '/register');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            side: const BorderSide(
                                              color: FnlColors.primary,
                                              width: 1.6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(40),
                                            ),
                                          ),
                                          child: const Text(
                                            'Crear una cuenta',
                                            style: TextStyle(
                                              color: FnlColors.primary,
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ---------------------------------------------------
                                      // Botones de inicio de sesión social (Google / Apple).
                                      // ---------------------------------------------------
                                      // const SizedBox(height: 24),
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: _buildSocialButton(
                                      //         label: 'Google',
                                      //         icon: _googleIcon(),
                                      //         onTap: () => _loginWithGoogle(context),
                                      //       ),
                                      //     ),
                                      //     const SizedBox(width: 14),
                                      //     Expanded(
                                      //       child: _buildSocialButton(
                                      //         label: 'Apple',
                                      //         icon: const Icon(Icons.apple,
                                      //             color: Colors.black, size: 22),
                                      //         onTap: () => _loginWithApple(context),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),

                                      const SizedBox(height: 28),

                                      Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              'Tu bienestar también cuenta',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 36,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: FnlColors.primary,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF212121),
          fontSize: 14.5,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _decorativeBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _googleIcon() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: Colors.grey[300]!, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF212121),
              fontSize: 14.5,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
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
            style: const TextStyle(fontSize: 15.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 21),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.5),
              suffixIcon: obscureText
                  ? ValueListenableBuilder<bool>(
                      valueListenable: passwordVisible,
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
              return null;
            },
          );
        },
      ),
    );
  }
}