// lib/Util/translations.dart
final Map<String, String> tipoTecnicaTraducciones = {
  "breathing": "Respiración",
  "mindfulness": "Atención plena",
  "reflection": "Reflexión",
  "exercise": "Ejercicio",
  "visualization": "Visualización",
};

String traducirTipoTecnica(String tipoTecnica) {
  return tipoTecnicaTraducciones[tipoTecnica] ?? tipoTecnica;
}