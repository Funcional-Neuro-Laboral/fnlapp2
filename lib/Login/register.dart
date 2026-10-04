import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../theme/app_colors.dart';
import '../Util/auth_session.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_background.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    namesController.dispose();
    lastnamesController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    setState(() {
      isLoading = true;
      _errorMessage = null;
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
          'names': namesController.text.trim(),
          'lastnames': lastnamesController.text.trim(),
          'email': emailController.text.trim(),
          'company_id': '8',
          'role_id': '1',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Inicio de sesión automático después del registro.
        final result = await AuthSession.login(username: username, password: password);
        if (!mounted) return;
        if (result.ok) {
          Navigator.pushReplacementNamed(context, '/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta creada. Inicia sesión para continuar.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      String message = 'No pudimos crear tu cuenta. Revisa los datos e inténtalo de nuevo.';
      try {
        final body = jsonDecode(response.body);
        final serverMessage = body['message'] ?? body['error'];
        if (serverMessage is String && serverMessage.isNotEmpty) message = serverMessage;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _errorMessage = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _errorMessage = 'No hay conexión a internet. Revísala e inténtalo de nuevo.';
      });
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Este campo es obligatorio' : null;

  String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Este campo es obligatorio';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Ingresa un correo válido';
  }

  String? _password(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    if (value.length < 6) return 'Usa al menos 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: FnlLogo(width: 150)),
                        const SizedBox(height: 24),
                        Text('Crea tu cuenta', style: textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          'Es rápido y tus datos están protegidos.',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Usuario',
                          hint: 'nombre.apellido',
                          controller: usernameController,
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newUsername],
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Nombres',
                          hint: 'Tus nombres',
                          controller: namesController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.givenName],
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Apellidos',
                          hint: 'Tus apellidos',
                          controller: lastnamesController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.familyName],
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Correo',
                          hint: 'tu@correo.com',
                          controller: emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: _email,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Contraseña',
                          hint: 'Mínimo 6 caracteres',
                          controller: passwordController,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: _password,
                          onSubmitted: (_) => _register(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                          color: AppColors.error, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppPrimaryButton(label: 'Crear cuenta', loading: isLoading, onPressed: _register),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('¿Ya tienes cuenta?',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary)),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
