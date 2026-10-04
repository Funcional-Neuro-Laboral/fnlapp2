import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../widgets/app_buttons.dart';
import '../widgets/brand_background.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              const FnlLogo(width: 150),
                              const Spacer(),
                              Container(
                                width: 240,
                                height: 240,
                                decoration: const BoxDecoration(
                                  color: AppColors.lavender,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const FuncyImage(
                                  FuncyPose.seguro,
                                  size: 250,
                                  semanticLabel: 'Funcy, tu compañero de bienestar',
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'Hola, soy Funcy',
                                style: textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tu compañero para entender, cuidar y equilibrar tus emociones en el trabajo.',
                                style: textTheme.bodyLarge?.copyWith(color: AppColors.inkSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const Spacer(),
                              const SizedBox(height: 32),
                              AppPrimaryButton(
                                label: 'Empezar',
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                child: const Text('Crear una cuenta'),
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
          ),
        ),
      ),
    );
  }
}
