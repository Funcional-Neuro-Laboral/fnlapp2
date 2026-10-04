import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../theme/stress_level_style.dart';
import '../Util/date_format_es.dart';
import '../Util/stress_factors.dart';
import '../widgets/stress_gauge.dart';
import 'stress_result_screen.dart';

class MiTestScreen extends StatefulWidget {
  final NivelEstres nivelEstres;
  final bool isExitTestEnabled;
  final bool hasCompletedExitTest;
  final VoidCallback? onStartExitTest;

  const MiTestScreen({
    Key? key,
    required this.nivelEstres,
    this.isExitTestEnabled = false,
    this.hasCompletedExitTest = false,
    this.onStartExitTest,
  }) : super(key: key);

  @override
  State<MiTestScreen> createState() => _MiTestScreenState();
}

class _MiTestScreenState extends State<MiTestScreen> {
  LastStressResult? _last;
  LastStressResult? _entry;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  void didUpdateWidget(MiTestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nivelEstres != widget.nivelEstres || oldWidget.hasCompletedExitTest != widget.hasCompletedExitTest) {
      _loadResults();
    }
  }

  Future<void> _loadResults() async {
    final last = await LastStressResult.load();
    final entry = await LastStressResult.loadEntry();
    if (!mounted) return;
    setState(() {
      _last = last;
      _entry = entry;
    });
  }

  /// El puntaje guardado solo se muestra si coincide con el nivel actual.
  LastStressResult? get _matchingLast =>
      (_last != null && _last!.nivel == widget.nivelEstres) ? _last : null;

  void _openFullResult() {
    final last = _matchingLast;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StressResultScreen(
          nivel: widget.nivelEstres,
          score: last?.score,
          factors: last?.factors ?? const [],
          primaryLabel: 'Volver a Mi test',
          onPrimary: () => Navigator.of(context).pop(),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final last = _matchingLast;
    final style = StressLevelStyle.of(widget.nivelEstres);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text('Mi test', style: textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(
                  last != null ? 'Último resultado · ${DateFormatEs.shortWithYear(last.date)}' : 'Tu nivel según tu último test',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 16),
                if (style.zone >= 0)
                  _LevelHeroCard(style: style, score: last?.score, onOpen: _openFullResult)
                else
                  const _NoResultCard(),
                const SizedBox(height: 22),
                Semantics(header: true, child: Text('Tu evolución', style: textTheme.titleSmall)),
                const SizedBox(height: 10),
                _EvolutionCard(
                  entryLevel: _entry?.nivel ?? widget.nivelEstres,
                  entryScore: _entry?.score,
                  entryDate: _entry?.date,
                  exitResult: (_last?.testType == 'exit') ? _last : null,
                  hasCompletedExitTest: widget.hasCompletedExitTest,
                  isExitTestEnabled: widget.isExitTestEnabled,
                  onStartExitTest: widget.onStartExitTest,
                ),
                const SizedBox(height: 22),
                Semantics(header: true, child: Text('Entiende tu resultado', style: textTheme.titleSmall)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Recomendaciones para tu nivel',
                        onTap: () => _showInfoSheet(context, 'Recomendaciones para ti', _recommendations(widget.nivelEstres)),
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.help_outline_rounded,
                        label: '¿Qué mide este test?',
                        onTap: () => _showInfoSheet(context, '¿Qué mide este test?', const [
                          'El test tiene 23 preguntas sobre situaciones de tu trabajo: la relación con tu jefe y tu equipo, '
                              'la organización de la empresa y los recursos con los que cuentas.',
                          'Cada respuesta va de «Nunca» (1) a «Siempre» (7). El puntaje total va de 23 a 161 puntos.',
                          'Hasta 92 puntos el nivel es leve; hasta 138, moderado; y desde 139, alto. '
                              'Los rangos pueden variar ligeramente según tu perfil.',
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _recommendations(NivelEstres nivel) {
    switch (nivel) {
      case NivelEstres.leve:
        return const [
          'Sigue con tu actividad diaria: mantiene tu equilibrio.',
          'Toma pausas cortas durante la jornada, aunque te sientas bien.',
          'Cuida tu descanso y tus horarios de sueño.',
        ];
      case NivelEstres.moderado:
        return const [
          'Haz la actividad de tu plan cada día; la constancia es lo que más ayuda.',
          'Cuando sientas tensión, haz una pausa de respiración de 2 minutos.',
          'Habla con Funcy cuando te sientas con mucha carga.',
        ];
      case NivelEstres.severo:
        return const [
          'Prioriza tu descanso y pide apoyo a tu jefe o a tu equipo si la carga es excesiva.',
          'Habla con el área de bienestar de tu empresa o con un profesional de salud mental.',
          'Haz respiraciones guiadas varias veces al día, no solo en tu actividad diaria.',
        ];
      case NivelEstres.desconocido:
        return const ['Completa el test para recibir recomendaciones según tu nivel.'];
    }
  }

  void _showInfoSheet(BuildContext context, String title, List<String> paragraphs) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFD9D5E3), borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final p in paragraphs) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p, style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary))),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Entendido')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelHeroCard extends StatelessWidget {
  const _LevelHeroCard({required this.style, required this.score, required this.onOpen});

  final StressLevelStyle style;
  final int? score;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.night,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.night.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu nivel de estrés',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              style.label.toUpperCase(),
                              style: TextStyle(
                                  color: style.accent, fontSize: 32, height: 38 / 32, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('$score de ${StressScore.max} puntos',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 112,
                      height: 104,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(color: style.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                          ),
                          Positioned(
                            top: -14,
                            child: FuncyImage(style.pose, size: 128, semanticLabel: style.poseLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                StressScaleBar(
                  zone: style.zone,
                  accent: style.accent,
                  fraction: score != null ? StressScore.fraction(score!) : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver resultado completo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const FuncyImage(FuncyPose.pensativo, size: 96),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aún no tienes un resultado', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  StressLevelStyle.of(NivelEstres.desconocido).message,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({
    required this.entryLevel,
    required this.entryScore,
    required this.entryDate,
    required this.exitResult,
    required this.hasCompletedExitTest,
    required this.isExitTestEnabled,
    this.onStartExitTest,
  });

  final NivelEstres entryLevel;
  final int? entryScore;
  final DateTime? entryDate;
  final LastStressResult? exitResult;
  final bool hasCompletedExitTest;
  final bool isExitTestEnabled;
  final VoidCallback? onStartExitTest;

  @override
  Widget build(BuildContext context) {
    final entryStyle = StressLevelStyle.of(entryLevel);
    final Widget exitContent;
    if (exitResult != null) {
      final exitStyle = StressLevelStyle.of(exitResult!.nivel);
      exitContent = _EvolutionColumn(
        title: 'Test de salida',
        value: '${exitStyle.label} · ${exitResult!.score}',
        valueColor: exitStyle.textOnLight,
        caption: DateFormatEs.short(exitResult!.date),
      );
    } else if (hasCompletedExitTest) {
      exitContent = const _EvolutionColumn(
        title: 'Test de salida',
        value: 'Completado',
        valueColor: AppColors.successText,
      );
    } else if (isExitTestEnabled && onStartExitTest != null) {
      exitContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Test de salida', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: onStartExitTest,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: const Text('Hacer ahora', style: TextStyle(fontSize: 14)),
          ),
        ],
      );
    } else {
      exitContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D5E3), width: 1.5),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test de salida', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.inkSecondary),
                SizedBox(width: 6),
                Text('Día 21', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSecondary)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EvolutionColumn(
              title: 'Test de entrada',
              value: entryScore != null ? '${entryStyle.label} · $entryScore' : entryStyle.label,
              valueColor: entryStyle.textOnLight,
              caption: entryDate != null ? DateFormatEs.short(entryDate!) : null,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, color: AppColors.placeholder),
          ),
          Expanded(child: exitContent),
        ],
      ),
    );
  }
}

class _EvolutionColumn extends StatelessWidget {
  const _EvolutionColumn({required this.title, required this.value, required this.valueColor, this.caption});

  final String title;
  final String value;
  final Color valueColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w800, color: valueColor)),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
