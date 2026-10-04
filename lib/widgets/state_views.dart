import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import 'app_buttons.dart';

/// Estado de error con Funcy, explicación y acción para reintentar.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
    this.pose = FuncyPose.nervioso,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final FuncyPose pose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: FuncyImage(pose, size: 150),
          ),
          const SizedBox(height: 20),
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            AppPrimaryButton(label: retryLabel, icon: Icons.refresh_rounded, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

/// Anima suavemente (pulso) un esqueleto de carga. Respeta la preferencia de
/// reducir movimiento del sistema.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.45).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Bloque gris de un esqueleto de carga.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 999,
    this.color = AppColors.borderSoft,
  });

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Mensaje claro para el usuario a partir de un error técnico.
String friendlyErrorMessage(Object? error) {
  final text = error?.toString().toLowerCase() ?? '';
  if (text.contains('socket') || text.contains('failed host lookup') || text.contains('network') || text.contains('clientexception')) {
    return 'No hay conexión a internet. Revísala e inténtalo de nuevo.';
  }
  if (text.contains('timeout')) {
    return 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
  }
  return 'Algo salió mal. Inténtalo de nuevo en unos minutos.';
}
