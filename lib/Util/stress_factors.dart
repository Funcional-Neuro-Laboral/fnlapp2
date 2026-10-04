import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../Util/enums.dart';

/// Etiqueta corta de cada pregunta del test de estrés (en el mismo orden que
/// `questions_data.dart`). Se usa para mostrar qué está afectando más.
const List<String> stressQuestionLabels = [
  'Rendir cuentas a jefes y equipo',
  'No tener el control de tu área',
  'Falta de equipo para trabajar',
  'Poco respaldo de tu jefe',
  'Falta de respeto o reconocimiento',
  'No sentirte parte del equipo',
  'Poco apoyo del equipo en tus metas',
  'La reputación de tu equipo',
  'Procesos de trabajo poco claros',
  'Políticas que dificultan tu trabajo',
  'Poco control sobre tu trabajo',
  'Supervisor que no cuida tu bienestar',
  'Falta de conocimiento técnico',
  'Falta de un espacio tranquilo',
  'Exceso de papeleo',
  'Poca confianza de tu supervisor',
  'Equipo desorganizado',
  'Demandas injustas sin respaldo',
  'Falta de dirección y objetivos',
  'Presión de tu equipo',
  'Falta de respeto en la organización',
  'Poco apoyo técnico del equipo',
  'Falta de tecnología adecuada',
];

/// Un área del test con su respuesta (1 = nunca, 7 = siempre).
class StressFactor {
  const StressFactor(this.label, this.answer);

  final String label;
  final int answer;

  double get intensity => (answer / 7).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => {'label': label, 'answer': answer};

  factory StressFactor.fromJson(Map<String, dynamic> json) =>
      StressFactor(json['label']?.toString() ?? '', (json['answer'] as num?)?.toInt() ?? 0);
}

/// Las [count] áreas con respuestas más altas.
List<StressFactor> topStressFactors(List<int> answers, {int count = 3}) {
  final indexed = <StressFactor>[];
  for (var i = 0; i < answers.length && i < stressQuestionLabels.length; i++) {
    if (answers[i] > 0) indexed.add(StressFactor(stressQuestionLabels[i], answers[i]));
  }
  indexed.sort((a, b) => b.answer.compareTo(a.answer));
  return indexed.take(count).toList();
}

/// Último resultado del test guardado en el dispositivo.
class LastStressResult {
  const LastStressResult({
    required this.score,
    required this.nivel,
    required this.date,
    required this.factors,
    required this.testType,
  });

  final int score;
  final NivelEstres nivel;
  final DateTime date;
  final List<StressFactor> factors;

  /// 'entry' o 'exit'.
  final String testType;

  static const _key = 'lastStressResult';
  static const _entryKey = 'entryStressResult';

  Map<String, dynamic> toJson() => {
        'score': score,
        'nivel': nivel.name,
        'date': date.toIso8601String(),
        'factors': factors.map((f) => f.toJson()).toList(),
        'testType': testType,
      };

  static LastStressResult? _fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LastStressResult(
        score: (json['score'] as num).toInt(),
        nivel: NivelEstres.values.firstWhere(
          (n) => n.name == json['nivel'],
          orElse: () => NivelEstres.desconocido,
        ),
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        factors: ((json['factors'] as List?) ?? [])
            .map((f) => StressFactor.fromJson(Map<String, dynamic>.from(f)))
            .toList(),
        testType: json['testType']?.toString() ?? 'entry',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(toJson());
    await prefs.setString(_key, raw);
    if (testType == 'entry') await prefs.setString(_entryKey, raw);
  }

  static Future<LastStressResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromJson(prefs.getString(_key));
  }

  static Future<LastStressResult?> loadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromJson(prefs.getString(_entryKey));
  }
}
