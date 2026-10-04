import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
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

  void _submitCurrentStep() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    switch (currentStep) {
      case 1:
        _sendResetEmail();
        break;
      case 2:
        _verifyCode();
        break;
      case 3:
        _resetPassword();
        break;
    }
  }

  void _nextStep() {
    setState(() {
      currentStep++;
    });
  }

  // Metodo para enviar codigo al correo
  Future<void> _sendResetEmail() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/recovery-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );
      if (!mounted) return;
      setState(() => isLoading = false);
      if (response.statusCode == 200) {
        _nextStep();
      } else {
        _showSnackBar('No pudimos enviar el correo. Revisa que la dirección sea correcta.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('No hay conexión a internet. Inténtalo de nuevo.');
    }
  }

  // Método para reenviar código
  Future<void> _resendCode() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/recovery-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar(response.statusCode == 200
          ? 'Te enviamos un nuevo código.'
          : 'No pudimos reenviar el código. Inténtalo de nuevo.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('No hay conexión a internet. Inténtalo de nuevo.');
    }
  }

  // Metodo para verificar codigo
  Future<void> _verifyCode() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/validate-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
        }),
      );
      if (!mounted) return;
      setState(() => isLoading = false);
      if (response.statusCode == 200) {
        _nextStep();
      } else {
        _showSnackBar('El código es incorrecto, expiró o ya se usó.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('No hay conexión a internet. Inténtalo de nuevo.');
    }
  }

  // Metodo para resetear la contraseña
  Future<void> _resetPassword() async {
    setState(() => isLoading = true);
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
      if (!mounted) return;
      setState(() => isLoading = false);
      if (response.statusCode == 200) {
        _nextStep();
      } else {
        _showSnackBar('No pudimos cambiar la contraseña. Verifica los datos.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('No hay conexión a internet. Inténtalo de nuevo.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(currentStep),
                          child: _buildStep(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (currentStep < 4)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    tooltip: currentStep == 1 ? 'Volver' : 'Paso anterior',
                    style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () {
                      if (currentStep == 1) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => currentStep--);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (currentStep) {
      case 1:
        return _StepLayout(
          title: 'Recuperar contraseña',
          subtitle: 'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
          children: [
            AppTextField(
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
              controller: emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submitCurrentStep(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Este campo es obligatorio';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(label: 'Enviar código', loading: isLoading, onPressed: _submitCurrentStep),
          ],
        );
      case 2:
        return _StepLayout(
          title: 'Verificar código',
          subtitle: 'Te enviamos un código de 6 dígitos a ${emailController.text.trim()}.',
          children: [
            AppTextField(
              label: 'Código de verificación',
              hint: '000000',
              controller: codeController,
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              onSubmitted: (_) => _submitCurrentStep(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Este campo es obligatorio';
                if (text.length != 6) return 'El código tiene 6 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : _resendCode,
                child: const Text('¿No recibiste el código? Reenviar'),
              ),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(label: 'Verificar código', loading: isLoading, onPressed: _submitCurrentStep),
          ],
        );
      case 3:
        return _StepLayout(
          title: 'Nueva contraseña',
          subtitle: '¡Bien! Ya casi estamos. Ingresa tu nueva contraseña.',
          children: [
            AppTextField(
              label: 'Nueva contraseña',
              hint: 'Mínimo 6 caracteres',
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Este campo es obligatorio';
                if (value.length < 6) return 'Usa al menos 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Repetir contraseña',
              hint: 'Repite tu nueva contraseña',
              controller: confirmPasswordController,
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitCurrentStep(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Este campo es obligatorio';
                if (value != passwordController.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(label: 'Cambiar contraseña', loading: isLoading, onPressed: _submitCurrentStep),
          ],
        );
      default:
        final textTheme = Theme.of(context).textTheme;
        return Column(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const FuncyImage(FuncyPose.celebra, size: 190, semanticLabel: 'Funcy celebrando'),
            ),
            const SizedBox(height: 24),
            Text('¡Contraseña actualizada!', style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Ya puedes iniciar sesión con tu nueva contraseña.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AppPrimaryButton(label: 'Ir a iniciar sesión', onPressed: () => Navigator.of(context).pop()),
          ],
        );
    }
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

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: FnlLogo(width: 176)),
          const SizedBox(height: 28),
          Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}
