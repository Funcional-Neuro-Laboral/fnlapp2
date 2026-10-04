import 'package:flutter/material.dart';

import '../Util/enums.dart';
import 'app_colors.dart';
import 'funcy.dart';

/// Rango del test de estrés: 23 preguntas con respuestas de 1 a 7.
class StressScore {
  StressScore._();

  static const int min = 23;
  static const int max = 161;

  /// Umbrales usados por la app para clasificar el puntaje.
  static const int leveMax = 92;
  static const int moderadoMax = 138;

  static double fraction(int score) =>
      ((score - min) / (max - min)).clamp(0.0, 1.0).toDouble();

  /// Proporción de cada zona en la escala (leve, moderado, alto).
  static const double leveEnd = (leveMax - min) / (max - min);
  static const double moderadoEnd = (moderadoMax - min) / (max - min);
}

/// Cómo se muestra cada nivel de estrés: texto, colores y expresión de Funcy.
class StressLevelStyle {
  const StressLevelStyle({
    required this.label,
    required this.zone,
    required this.accent,
    required this.textOnLight,
    required this.barOnLight,
    required this.pose,
    required this.poseLabel,
    required this.message,
    required this.secondaryAction,
  });

  final String label;

  /// 0 = leve, 1 = moderado, 2 = alto, -1 = sin resultado.
  final int zone;

  /// Color del nivel sobre el fondo oscuro de marca.
  final Color accent;

  /// Colores del nivel sobre fondo claro (etiquetas y barras).
  final Color textOnLight;
  final Color barOnLight;

  final FuncyPose pose;
  final String poseLabel;
  final String message;
  final String secondaryAction;

  static StressLevelStyle of(NivelEstres nivel) {
    switch (nivel) {
      case NivelEstres.leve:
        return const StressLevelStyle(
          label: 'Leve',
          zone: 0,
          accent: Color(0xFF6EE7B7),
          textOnLight: AppColors.successText,
          barOnLight: Color(0xFF1F9D72),
          pose: FuncyPose.feliz,
          poseLabel: 'Funcy saltando de alegría',
          message: '¡Bien! Manejas la presión con equilibrio. Tu plan te ayudará a mantenerlo así.',
          secondaryAction: 'Ver mis respuestas',
        );
      case NivelEstres.moderado:
        return const StressLevelStyle(
          label: 'Moderado',
          zone: 1,
          accent: Color(0xFFFFC44D),
          textOnLight: AppColors.streakText,
          barOnLight: Color(0xFFD98A00),
          pose: FuncyPose.cansado,
          poseLabel: 'Funcy cansado, con una gota de sudor',
          message: 'Hay señales de tensión. Tu plan de 21 días está pensado para ayudarte a bajarla.',
          secondaryAction: 'Ver mis respuestas',
        );
      case NivelEstres.severo:
        return const StressLevelStyle(
          label: 'Alto',
          zone: 2,
          accent: Color(0xFFFF8A80),
          textOnLight: AppColors.error,
          barOnLight: Color(0xFFD64545),
          pose: FuncyPose.agobiado,
          poseLabel: 'Funcy agobiado, con las manos en la cabeza',
          message: 'Tu cuerpo te pide una pausa. Empecemos hoy, paso a paso y con apoyo.',
          secondaryAction: 'Hablar con un profesional',
        );
      case NivelEstres.desconocido:
        return const StressLevelStyle(
          label: 'Sin resultado',
          zone: -1,
          accent: Colors.white,
          textOnLight: AppColors.inkSecondary,
          barOnLight: AppColors.primary,
          pose: FuncyPose.pensativo,
          poseLabel: 'Funcy pensativo',
          message: 'Aún no tienes un resultado. Completa el test para conocer tu nivel de estrés.',
          secondaryAction: 'Ver mis respuestas',
        );
    }
  }

  /// Etiqueta de intensidad para el puntaje de una pregunta (1 a 7).
  static String intensityLabel(int answer) {
    if (answer >= 7) return 'Muy alta';
    if (answer >= 5) return 'Alta';
    if (answer >= 3) return 'Media';
    return 'Baja';
  }
}
