import 'package:flutter/material.dart';

/// Expresiones de Funcy y el momento de la app en que se usa cada una.
enum FuncyPose {
  celebra('assets/funcy/funcy_celebra.png'), // Día completado y certificado
  feliz('assets/funcy/funcy_feliz.png'), // Resultado: estrés leve
  cansado('assets/funcy/funcy_cansado.png'), // Resultado: estrés moderado
  agobiado('assets/funcy/funcy_agobiado.png'), // Resultado: estrés alto
  seguro('assets/funcy/funcy_seguro.png'), // Chat y bienvenida
  medita('assets/funcy/funcy_medita.png'), // Respiración y carga
  pensativo('assets/funcy/funcy_pensativo.png'), // Preguntas iniciales y test
  nervioso('assets/funcy/funcy_nervioso.png'), // Errores y sin conexión
  emocionado('assets/funcy/funcy_emocionado.png'), // Logros y rachas
  canta('assets/funcy/funcy_canta.png'), // Respuestas positivas en el chat
  triste('assets/funcy/funcy_triste.png'); // Volver tras días sin entrar

  const FuncyPose(this.asset);

  final String asset;
}

class FuncyImage extends StatelessWidget {
  const FuncyImage(
    this.pose, {
    super.key,
    this.size = 160,
    this.flipped = false,
    this.semanticLabel,
  });

  final FuncyPose pose;
  final double size;

  /// Voltea a Funcy horizontalmente (por ejemplo, para que mire hacia el texto).
  final bool flipped;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      pose.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (!flipped) return image;
    return Transform.flip(flipX: true, child: image);
  }
}
