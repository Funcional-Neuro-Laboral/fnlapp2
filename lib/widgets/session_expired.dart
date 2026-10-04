import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../Util/app_navigator.dart';
import 'app_buttons.dart';

bool _sheetVisible = false;

/// Avisa que la sesión expiró y lleva al inicio de sesión.
///
/// Se puede llamar desde cualquier lugar: usa el navegador global.
Future<void> showSessionExpiredSheet() async {
  final context = appNavigatorKey.currentContext;
  if (context == null || _sheetVisible) return;
  _sheetVisible = true;

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (sheetContext) => const _SessionExpiredSheet(),
  );
  _sheetVisible = false;
}

class _SessionExpiredSheet extends StatelessWidget {
  const _SessionExpiredSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D5E3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
              child: const Icon(Icons.lock_clock_outlined, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Tu sesión expiró', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Por tu seguridad, vuelve a iniciar sesión. Tu progreso está guardado.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Iniciar sesión',
              onPressed: () {
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
