import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../Main/recuperarcontra.dart';
import '../Politicas y Terminos/condiciones_uso.dart';
import '../Politicas y Terminos/politica_privacidad.dart';
import '../SplashScreen/splashscreen.dart';
import '../theme/app_colors.dart';
import '../Util/auth_session.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_background.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocus = FocusNode();
  bool isLoading = false;
  bool rememberMe = false;
  String? _errorMessage;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => CondicionesUsoScreen()));
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()));

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthSession.login(
      username: usernameController.text.trim(),
      // La contraseña se envía tal cual: los espacios pueden ser parte de ella.
      password: passwordController.text,
      rememberMe: rememberMe,
    );

    if (!mounted) return;
    if (result.ok) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        isLoading = false;
        _errorMessage = result.message;
      });
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Este campo es obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sessionExpired = ModalRoute.of(context)?.settings.arguments == LoginArgs.sessionExpired;

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: FnlLogo(width: 176)),
                        const SizedBox(height: 28),
                        Text('¡Hola de nuevo!', style: textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          'Ingresa para continuar con tu plan de bienestar.',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (sessionExpired) ...[
                          const SizedBox(height: 20),
                          const _InfoBanner(
                            icon: Icons.lock_clock_outlined,
                            message: 'Tu sesión expiró. Vuelve a iniciar sesión; tu progreso está guardado.',
                          ),
                        ],
                        const SizedBox(height: 26),
                        AppTextField(
                          label: 'Usuario o correo',
                          hint: 'nombre.apellido',
                          controller: usernameController,
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          validator: _required,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Contraseña',
                          hint: 'Tu contraseña',
                          controller: passwordController,
                          focusNode: _passwordFocus,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Este campo es obligatorio' : null,
                          onSubmitted: (_) => _login(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => rememberMe = !rememberMe),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 44),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      onChanged: (value) => setState(() => rememberMe = value ?? false),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text('Recordarme', style: textTheme.bodySmall),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              ),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppPrimaryButton(label: 'Iniciar sesión', loading: isLoading, onPressed: _login),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('¿No tienes cuenta?',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary)),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, height: 18 / 12, color: AppColors.inkSecondary),
                            children: [
                              const TextSpan(text: 'Al continuar aceptas los '),
                              TextSpan(
                                text: 'Términos de uso',
                                style: const TextStyle(color: AppColors.primaryDeep, decoration: TextDecoration.underline),
                                recognizer: _termsTap,
                              ),
                              const TextSpan(text: ' y la '),
                              TextSpan(
                                text: 'Política de privacidad',
                                style: const TextStyle(color: AppColors.primaryDeep, decoration: TextDecoration.underline),
                                recognizer: _privacyTap,
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.primaryDeep, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
