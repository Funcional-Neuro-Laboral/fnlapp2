import 'package:flutter/material.dart';
import 'package:fnlapp/Main/testestres_form.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../widgets/app_buttons.dart';

/// Introducción al test de estrés.
class TestEstresScreen extends StatelessWidget {
  const TestEstresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const FuncyImage(FuncyPose.pensativo, size: 210, flipped: true, semanticLabel: 'Funcy pensativo'),
                        ),
                        const SizedBox(height: 28),
                        Text('Test de estrés laboral', style: textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(
                          'Responde según cómo te has sentido en tu trabajo. No hay respuestas buenas ni malas.',
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const _InfoLine(icon: Icons.format_list_numbered_rounded, text: '23 preguntas cortas'),
                        const _InfoLine(icon: Icons.schedule_rounded, text: 'Unos 5 minutos'),
                        const _InfoLine(icon: Icons.verified_user_outlined, text: 'Tus respuestas son confidenciales'),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: AppPrimaryButton(
                    label: 'Comenzar test',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TestEstresQuestionScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primaryDeep),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
