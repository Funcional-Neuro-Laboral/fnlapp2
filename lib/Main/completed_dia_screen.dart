import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../widgets/app_buttons.dart';

/// Se muestra al repetir una actividad que ya estaba completada.
class CompletedDiaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const FuncyImage(FuncyPose.emocionado, size: 190, semanticLabel: 'Funcy emocionado'),
                  ),
                  const SizedBox(height: 24),
                  Text('¡Ya habías completado esta actividad!',
                      style: textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Repasarla también suma. Sigue adelante: tu bienestar es lo más importante.',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Volver a mi plan',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
