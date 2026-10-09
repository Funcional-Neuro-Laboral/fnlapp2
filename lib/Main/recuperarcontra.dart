import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

const Color _fpPrimary = Color(0xFF6D4BD8);
const Color _fpPrimaryDark = Color(0xFF4A2FB8);
const Color _fpTextDark = Color(0xFF0F0A2E);
const Color _fpBackground = Color(0xFFFCFBFF);

const String _fpLogoUrl =
    'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/fnl/f24c3b81-229f-4fd8-9e07-99074e44cc88.png';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
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
        _showSnackBar('Error al restablecer la contraseña. Verifica los datos.');
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _fpBackground,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _decorativeBlob(220, _fpPrimary.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _decorativeBlob(260, _fpPrimary.withOpacity(0.08)),
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
                                Image.network(
                                  _fpLogoUrl,
                                  height: 96,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.psychology_alt_rounded,
                                      size: 72,
                                      color: _fpPrimary,
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),

                                Form(
                                  key: _formKey,
                                  child: _getCurrentStepContent(),
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

  Widget _decorativeBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

  Widget _stepTitle(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _fpTextDark,
          fontSize: 30,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _stepSubtitle(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 15.5,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      );

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextAlign textAlign = TextAlign.start,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E1F2), width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textAlign: textAlign,
        style: const TextStyle(fontSize: 15.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.5),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [_fpPrimary, _fpPrimaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _fpPrimary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepTitle('Recuperar contraseña'),
        const SizedBox(height: 10),
        _stepSubtitle(
          'Ingresa tu correo electrónico y te ayudaremos a restablecer tu contraseña.',
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Dirección de correo electrónico'),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: emailController,
              hintText: 'ejemplo@correo.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Continuar',
          onPressed: _handleEmailStep,
          loading: isLoading,
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepTitle('Verificar código'),
        const SizedBox(height: 10),
        _stepSubtitle(
          'Hemos enviado un código de verificación de 6 dígitos a tu correo electrónico.',
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Código de verificación'),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: codeController,
              hintText: 'XXXXXX',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading ? null : () => _resendCode(),
          child: const Text(
            '¿No recibiste el código? Reenviar',
            style: TextStyle(
              color: _fpPrimary,
              fontSize: 14.5,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _primaryButton(
          label: 'Verificar código',
          onPressed: _handleCodeStep,
          loading: isLoading,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepTitle('Recuperar contraseña'),
        const SizedBox(height: 10),
        _stepSubtitle('¡Bien! Ya casi estamos. Ingresa una nueva contraseña.'),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Nueva contraseña'),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: passwordController,
              hintText: 'Ingresa tu nueva contraseña',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
            const SizedBox(height: 18),
            _fieldLabel('Repetir contraseña'),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: confirmPasswordController,
              hintText: 'Repite tu nueva contraseña',
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
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
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Cambiar contraseña',
          onPressed: _handlePasswordStep,
          loading: isLoading,
        ),
      ],
    );
  }

  Widget _buildFinishStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Image.network(
            'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_like.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.check_circle_rounded,
                size: 100,
                color: _fpPrimary,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _stepTitle('¡Contraseña restablecida\nexitosamente!'),
        const SizedBox(height: 12),
        _stepSubtitle('Funcy está orgulloso de ti ;)\nYa puedes iniciar sesión con tu nueva contraseña.'),
        const SizedBox(height: 32),
        _primaryButton(
          label: '¡Vamos!',
          onPressed: () => Navigator.of(context).pop(),
        ),
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