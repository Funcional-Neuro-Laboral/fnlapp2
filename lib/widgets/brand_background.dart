import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo de marca: dos círculos lavanda, arriba a la derecha y abajo a la
/// izquierda.
class BrandBackground extends StatelessWidget {
  const BrandBackground({
    super.key,
    required this.child,
    this.color = AppColors.brandBackground,
    this.circleColor = AppColors.lavender,
  });

  final Widget child;
  final Color color;
  final Color circleColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          Positioned(
            top: -64,
            right: -88,
            child: _Circle(size: 210, color: circleColor),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: _Circle(size: 250, color: circleColor),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Logo de Funcional Neuro Laboral (versión para fondo claro).
class FnlLogo extends StatelessWidget {
  const FnlLogo({super.key, this.width = 176});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/logo_fnl.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Funcional Neuro Laboral',
    );
  }
}
