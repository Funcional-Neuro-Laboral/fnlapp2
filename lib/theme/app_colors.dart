import 'package:flutter/material.dart';

/// Paleta única de la app (sistema de diseño Funcy).
///
/// Úsala en lugar de escribir colores hexadecimales en cada pantalla.
class AppColors {
  AppColors._();

  // Marca
  static const Color primary = Color(0xFF5027D0); // Morado FNL: acciones principales
  static const Color primaryDeep = Color(0xFF3B1C9C); // Texto destacado y pestaña activa
  static const Color night = Color(0xFF22106A); // Noche Funcy: pantallas de resultado
  static const Color logoInk = Color(0xFF120B35);

  // Superficies
  static const Color background = Color(0xFFF6F5FA); // Fondo de todas las pantallas
  static const Color brandBackground = Color(0xFFFCFBFF); // Fondo con círculos de marca
  static const Color surface = Colors.white;
  static const Color lavender = Color(0xFFEEEAFD); // Fondos suaves y selección
  static const Color lavenderStrong = Color(0xFFDCD4F6);
  static const Color selected = Color(0xFFF4F1FE);
  static const Color muted = Color(0xFFF3F1F8);
  static const Color navIndicator = Color(0xFFE6E0FB);

  // Texto
  static const Color ink = Color(0xFF1A1530); // Texto principal
  static const Color inkSecondary = Color(0xFF575170); // Descripciones (contraste 7:1)
  static const Color inkTertiary = Color(0xFF6B6680); // Etiquetas y ayudas
  static const Color placeholder = Color(0xFF8A859C);

  // Bordes
  static const Color border = Color(0xFFE2DFEB);
  static const Color borderSoft = Color(0xFFECE9F3);
  static const Color divider = Color(0xFFF0EEF5);
  static const Color inputBorder = Color(0xFFDAD6E6);

  // Estados
  static const Color success = Color(0xFF187A55);
  static const Color successText = Color(0xFF146848);
  static const Color successBg = Color(0xFFE3F4EC);
  static const Color streak = Color(0xFFE08A00);
  static const Color streakText = Color(0xFF8A4F00);
  static const Color streakBg = Color(0xFFFFF1DB);
  static const Color error = Color(0xFFB4232C);
  static const Color errorBg = Color(0xFFFDECEC);
  static const Color errorBorder = Color(0xFFF1C9CC);
  static const Color disabledBg = Color(0xFFECE9F3);
  static const Color disabledText = Color(0xFF77718A);

  // Escala de estrés (sobre fondo oscuro)
  static const Color zoneLeve = Color(0xFF34D399);
  static const Color zoneModerado = Color(0xFFFBBF24);
  static const Color zoneAlto = Color(0xFFF87171);
}
