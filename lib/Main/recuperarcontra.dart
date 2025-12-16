import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  int currentStep = 1; // 1: Email, 2: Code, 3: Password, 4: Finish
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _handleEmailStep() {
    if (_formKey.currentState!.validate()) {
      _sendResetEmail();
    }
  }

  void _handleCodeStep() {
    if (_formKey.currentState!.validate()) {
      _verifyCode();
    }
  }

  void _handlePasswordStep() {
    if (_formKey.currentState!.validate()) {
      _resetPassword();
    }
  }

  // Metodo para avanzar al siguiente paso
  void _nextStep() {
    setState(() {
      currentStep++;
    });
  }

  // Metodo para obtener el contenido según el paso actual
  Widget _getCurrentStepContent() {
    switch (currentStep) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildCodeStep();
      case 3:
        return _buildPasswordStep();
      case 4:
        return _buildFinishStep();
      default:
        return _buildEmailStep();
    }
  }

  // Metodo para enviar codigo al correo
  Future<void> _sendResetEmail() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/recovery-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        _nextStep(); // Avanzar al paso de verificación de código
      } else {
        _showSnackBar('Error al enviar el correo de recuperación');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error de conexión. Intenta nuevamente.');
    }
  }

  // Método para reenviar código
  Future<void> _resendCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/recovery-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        _showSnackBar('Código reenviado exitosamente');
      } else {
        _showSnackBar('Error al reenviar el código');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error de conexión. Intenta nuevamente.');
    }
  }

  // Metodo para verificar codigo
  Future<void> _verifyCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/validate-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        _nextStep(); // Avanzar al paso de nueva contraseña
      } else {
        _showSnackBar('Código incorrecto, expirado o ya utilizado.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error de conexión. Intenta nuevamente.');
    }
  }

  // Metodo para resetear la contraseña
  Future<void> _resetPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl2}/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
          'newPassword': passwordController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        _nextStep(); // Avanzar al paso final
      } else {
        _showSnackBar(
            'Error al restablecer la contraseña. Verifica los datos.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error de conexión. Intenta nuevamente.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Logo con padding fijo
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 20),
                    child: Image.network(
                      'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Contenedor blanco sobrepuesto
                  Container(
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Form(
                        key: _formKey,
                        child: _getCurrentStepContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4),
        Text(
          'Recuperar Contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020107),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Ingresa tu correo electrónico y te ayudaremos a restablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF020107),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 52),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirección de correo electrónico',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'ejemplo@correo.com',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    width: 1,
                    color: const Color(0xFF7F7F7F),
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
          ],
        ),
        Spacer(), // Esto empuja el botón hacia abajo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleEmailStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6D4BD8),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Color(0x26000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Continuar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4),
        Text(
          'Verificar código',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020107),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Hemos enviado un código de verificación de 6 digitos a tu correo electrónico.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF020107),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 52),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Código de verificación',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    width: 1,
                    color: const Color(0xFF7F7F7F),
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (value.length != 6) {
                  return 'El código debe tener 6 dígitos';
                }
                return null;
              },
            ),
          ],
        ),
        SizedBox(height: 24),
        TextButton(
          onPressed: isLoading ? null : () => _resendCode(),
          child: Text(
            '¿No recibiste el código? Reenviar',
            style: TextStyle(
              color: Color(0xFF6D4BD8),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Spacer(), // Esto empuja el botón hacia abajo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleCodeStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6D4BD8),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Color(0x26000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Verificar código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4),
        Text(
          'Recuperar Contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020107),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 16),
        Text(
          '¡Bien! Ya casi estamos. Ingresa una nueva contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF020107),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nueva contraseña',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Ingresa tu nueva contraseña',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.white,
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Text(
              'Repetir contraseña',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Repite tu nueva contraseña',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.white,
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (value != passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
        ),
        Spacer(), // Esto empuja el botón hacia abajo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handlePasswordStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6D4BD8),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Color(0x26000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFinishStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 32),
        // Imagen de Funcy
        Container(
          width: 200,
          height: 200,
          child: Image.network(
            'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_like.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.check_circle,
                size: 120,
                color: Color(0xFF6D4BD8),
              );
            },
          ),
        ),
        SizedBox(height: 22),
        Text(
          '¡Contraseña restablecida exitosamente!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020107),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Funcy está orgulloso de ti ;)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF020107),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          'Ya puedes iniciar sesión con tu nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF020107),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        Spacer(), // Esto empuja el botón hacia abajo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6D4BD8),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Color(0x26000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: Text(
              '¡Vamos!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
