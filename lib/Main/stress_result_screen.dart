import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../theme/stress_level_style.dart';
import '../Util/enums.dart';
import '../Util/stress_factors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/stress_gauge.dart';

/// Revelación del resultado del test de estrés: medidor, Funcy con la emoción
/// del nivel, puntaje y las áreas que más afectan.
class StressResultScreen extends StatefulWidget {
  const StressResultScreen({
    super.key,
    required this.nivel,
    required this.primaryLabel,
    required this.onPrimary,
    this.score,
    this.factors = const [],
    this.onClose,
    this.onSecondary,
  });

  final NivelEstres nivel;
  final int? score;
  final List<StressFactor> factors;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onClose;
  final VoidCallback? onSecondary;

  @override
  State<StressResultScreen> createState() => _StressResultScreenState();
}

class _StressResultScreenState extends State<StressResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _reveal.value = 1;
    } else if (_reveal.value == 0 && !_reveal.isAnimating) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(parent: _reveal, curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  Widget build(BuildContext context) {
    final style = StressLevelStyle.of(widget.nivel);
    final score = widget.score;
    final fraction = score != null
        ? StressScore.fraction(score)
        : switch (style.zone) {
            0 => StressScore.leveEnd / 2,
            1 => (StressScore.leveEnd + StressScore.moderadoEnd) / 2,
            _ => (StressScore.moderadoEnd + 1) / 2,
          };
    final mascot = _interval(0.0, 0.45);
    final word = _interval(0.55, 0.85);
    final pill = _interval(0.65, 1.0);

    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(
        children: [
          const Positioned(top: -92, right: -102, child: _Glow(size: 240, opacity: 0.06)),
          const Positioned(top: 300, left: -116, child: _Glow(size: 230, opacity: 0.05)),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                      children: [
                        _TopBar(onClose: widget.onClose),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  if (style.zone >= 0)
                                    StressGauge(
                                      fraction: fraction,
                                      zone: style.zone,
                                      accent: style.accent,
                                      semanticLabel: score != null
                                          ? 'Nivel de estrés ${style.label.toLowerCase()}: $score de ${StressScore.max} puntos'
                                          : 'Nivel de estrés ${style.label.toLowerCase()}',
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 52),
                                    child: FadeTransition(
                                      opacity: mascot,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.85, end: 1).animate(mascot),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 220,
                                              height: 220,
                                              decoration: BoxDecoration(
                                                color: style.accent.withValues(alpha: 0.16),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            FuncyImage(style.pose, size: 220, semanticLabel: style.poseLabel),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tu nivel de estrés es',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FadeTransition(
                          opacity: word,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(word),
                            child: Semantics(
                              header: true,
                              child: Text(
                                style.label.toUpperCase(),
                                style: TextStyle(
                                  color: style.accent,
                                  fontSize: 46,
                                  height: 52 / 46,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (score != null) ...[
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: pill,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$score de ${StressScore.max} puntos',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Expanded(
                          child: _ResultSheet(
                            style: style,
                            factors: widget.factors,
                            primaryLabel: widget.primaryLabel,
                            onPrimary: widget.onPrimary,
                            onSecondary: widget.onSecondary,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text('Tu resultado', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            if (onClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Cerrar',
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.style,
    required this.factors,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  final StressLevelStyle style;
  final List<StressFactor> factors;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 22, 20, 16 + bottomInset),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(style.message, style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF3F3A55))),
              if (factors.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Lo que más te está afectando', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                for (var i = 0; i < factors.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _FactorRow(factor: factors[i], style: style),
                ],
              ],
              const SizedBox(height: 20),
              AppPrimaryButton(label: primaryLabel, onPressed: onPrimary),
              if (onSecondary != null || style.zone == 2) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onSecondary ?? () => _showSupportInfo(context),
                  child: Text(style.zone == 2 ? 'Hablar con un profesional' : style.secondaryAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Busca apoyo profesional'),
        content: const Text(
          'Si sientes que el estrés te supera, habla con el área de bienestar o recursos humanos de tu empresa, '
          'o con un profesional de salud mental. Si estás en peligro, comunícate con los servicios de emergencia de tu país.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor, required this.style});

  final StressFactor factor;
  final StressLevelStyle style;

  @override
  Widget build(BuildContext context) {
    final intensity = StressLevelStyle.intensityLabel(factor.answer);
    return Semantics(
      label: '${factor.label}: intensidad $intensity',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(factor.label, style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(intensity, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: style.textOnLight)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor.intensity,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: style.barOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: opacity), shape: BoxShape.circle),
    );
  }
}
