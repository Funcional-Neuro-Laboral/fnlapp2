import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnlapp/Login/login.dart';
import 'package:fnlapp/Main/plan.dart';
import 'package:fnlapp/Main/stress_result_screen.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:fnlapp/Util/stress_factors.dart';
import 'package:fnlapp/theme/app_colors.dart';
import 'package:fnlapp/theme/app_theme.dart';
import 'package:fnlapp/theme/stress_level_style.dart';
import 'package:fnlapp/widgets/app_bottom_nav.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

String _isoDaysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 10).subtract(Duration(days: days)).toIso8601String();
}

void main() {
  group('Tema', () {
    test('usa la tipografía y el color de marca', () {
      final theme = AppTheme.light;
      expect(theme.textTheme.bodyLarge?.fontFamily, AppTheme.fontFamily);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  group('Escala de estrés', () {
    test('el puntaje se ubica entre 0 y 1', () {
      expect(StressScore.fraction(StressScore.min), 0);
      expect(StressScore.fraction(StressScore.max), 1);
      expect(StressScore.fraction(500), 1);
    });

    test('cada nivel tiene su propia expresión de Funcy', () {
      final poses = {
        StressLevelStyle.of(NivelEstres.leve).pose,
        StressLevelStyle.of(NivelEstres.moderado).pose,
        StressLevelStyle.of(NivelEstres.severo).pose,
      };
      expect(poses.length, 3);
    });

    test('los factores se ordenan por la respuesta más alta', () {
      final answers = List<int>.filled(23, 2);
      answers[4] = 7;
      answers[10] = 6;
      answers[1] = 5;
      final top = topStressFactors(answers);
      expect(top.map((f) => f.label), [
        stressQuestionLabels[4],
        stressQuestionLabels[10],
        stressQuestionLabels[1],
      ]);
    });
  });

  group('Racha', () {
    test('cuenta días seguidos hasta hoy', () {
      final programas = [
        Programa.fromMap({'nombre_tecnica': 'A', 'dia': 1, 'completed_date': _isoDaysAgo(2)}),
        Programa.fromMap({'nombre_tecnica': 'B', 'dia': 2, 'completed_date': _isoDaysAgo(1)}),
        Programa.fromMap({'nombre_tecnica': 'C', 'dia': 3, 'completed_date': _isoDaysAgo(0)}),
      ];
      expect(computeStreak(programas), 3);
    });

    test('se corta si falta un día', () {
      final programas = [
        Programa.fromMap({'nombre_tecnica': 'A', 'dia': 1, 'completed_date': _isoDaysAgo(3)}),
        Programa.fromMap({'nombre_tecnica': 'B', 'dia': 2, 'completed_date': _isoDaysAgo(1)}),
      ];
      expect(computeStreak(programas), 1);
    });
  });

  testWidgets('la barra inferior muestra 4 pestañas con etiqueta', (tester) async {
    var selected = 0;
    await tester.pumpWidget(_app(Scaffold(
      bottomNavigationBar: StatefulBuilder(
        builder: (context, setState) => AppBottomNav(
          selectedIndex: selected,
          onSelected: (i) => setState(() => selected = i),
        ),
      ),
    )));

    for (final label in ['Mi plan', 'Chat', 'Mi test', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(selected, 3);
  });

  testWidgets('el login valida los campos vacíos sin llamar al servidor', (tester) async {
    await tester.pumpWidget(_app(LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola de nuevo!'), findsOneWidget);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
  });

  testWidgets('el resultado muestra el nivel, el puntaje y los factores', (tester) async {
    await tester.pumpWidget(_app(StressResultScreen(
      nivel: NivelEstres.moderado,
      score: 112,
      factors: const [StressFactor('Exceso de papeleo', 6)],
      primaryLabel: 'Ver mi plan de 21 días',
      onPrimary: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('MODERADO'), findsOneWidget);
    expect(find.text('112 de 161 puntos'), findsOneWidget);
    expect(find.text('Exceso de papeleo'), findsOneWidget);
    expect(find.text('Ver mi plan de 21 días'), findsOneWidget);
  });

  testWidgets('Mi plan destaca la actividad de hoy y el progreso', (tester) async {
    final programas = [
      {
        'nombre_tecnica': 'Pausa consciente',
        'tipo_tecnica': 'mindfulness',
        'dia': 1,
        'user_id': 1,
        'id': 10,
        'unlocked': true,
        'start_date': _isoDaysAgo(1),
        'completed_date': _isoDaysAgo(1),
        'guia': '["Paso 1"]',
      },
      {
        'nombre_tecnica': 'Respiración 4-7-8',
        'tipo_tecnica': 'breathing',
        'dia': 2,
        'user_id': 1,
        'id': 11,
        'unlocked': true,
        'start_date': _isoDaysAgo(0),
        'guia': '["Paso 1", "Paso 2"]',
      },
      {
        'nombre_tecnica': 'Escaneo corporal',
        'tipo_tecnica': 'mindfulness',
        'dia': 3,
        'user_id': 1,
        'id': 12,
        'unlocked': false,
      },
    ];

    await tester.pumpWidget(_app(PlanScreen(
      nivelEstres: NivelEstres.moderado,
      isLoading: false,
      programas: programas,
      userName: 'María',
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mi plan'), findsOneWidget);
    expect(find.text('Día 2 de 21'), findsOneWidget);
    expect(find.text('Para hoy'), findsOneWidget);
    expect(find.text('Empezar actividad'), findsOneWidget);
    expect(find.text('Racha de 1 día'), findsOneWidget);

    final locked = find.text('Se desbloquea al completar el anterior');
    await tester.dragUntilVisible(locked, find.byType(CustomScrollView), const Offset(0, -200));
    expect(locked, findsOneWidget);
  });

  testWidgets('Mi plan muestra un error claro si no carga', (tester) async {
    await tester.pumpWidget(_app(PlanScreen(
      nivelEstres: NivelEstres.desconocido,
      isLoading: false,
      loadFailed: true,
      programas: const [],
      onRefresh: () async {},
    )));
    await tester.pump();

    expect(find.text('No pudimos cargar tu plan'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
